defmodule SpokenNumbers do
  def run(args) do
    {opts, [start]} = OptionParser.parse!(args, strict: [part_2: :boolean])

    if Keyword.get(opts, :part_2) do
      play_game(start, 30_000_000)
    else
      play_game(start, 2020)
    end
  end

  def play_game(start, turns) do
    start
    |> stream_numbers
    |> ith(turns)
  end

  defp stream_numbers(start) do
    starting_numbers =
      start
      |> String.split(",")
      |> Enum.map(&String.to_integer/1)

    {starting_numbers, 0, nil, Map.new()}
    |> Stream.iterate(&advance/1)
    |> Stream.drop(1)
  end

  defp advance({[first | numbers], turn, _previous, seen}) do
    {numbers, turn + 1, first, Map.put(seen, first, turn)}
  end

  defp advance({[], turn, previous, seen}) do
    next =
      if Map.has_key?(seen, previous) do
        turn - 1 - Map.fetch!(seen, previous)
      else
        0
      end

    {[], turn + 1, next, Map.put(seen, previous, turn - 1)}
  end

  defp ith(numbers, i) do
    numbers
    |> Enum.at(i - 1)
    |> elem(2)
  end
end

System.argv()
|> SpokenNumbers.run()
|> IO.puts()
