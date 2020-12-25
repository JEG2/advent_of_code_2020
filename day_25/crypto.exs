defmodule Crypto do
  def run(args) do
    {opts, [path]} = OptionParser.parse!(args, strict: [part_2: :boolean])

    # if Keyword.get(opts, :part_2) do
    #   advance_living_art(path)
    # else
    find_encryption_key(path)
    # end
  end

  defp find_encryption_key(path) do
    path
    |> read_keys
    |> find_card_loop_size
    |> calculate_encryption_key
  end

  defp read_keys(path) do
    path
    |> File.stream!()
    |> Stream.map(&String.trim/1)
    |> Enum.map(&String.to_integer/1)
    |> List.to_tuple()
  end

  defp find_card_loop_size({card_key, door_key}) do
    {card_key, find_loop_size(card_key), door_key}
  end

  defp find_loop_size(target) do
    1
    |> Stream.iterate(fn value -> rem(value * 7, 20_201_227) end)
    |> Enum.take_while(fn value -> value != target end)
    |> length
  end

  defp calculate_encryption_key({_card_key, card_loop_size, door_key}) do
    1
    |> Stream.iterate(fn value -> rem(value * door_key, 20_201_227) end)
    |> Stream.drop(card_loop_size)
    |> Enum.take(1)
    |> hd
  end
end

System.argv()
|> Crypto.run()
|> IO.inspect()
