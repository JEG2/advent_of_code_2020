defmodule Passports do
  def run(args) do
    {opts, [path]} = OptionParser.parse!(args, strict: [part_2: :boolean])

    if Keyword.get(opts, :part_2) do
      validate(path, &format/2)
    else
      validate(path, &presence/2)
    end
  end

  def validate(path, check) do
    path
    |> read_passports
    |> count_valid(check)
  end

  defp read_passports(path) do
    path
    |> File.stream!()
    |> Stream.chunk_while(
      Map.new(),
      fn line, passport ->
        if String.match?(line, ~r{\A\s*\z}) and map_size(passport) != 0 do
          {:cont, passport, Map.new()}
        else
          new_fields =
            line
            |> String.trim()
            |> String.split(~r{\s+})
            |> Enum.into(Map.new(), fn key_and_value ->
              key_and_value
              |> String.split(":", parts: 2, trim: true)
              |> List.to_tuple()
            end)

          {:cont, Map.merge(passport, new_fields)}
        end
      end,
      fn passport ->
        if map_size(passport) != 0 do
          {:cont, passport, Map.new()}
        else
          {:cont, passport}
        end
      end
    )
  end

  @validations %{
    "byr" => ~r"\A(?:19[2-9]\d|200[0-2])\z",
    "iyr" => ~r"\A(?:201\d|2020)\z",
    "eyr" => ~r"\A(?:202\d|2030)\z",
    "hgt" => ~r"\A(?:(?:1[5-8]\d|19[0-3])cm|(?:59|6\d|7[0-6])in)\z",
    "hcl" => ~r"\A#[0-9a-f]{6}\z",
    "ecl" => ~r"\A(?:amb|blu|brn|gry|grn|hzl|oth)\z",
    "pid" => ~r"\A\d{9}\z"
  }

  defp count_valid(passports, check) do
    Enum.count(passports, fn passport ->
      @validations
      |> Map.keys()
      |> Enum.all?(fn field -> check.(passport, field) end)
    end)
  end

  defp presence(passport, field), do: Map.has_key?(passport, field)

  defp format(passport, field) do
    presence(passport, field) and
      String.match?(
        Map.fetch!(passport, field),
        Map.fetch!(@validations, field)
      )
  end
end

System.argv()
|> Passports.run()
|> IO.puts()
