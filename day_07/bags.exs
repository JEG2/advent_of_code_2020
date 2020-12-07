defmodule Bags do
  def run(args) do
    {opts, [path]} = OptionParser.parse!(args, strict: [part_2: :boolean])

    if Keyword.get(opts, :part_2) do
      count_combined_contents(path)
    else
      count_possible_containers(path)
    end
  end

  def count_combined_contents(path) do
    path
    |> read_rules
    |> count_contents
  end

  def count_possible_containers(path) do
    path
    |> read_rules
    |> count_containers
  end

  defp read_rules(path) do
    path
    |> File.stream!()
    |> Enum.into(Map.new(), fn rule ->
      %{"container" => container, "contents" => raw_contents} =
        Regex.named_captures(
          ~r{\A(?<container>.+?)\s+bags\s+contain\s+(?<contents>.+?)\.\Z},
          rule
        )

      contents =
        Regex.scan(
          ~r{(?<count>\d+)\s+(?<color>.+?)\s+bags?},
          raw_contents,
          capture: :all_names
        )
        |> Enum.into(Map.new(), fn [color, count] ->
          {color, String.to_integer(count)}
        end)

      {container, contents}
    end)
  end

  defp count_contents(%{"shiny gold" => contents} = bags, count \\ 0) do
    count_contents(contents, bags, count)
  end

  defp count_contents(contents, bags, count) do
    Enum.reduce(contents, count, fn {color, number}, sum ->
      number + sum + number * count_contents(Map.fetch!(bags, color), bags, 0)
    end)
  end

  defp count_containers(bags) do
    bags
    |> Map.keys()
    |> Enum.count(fn color -> contains?(color, bags) end)
  end

  defp contains?(color, bags) do
    contents = Map.fetch!(bags, color)

    Map.has_key?(contents, "shiny gold") or
      Enum.any?(contents, fn {other_color, _contents} ->
        contains?(other_color, bags)
      end)
  end
end

System.argv()
|> Bags.run()
|> IO.inspect()
