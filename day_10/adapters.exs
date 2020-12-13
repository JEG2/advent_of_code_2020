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

  defp count([first | adapters]) do
    adapters
    |> Enum.reduce([[first]], fn n, [[prev | _rest] = group | rest] ->
      if n == prev + 1 do
        [[n | group] | rest]
      else
        [[n], group | rest]
      end
    end)
    |> Enum.map(&length/1)
    |> Enum.map(&to_combinations/1)
    |> Enum.reduce(&Kernel.*/2)
  end

  def to_combinations(0), do: 0
  def to_combinations(1), do: 1
  def to_combinations(2), do: 1

  def to_combinations(n),
    do: to_combinations(n - 1) + to_combinations(n - 2) + to_combinations(n - 3)

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
