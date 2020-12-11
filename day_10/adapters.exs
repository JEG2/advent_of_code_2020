defmodule Adapters do
  def run(args) do
    {opts, [path]} = OptionParser.parse!(args, strict: [part_2: :boolean])

    if Keyword.get(opts, :part_2) do
      count_branches(path)
    else
      calculate_jolt_differences(path)
    end
  end

  def count_branches(path) do
    path
    |> read_adapters
    |> count
  end

  def calculate_jolt_differences(path) do
    path
    |> read_adapters
    |> measure_differences
    |> calculate
  end

  defp read_adapters(path) do
    adapters =
      path
      |> File.stream!()
      |> Stream.map(&String.trim/1)
      |> Stream.map(&String.to_integer/1)
      |> Enum.sort()

    [0 | adapters]
  end

  defp count(adapters, branches \\ 1)

  defp count([_last], branches), do: branches

  defp count([adapter | rest], branches) do
    IO.inspect({adapter, rest, branches})
    choices = run_of_choices(adapter, rest)
    skip = length(choices) - 1
    multiple = 2 |> :math.pow(skip) |> trunc
    IO.inspect(choices)
    count(Enum.drop(rest, skip), branches * multiple)
  end

  defp run_of_choices(adapter, rest, choices \\ [])

  defp run_of_choices(adapter, [skip, test | rest], choices)
       when test - adapter <= 3 do
    IO.inspect({adapter, test, rest, choices}, label: :choices)
    run_of_choices(skip, [test | rest], [skip | choices])
  end

  defp run_of_choices(_adapter, [next | rest], choices) do
    Enum.reverse([next | choices])
  end

  defp measure_differences(adapters) do
    adapters
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.reduce(%{1 => 0, 2 => 0, 3 => 1}, fn [l, r], diffs ->
      Map.update!(diffs, r - l, fn sum -> sum + 1 end)
    end)
  end

  defp calculate(diffs) do
    Map.fetch!(diffs, 1) * Map.fetch!(diffs, 3)
  end
end

System.argv()
|> Adapters.run()
|> IO.puts()
