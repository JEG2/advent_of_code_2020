defmodule Allergens do
  def run(args) do
    {opts, [path]} = OptionParser.parse!(args, strict: [part_2: :boolean])

    if Keyword.get(opts, :part_2) do
      find_dangerous(path)
    else
      count_non_allergens(path)
    end
  end

  def find_dangerous(path) do
    path
    |> stream_ingredients_and_allergens
    |> identify_allergens
    |> list_dangerous
  end

  def count_non_allergens(path) do
    path
    |> stream_ingredients_and_allergens
    |> identify_allergens
    |> identify_non_allergens
    |> count
  end

  defp stream_ingredients_and_allergens(path) do
    path
    |> File.stream!()
    |> Stream.map(&String.trim/1)
    |> Enum.map(fn line ->
      [ingredients, allergens] = String.split(line, " (contains ")

      {
        ingredients |> String.split(" ") |> MapSet.new(),
        allergens |> String.slice(0..-2) |> String.split(", ")
      }
    end)
  end

  defp identify_allergens(labels) do
    identified =
      Enum.reduce(labels, Map.new(), fn {ingredients, allergens}, combined ->
        Enum.reduce(allergens, combined, fn allergen, c ->
          if Map.has_key?(c, allergen) do
            Map.update!(c, allergen, fn previous ->
              MapSet.intersection(previous, ingredients)
            end)
          else
            Map.put(c, allergen, ingredients)
          end
        end)
      end)

    {
      Enum.map(labels, fn {food, _allergens} -> food end),
      prune_allergens(identified)
    }
  end

  defp prune_allergens(allergens) do
    found =
      allergens
      |> Map.values()
      |> Enum.filter(fn possible -> MapSet.size(possible) == 1 end)
      |> Enum.reduce(&MapSet.union/2)

    pruned =
      Enum.into(allergens, Map.new(), fn {allergen, possible} ->
        new_possible =
          if MapSet.size(possible) == 1 do
            possible
          else
            MapSet.difference(possible, found)
          end

        {allergen, new_possible}
      end)

    if allergens == pruned do
      pruned
    else
      prune_allergens(pruned)
    end
  end

  defp identify_non_allergens({foods, allergens}) do
    identified =
      allergens
      |> Map.values()
      |> Enum.reduce(&MapSet.union/2)

    non_allergens =
      Enum.reduce(foods, MapSet.new(), fn food, combined ->
        MapSet.union(combined, MapSet.difference(food, identified))
      end)

    {foods, non_allergens}
  end

  defp count({foods, non_allergens}) do
    Enum.reduce(foods, 0, fn food, sum ->
      sum + MapSet.size(MapSet.intersection(food, non_allergens))
    end)
  end

  defp list_dangerous({_foods, allergens}) do
    allergens
    |> Enum.sort_by(fn {allergen, _ingredient} -> allergen end)
    |> Enum.map(fn {_allergen, ingredient} ->
      ingredient |> MapSet.to_list() |> hd
    end)
    |> Enum.join(",")
  end
end

System.argv()
|> Allergens.run()
|> IO.puts()
