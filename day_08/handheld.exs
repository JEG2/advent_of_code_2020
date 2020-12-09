defmodule Handheld do
  defmodule Operation do
    def parse("acc " <> arg), do: {:acc, String.to_integer(arg)}
    def parse("jmp " <> arg), do: {:jmp, String.to_integer(arg)}
    def parse("nop " <> arg), do: {:nop, String.to_integer(arg)}
  end

  defmodule Program do
    def parse(path) do
      path
      |> File.stream!()
      |> Stream.map(&String.trim/1)
      |> Enum.with_index()
      |> Enum.into(Map.new(), fn {line, i} -> {i, Operation.parse(line)} end)
    end
  end

  defmodule VM do
    def new(program), do: {program, 0, 0}

    def advance({program, cursor, acc} = vm) do
      case Map.get(program, cursor) do
        operation when is_tuple(operation) ->
          execute(vm, operation)

        nil ->
          {:halted, acc}
      end
    end

    defp execute({program, cursor, acc}, {:acc, arg}) do
      {program, cursor + 1, acc + arg}
    end

    defp execute({program, cursor, acc}, {:jmp, arg}) do
      {program, cursor + arg, acc}
    end

    defp execute({program, cursor, acc}, {:nop, _arg}) do
      {program, cursor + 1, acc}
    end
  end

  def run(args) do
    {opts, [path]} = OptionParser.parse!(args, strict: [part_2: :boolean])

    if Keyword.get(opts, :part_2) do
      repair_program(path)
    else
      find_infinite_loop(path)
    end
  end

  def repair_program(path) do
    path
    |> Program.parse()
    |> repair
  end

  def find_infinite_loop(path) do
    path
    |> Program.parse()
    |> VM.new()
    |> find_loop
  end

  defp repair(program) do
    program
    |> Stream.map(fn
      {_i, {:acc, _arg}} ->
        {:loop, :acc}

      {i, {:jmp, arg}} ->
        program
        |> Map.put(i, {:nop, arg})
        |> VM.new()
        |> run_to_loop_or_halt

      {i, {:nop, arg}} ->
        program
        |> Map.put(i, {:jmp, arg})
        |> VM.new()
        |> run_to_loop_or_halt
    end)
    |> Enum.find(fn
      {:halted, _acc} ->
        true

      {:loop, _acc} ->
        false
    end)
    |> elem(1)
  end

  defp find_loop(vm) do
    {:loop, acc} = run_to_loop_or_halt(vm)
    acc
  end

  defp run_to_loop_or_halt(vm) do
    Stream.resource(
      fn -> {vm, MapSet.new()} end,
      fn
        {{_program, cursor, acc} = vm, seen} ->
          if MapSet.member?(seen, cursor) do
            {[loop: acc], :done}
          else
            case VM.advance(vm) do
              {:halted, acc} ->
                {[halted: acc], :done}

              advanced ->
                {[], {advanced, MapSet.put(seen, cursor)}}
            end
          end

        :done ->
          {:halt, :done}
      end,
      fn :done -> :ok end
    )
    |> Enum.take(1)
    |> hd
  end
end

System.argv()
|> Handheld.run()
|> IO.puts()
