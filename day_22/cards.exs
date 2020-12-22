defmodule Cards do
  def run(args) do
    {opts, [path]} = OptionParser.parse!(args, strict: [part_2: :boolean])

    if Keyword.get(opts, :part_2) do
      play_recursive_combat(path)
    else
      play_combat(path)
    end
  end

  defp play_recursive_combat(path) do
    path
    |> deal_cards
    |> play_recursive(MapSet.new())
    |> score
  end

  defp play_combat(path) do
    path
    |> deal_cards
    |> play
    |> score
  end

  defp deal_cards(path) do
    path
    |> File.stream!()
    |> Stream.map(&String.trim/1)
    |> Stream.chunk_by(fn line -> line != "" end)
    |> Stream.reject(fn chunk -> chunk == [""] end)
    |> Enum.map(fn deck ->
      deck
      |> Enum.drop(1)
      |> Enum.map(&String.to_integer/1)
    end)
    |> List.to_tuple()
  end

  defp play_recursive({[], player_2}, _positions), do: {:player_2, player_2}

  defp play_recursive({player_1, []}, _positions), do: {:player_1, player_1}

  defp play_recursive(
         {[card_1 | rest_1] = player_1, [card_2 | rest_2]} = position,
         positions
       ) do
    cond do
      MapSet.member?(positions, position) ->
        {:player_1, player_1}

      length(rest_1) >= card_1 and length(rest_2) >= card_2 ->
        case play_recursive(
               {Enum.take(rest_1, card_1), Enum.take(rest_2, card_2)},
               MapSet.new()
             ) do
          {:player_1, _deck} ->
            play_recursive(
              {rest_1 ++ [card_1, card_2], rest_2},
              MapSet.put(positions, position)
            )

          {:player_2, _deck} ->
            play_recursive(
              {rest_1, rest_2 ++ [card_2, card_1]},
              MapSet.put(positions, position)
            )
        end

      card_1 > card_2 ->
        play_recursive(
          {rest_1 ++ [card_1, card_2], rest_2},
          MapSet.put(positions, position)
        )

      card_2 > card_1 ->
        play_recursive(
          {rest_1, rest_2 ++ [card_2, card_1]},
          MapSet.put(positions, position)
        )
    end
  end

  defp play({[], player_2}), do: player_2

  defp play({player_1, []}), do: player_1

  defp play({[card_1 | rest_1], [card_2 | rest_2]}) when card_1 > card_2 do
    play({rest_1 ++ [card_1, card_2], rest_2})
  end

  defp play({[card_1 | rest_1], [card_2 | rest_2]}) when card_2 > card_1 do
    play({rest_1, rest_2 ++ [card_2, card_1]})
  end

  defp score({_player, deck}), do: score(deck)

  defp score(deck) do
    deck
    |> Enum.reverse()
    |> Enum.with_index(1)
    |> Enum.map(fn {card, i} -> card * i end)
    |> Enum.sum()
  end
end

System.argv()
|> Cards.run()
|> IO.puts()
