defmodule Cups do
  def run(args) do
    {opts, [cups]} = OptionParser.parse!(args, strict: [part_2: :boolean])

    if Keyword.get(opts, :part_2) do
      simulate_big(cups)
    else
      simulate(cups)
    end
  end

  defp simulate_big(cups) do
    cups
    |> prepare
    |> expand
    |> repeat(&move_big/1, 10_000_000)
    |> after_1
  end

  defp simulate(cups) do
    cups
    |> prepare
    |> repeat(&move/1, 100)
    |> from_1
  end

  defp prepare(cups) do
    circle =
      cups
      |> String.graphemes()
      |> Enum.map(&String.to_integer/1)

    {hd(circle), tl(circle)}
  end

  defp expand({current, circle}) do
    expanded =
      [current | circle]
      |> Stream.concat(10..1_000_000)
      |> Stream.chunk_every(2, 1, [current])
      |> Enum.reduce(Map.new(), fn [i, j], connections ->
        Map.put(connections, i, j)
      end)

    {current, expanded}
  end

  defp repeat(circle, func, count) do
    circle
    |> Stream.iterate(func)
    |> Stream.drop(count)
    |> Enum.take(1)
    |> hd
  end

  defp move_big({current, circle}) do
    picked_up =
      circle
      |> Map.fetch!(current)
      |> Stream.iterate(fn n -> Map.fetch!(circle, n) end)
      |> Enum.take(3)

    destination = find_destination(current, [current | picked_up], 1_000_000)
    last_pick_up = List.last(picked_up)
    new_current = Map.fetch!(circle, last_pick_up)

    new_circle =
      Map.merge(circle, %{
        current => new_current,
        destination => hd(picked_up),
        last_pick_up => Map.fetch!(circle, destination)
      })

    {new_current, new_circle}
  end

  defp find_destination(current, picked_up, max) do
    cond do
      current == 1 and current in picked_up ->
        find_destination(max, picked_up, max)

      current in picked_up ->
        find_destination(current - 1, picked_up, max)

      true ->
        current
    end
  end

  def after_1({_current, circle}) do
    first = Map.fetch!(circle, 1)
    next = Map.fetch!(circle, first)
    first * next
  end

  defp move({current, circle}) do
    {picked_up, rest} = split(circle, 3)
    destination = find_destination(current, [current | picked_up], 9)
    i = Enum.find_index(rest, fn n -> n == destination end)
    {left, right} = split(rest, i + 1)
    new_circle = left ++ picked_up ++ right
    {hd(new_circle), tl(new_circle) ++ [current]}
  end

  defp split(enum, count) do
    {Enum.take(enum, count), Enum.drop(enum, count)}
  end

  defp from_1({1, circle}), do: Enum.join(circle)

  defp from_1({current, circle}) do
    from_1({hd(circle), tl(circle) ++ [current]})
  end
end

System.argv()
|> Cups.run()
|> IO.puts()
