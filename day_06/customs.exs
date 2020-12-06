defmodule Customs do
  def run(args) do
    {opts, [path]} = OptionParser.parse!(args, strict: [part_2: :boolean])

    if Keyword.get(opts, :part_2) do
      sum_all_yes_answers(path)
    else
      sum_any_yes_answers(path)
    end
  end

  def sum_all_yes_answers(path) do
    path
    |> read_answers
    |> combine_all_yesses
    |> count_and_sum
  end

  def sum_any_yes_answers(path) do
    path
    |> read_answers
    |> combine_any_yes
    |> count_and_sum
  end

  defp read_answers(path) do
    path
    |> File.stream!()
    |> Stream.map(fn line -> line |> String.trim() |> String.graphemes() end)
    |> Stream.chunk_by(fn answers -> answers == [] end)
    |> Stream.reject(fn group -> group == [[]] end)
  end

  defp combine_all_yesses(groups) do
    Stream.map(groups, fn group ->
      group
      |> Enum.map(&MapSet.new/1)
      |> Enum.reduce(&MapSet.intersection/2)
    end)
  end

  defp combine_any_yes(groups) do
    Stream.map(groups, fn group -> group |> List.flatten() |> Enum.uniq() end)
  end

  defp count_and_sum(yesses) do
    yesses
    |> Stream.map(&Enum.count/1)
    |> Enum.reduce(&Kernel.+/2)
  end
end

System.argv()
|> Customs.run()
|> IO.puts()
