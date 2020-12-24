defmodule Tiles do
  require Integer

  def run(args) do
    {opts, [path]} = OptionParser.parse!(args, strict: [part_2: :boolean])

    if Keyword.get(opts, :part_2) do
      advance_living_art(path)
    else
      count_flipped_to_black(path)
    end
  end

  defp advance_living_art(path) do
    path
    |> stream_directions
    |> flip_tiles
    |> repeat(&advance/1, 100)
    |> count_black
  end

  defp count_flipped_to_black(path) do
    path
    |> stream_directions
    |> flip_tiles
    |> count_black
  end

  defp stream_directions(path) do
    path
    |> File.stream!()
    |> Stream.map(&String.trim/1)
    |> Stream.map(fn line ->
      Regex.scan(~r{[ns][ew]|[ew]}, line)
      |> List.flatten()
    end)
  end

  defp flip_tiles(directions) do
    Enum.reduce(directions, MapSet.new(), fn steps, black ->
      xy = walk(steps)

      if MapSet.member?(black, xy) do
        MapSet.delete(black, xy)
      else
        MapSet.put(black, xy)
      end
    end)
  end

  # 0:  0 1 2 3
  # 1:   0 1 2 3
  # 2:  0 1 2 3
  # 3:   0 1 2 3
  defp walk(steps, xy \\ {0, 0})

  defp walk([], xy), do: xy

  defp walk(["ne" | steps], {x, y}) when Integer.is_even(y) do
    walk(steps, {x, y - 1})
  end

  defp walk(["ne" | steps], {x, y}) when Integer.is_odd(y) do
    walk(steps, {x + 1, y - 1})
  end

  defp walk(["e" | steps], {x, y}), do: walk(steps, {x + 1, y})

  defp walk(["se" | steps], {x, y}) when Integer.is_even(y) do
    walk(steps, {x, y + 1})
  end

  defp walk(["se" | steps], {x, y}) when Integer.is_odd(y) do
    walk(steps, {x + 1, y + 1})
  end

  defp walk(["sw" | steps], {x, y}) when Integer.is_even(y) do
    walk(steps, {x - 1, y + 1})
  end

  defp walk(["sw" | steps], {x, y}) when Integer.is_odd(y) do
    walk(steps, {x, y + 1})
  end

  defp walk(["w" | steps], {x, y}), do: walk(steps, {x - 1, y})

  defp walk(["nw" | steps], {x, y}) when Integer.is_even(y) do
    walk(steps, {x - 1, y - 1})
  end

  defp walk(["nw" | steps], {x, y}) when Integer.is_odd(y) do
    walk(steps, {x, y - 1})
  end

  defp repeat(black, func, days) do
    black
    |> Stream.iterate(func)
    |> Stream.drop(days)
    |> Enum.take(1)
    |> hd
  end

  defp advance(black) do
    {min_x, max_x} = black |> Enum.map(fn {x, _y} -> x end) |> Enum.min_max()
    {min_y, max_y} = black |> Enum.map(fn {_x, y} -> y end) |> Enum.min_max()

    Enum.reduce((min_y - 1)..(max_y + 1), black, fn y, new_black ->
      Enum.reduce((min_x - 1)..(max_x + 1), new_black, fn x, nb ->
        case {MapSet.member?(black, {x, y}), adjacent(black, {x, y})} do
          {true, count} when count == 0 or count > 2 ->
            MapSet.delete(nb, {x, y})

          {false, 2} ->
            MapSet.put(nb, {x, y})

          _unchanged ->
            nb
        end
      end)
    end)
  end

  defp adjacent(black, {x, y}) when Integer.is_even(y) do
    [
      {x, y - 1},
      {x + 1, y},
      {x, y + 1},
      {x - 1, y + 1},
      {x - 1, y},
      {x - 1, y - 1}
    ]
    |> Enum.count(fn xy -> MapSet.member?(black, xy) end)
  end

  defp adjacent(black, {x, y}) when Integer.is_odd(y) do
    [
      {x + 1, y - 1},
      {x + 1, y},
      {x + 1, y + 1},
      {x, y + 1},
      {x - 1, y},
      {x, y - 1}
    ]
    |> Enum.count(fn xy -> MapSet.member?(black, xy) end)
  end

  defp count_black(black), do: MapSet.size(black)
end

System.argv()
|> Tiles.run()
|> IO.puts()
