defmodule Docking do
  def run(args) do
    {opts, [path]} = OptionParser.parse!(args, strict: [part_2: :boolean])

    if Keyword.get(opts, :part_2) do
      mask_addresses(path)
    else
      mask_memory(path)
    end
  end

  def mask_addresses(path) do
    path
    |> stream_program
    |> run_program(&execute_floating/2)
    |> sum_memory
  end

  def mask_memory(path) do
    path
    |> stream_program
    |> run_program(&execute/2)
    |> sum_memory
  end

  defp stream_program(path) do
    path
    |> File.stream!()
    |> Stream.map(&String.trim/1)
  end

  defp run_program(instructions, fun) do
    Enum.reduce(instructions, {List.duplicate("X", 36), Map.new()}, fun)
  end

  defp execute_floating("mask = " <> _mask = instruction, mask_and_memory) do
    execute(instruction, mask_and_memory)
  end

  defp execute_floating(instruction, {mask, memory}) do
    [address, value] = parse_address_and_value(instruction)

    new_memory =
      address
      |> mask_address(mask)
      |> set_memory(value, memory)

    {mask, new_memory}
  end

  defp execute("mask = " <> mask, {_mask, memory}) do
    {String.graphemes(mask), memory}
  end

  defp execute(instruction, {mask, memory}) do
    [address, value] = parse_address_and_value(instruction)
    masked = mask_value(value, mask)
    {mask, Map.put(memory, address, masked)}
  end

  defp parse_address_and_value(instruction) do
    Regex.scan(~r{\d+}, instruction)
    |> List.flatten()
    |> Enum.map(&String.to_integer/1)
  end

  defp mask_address(address, mask) do
    address
    |> Integer.to_string(2)
    |> String.pad_leading(36, "0")
    |> String.graphemes()
    |> Enum.zip(mask)
    |> Enum.reduce([], fn
      {bit, "0"}, [] ->
        [bit]

      {_bit, "1"}, [] ->
        ["1"]

      {_bit, "X"}, [] ->
        ["0", "1"]

      {bit, "0"}, addresses ->
        Enum.map(addresses, fn a -> a <> bit end)

      {_bit, "1"}, addresses ->
        Enum.map(addresses, fn a -> a <> "1" end)

      {_bit, "X"}, addresses ->
        Enum.flat_map(addresses, fn a -> [a <> "0", a <> "1"] end)
    end)
    |> Enum.map(fn a -> String.to_integer(a, 2) end)
  end

  defp set_memory(addresses, value, memory) do
    Enum.reduce(addresses, memory, fn address, m ->
      Map.put(m, address, value)
    end)
  end

  defp mask_value(value, mask) do
    value
    |> Integer.to_string(2)
    |> String.pad_leading(36, "0")
    |> String.graphemes()
    |> Enum.zip(mask)
    |> Enum.map(fn
      {bit, "X"} -> bit
      {_bit, masked} -> masked
    end)
    |> Enum.join()
    |> String.to_integer(2)
  end

  defp sum_memory({_mask, memory}) do
    memory
    |> Map.values()
    |> Enum.reduce(&Kernel.+/2)
  end
end

System.argv()
|> Docking.run()
|> IO.puts()
