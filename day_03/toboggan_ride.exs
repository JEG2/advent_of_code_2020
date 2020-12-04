defmodule TobogganRide do
  def run(args) do
    {opts, [path]} = OptionParser.parse!(args, strict: [part_2: :boolean])

    if Keyword.get(opts, :part_2) do
      check_all_slopes(path)
    else
      count_tree_hits(path)
    end
  end

  def count_tree_hits(path) do
    path
    |> read_map
    |> count_trees({3, 1})
  end

  def check_all_slopes(path) do
    path
    |> read_map
    |> check_slopes([{1, 1}, {3, 1}, {5, 1}, {7, 1}, {1, 2}])
    |> multiply
  end

  defp read_map(path) do
    path
    |> File.stream!()
    |> Enum.map(fn line ->
      line
      |> String.trim()
      |> String.graphemes()
      |> Enum.map(fn
        "." -> :open
        "#" -> :tree
      end)
    end)
  end

  defp count_trees(map, {x_offset, y_offset}) do
    height = length(map)
    width = map |> hd |> length

    Stream.unfold({0, 0}, fn {x, y} ->
      {_new_x, new_y} = new_xy = {rem(x + x_offset, width), y + y_offset}

      if new_y < height do
        {new_xy, new_xy}
      else
        nil
      end
    end)
    |> Enum.count(fn {x, y} -> map |> Enum.at(y) |> Enum.at(x) == :tree end)
  end

  defp check_slopes(map, slopes) do
    Enum.map(slopes, fn slope -> count_trees(map, slope) end)
  end

  defp multiply(counts), do: Enum.reduce(counts, fn n, acc -> n * acc end)
end

System.argv()
|> TobogganRide.run()
|> IO.puts()
