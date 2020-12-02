defmodule ExpenseReport do
  def run(args) do
    {opts, [path]} = OptionParser.parse!(args, strict: [part_2: :boolean])

    if Keyword.get(opts, :part_2) do
      find_three(path)
    else
      find_two(path)
    end
  end

  def find_two(path) do
    path
    |> read_expenses
    |> add_two_to(2020)
    |> multiply
  end

  def find_three(path) do
    path
    |> read_expenses
    |> add_three_to(2020)
    |> multiply
  end

  defp read_expenses(path) do
    path
    |> File.stream!()
    |> Enum.map(fn expense ->
      expense
      |> String.trim()
      |> String.to_integer()
    end)
  end

  defp add_two_to([], _goal), do: nil

  defp add_two_to([i | rest], goal) do
    case Enum.find(rest, fn j -> i + j == goal end) do
      j when is_integer(j) -> [i, j]
      nil -> add_two_to(rest, goal)
    end
  end

  defp add_three_to([i | rest], goal) do
    case add_two_to(rest, goal - i) do
      [j, k] -> [i, j, k]
      nil -> add_three_to(rest, goal)
    end
  end

  defp multiply(expenses), do: Enum.reduce(expenses, 1, fn i, j -> i * j end)
end

System.argv()
|> ExpenseReport.run()
|> IO.puts()
