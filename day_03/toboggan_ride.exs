defmodule TobogganRide do
  def run(args) do
    {opts, [path]} = OptionParser.parse!(args, strict: [part_2: :boolean])

    # if Keyword.get(opts, :part_2) do
    #   validate(path)
    # else
    count_tree_hits(path)
    # end
  end

  def count_tree_hits(path) do
    path
    |> read_map
    |> count_trees
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

  defp count_trees(map) do
    height = length(map)
    width = map |> hd |> length

    Stream.unfold({0, 0}, fn {x, y} ->
      {_new_x, new_y} = new_xy = {rem(x + 3, width), y + 1}

      if new_y < height do
        {new_xy, new_xy}
      else
        nil
      end
    end)
    |> Enum.count(fn {x, y} -> map |> Enum.at(y) |> Enum.at(x) == :tree end)
  end
end

System.argv()
|> TobogganRide.run()
|> IO.inspect()
