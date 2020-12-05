defmodule Boarding do
  def run(args) do
    {opts, [path]} = OptionParser.parse!(args, strict: [part_2: :boolean])

    if Keyword.get(opts, :part_2) do
      find_seat(path)
    else
      find_highest_id(path)
    end
  end

  def find_seat(path) do
    path
    |> read_boarding_passes
    |> locate_seats
    |> find_missing
  end

  def find_highest_id(path) do
    path
    |> read_boarding_passes
    |> locate_seats
    |> find_highest
  end

  defp read_boarding_passes(path) do
    path
    |> File.stream!()
    |> Stream.map(&String.trim/1)
  end

  defp locate_seats(seats), do: Stream.map(seats, &locate/1)

  defp locate(binary, location \\ {{0, 127}, {0, 7}})
  defp locate("", location), do: to_id(location)
  defp locate("F" <> binary, {row, col}), do: locate(binary, {down(row), col})
  defp locate("B" <> binary, {row, col}), do: locate(binary, {up(row), col})
  defp locate("L" <> binary, {row, col}), do: locate(binary, {row, down(col)})
  defp locate("R" <> binary, {row, col}), do: locate(binary, {row, up(col)})

  defp down({min, max}) when min + 1 == max, do: min
  defp down({min, max}), do: {min, mid_point(min, max)}

  defp up({min, max}) when min + 1 == max, do: max
  defp up({min, max}), do: {mid_point(min, max) + 1, max}

  defp mid_point(min, max), do: min + div(max - min, 2)

  defp to_id({row, col}), do: row * 8 + col

  defp find_highest(ids), do: Enum.max(ids)

  defp find_missing(ids) do
    ids
    |> Enum.sort()
    |> Enum.chunk_every(2, 1)
    |> Enum.find(fn [prev, next] -> prev + 2 == next end)
    |> hd
    |> Kernel.+(1)
  end
end

System.argv()
|> Boarding.run()
|> IO.puts()
