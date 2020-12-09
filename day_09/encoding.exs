defmodule Encoding do
  def run(args) do
    {opts, [path]} = OptionParser.parse!(args, strict: [part_2: :boolean])

    if Keyword.get(opts, :part_2) do
      find_weakness(path)
    else
      checksum(path)
    end
  end

  def find_weakness(path) do
    invalid = checksum(path)

    path
    |> stream_numbers
    |> find_contiguous_sum(invalid)
    |> to_weakness
  end

  def checksum(path) do
    path
    |> stream_numbers
    |> find_missed_sum
  end

  defp stream_numbers(path) do
    path
    |> File.stream!()
    |> Stream.map(&String.trim/1)
    |> Stream.map(&String.to_integer/1)
  end

  defp find_missed_sum(numbers) do
    numbers
    |> Stream.chunk_every(26, 1, :discard)
    |> Enum.find(fn sums_plus_one ->
      sums = sums_plus_one |> Enum.take(25) |> Enum.uniq() |> build_sums
      not MapSet.member?(sums, List.last(sums_plus_one))
    end)
    |> List.last()
  end

  defp build_sums(numbers, sums \\ MapSet.new())

  defp build_sums([], sums), do: sums

  defp build_sums([n | rest], sums) do
    new_sums = Enum.reduce(rest, sums, fn m, s -> MapSet.put(s, n + m) end)
    build_sums(rest, new_sums)
  end

  defp find_contiguous_sum(numbers, goal) do
    numbers
    |> Stream.transform({[], 0}, fn
      n, {run, sum} ->
        {new_run, new_sum} = append(run, sum, n, goal)

        if new_run != [goal] and new_sum == goal do
          {[new_run], :done}
        else
          {[], {new_run, new_sum}}
        end

      _n, :done ->
        {:halt, :done}
    end)
    |> Enum.take(1)
    |> hd()
  end

  defp append(run, sum, n, goal) do
    new_run = run ++ [n]
    new_sum = sum + n
    reduce(new_run, new_sum, goal)
  end

  defp reduce(run, sum, goal) when sum > goal do
    n = hd(run)
    reduce(tl(run), sum - n, goal)
  end

  defp reduce(run, sum, _goal), do: {run, sum}

  defp to_weakness(run) do
    {min, max} = Enum.min_max(run)
    min + max
  end
end

System.argv()
|> Encoding.run()
|> IO.puts()
