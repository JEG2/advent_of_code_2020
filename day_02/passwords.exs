defmodule Passwords do
  def run(args) do
    {opts, [path]} = OptionParser.parse!(args, strict: [part_2: :boolean])

    if Keyword.get(opts, :part_2) do
      validate(path)
    else
      validate_old_job(path)
    end
  end

  def validate_old_job(path) do
    path
    |> read_passwords
    |> count_valid_old_job
  end

  def validate(path) do
    path
    |> read_passwords
    |> count_valid
  end

  defp read_passwords(path) do
    path
    |> File.stream!()
    |> Stream.map(fn line ->
      parsed =
        Regex.named_captures(
          ~r{\A(?<min>\d+)-(?<max>\d+)\s+(?<required>\S):\s*(?<password>\S+)\z},
          String.trim(line)
        )

      Map.merge(
        parsed,
        Enum.into(~w[min max], Map.new(), fn field ->
          {
            field,
            parsed
            |> Map.fetch!(field)
            |> String.to_integer()
          }
        end)
      )
    end)
  end

  defp count_valid_old_job(rows) do
    Enum.count(rows, fn row ->
      count =
        row
        |> Map.fetch!("password")
        |> String.graphemes()
        |> Enum.count(fn char -> char == Map.fetch!(row, "required") end)

      Map.fetch!(row, "min") <= count and count <= Map.fetch!(row, "max")
    end)
  end

  defp count_valid(rows) do
    Enum.count(rows, fn row ->
      chars =
        row
        |> Map.fetch!("password")
        |> String.graphemes()

      count =
        ~w[min max]
        |> Enum.map(fn field -> Enum.at(chars, Map.fetch!(row, field) - 1) end)
        |> Enum.count(fn char -> char == Map.fetch!(row, "required") end)

      count == 1
    end)
  end
end

System.argv()
|> Passwords.run()
|> IO.puts()
