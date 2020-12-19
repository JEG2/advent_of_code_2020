defmodule Homework do
  def run(args) do
    {opts, [path]} = OptionParser.parse!(args, strict: [part_2: :boolean])

    if Keyword.get(opts, :part_2) do
      addition_then_multiplication(path)
    else
      left_to_right(path)
    end
  end

  def addition_then_multiplication(path) do
    path
    |> stream_parsed_equations
    |> evaluate_all(&add_then_multiply/1)
    |> sum_results
  end

  def left_to_right(path) do
    path
    |> stream_parsed_equations
    |> evaluate_all(&l2r/1)
    |> sum_results
  end

  defp stream_parsed_equations(path) do
    path
    |> File.stream!()
    |> Stream.map(&String.trim/1)
  end

  defp evaluate_all(equations, calculator) do
    Enum.map(equations, fn equation -> evaluate(equation, calculator) end)
  end

  defp evaluate(equation, calculator) do
    new_equation =
      String.replace(equation, ~r{\(\d+(?:\s*[+*]\s*\d+)+\)}, fn operations ->
        operations
        |> String.slice(1..-2)
        |> calculator.()
      end)

    if equation == new_equation do
      equation
      |> calculator.()
      |> String.to_integer()
    else
      evaluate(new_equation, calculator)
    end
  end

  defp l2r(equation) do
    new_equation =
      String.replace(equation, ~r{\A\d+\s*[+*]\s*\d+\s*}, fn math ->
        math |> Code.eval_string() |> elem(0) |> to_string
      end)

    if equation == new_equation do
      equation
    else
      l2r(new_equation)
    end
  end

  defp add_then_multiply(equation) do
    new_equation =
      String.replace(
        equation,
        ~r{\d+\s*\+\s*\d+\s*},
        fn math ->
          math |> Code.eval_string() |> elem(0) |> to_string
        end,
        global: false
      )

    if equation == new_equation do
      multiply(equation)
    else
      add_then_multiply(new_equation)
    end
  end

  defp multiply(equation) do
    new_equation =
      String.replace(
        equation,
        ~r{\d+\s*\*\s*\d+\s*},
        fn math ->
          math |> Code.eval_string() |> elem(0) |> to_string
        end,
        global: false
      )

    if equation == new_equation do
      equation
    else
      multiply(new_equation)
    end
  end

  defp sum_results(results), do: Enum.reduce(results, 0, &Kernel.+/2)
end

System.argv()
|> Homework.run()
|> IO.puts()
