defmodule Rain do
  def run(args) do
    {opts, [path]} = OptionParser.parse!(args, strict: [part_2: :boolean])

    if Keyword.get(opts, :part_2) do
      follow_waypoint_instructions(path)
    else
      follow_instructions(path)
    end
  end

  def follow_waypoint_instructions(path) do
    path
    |> stream_instructions
    |> follow_waypoint
    |> calculate_distance
  end

  def follow_instructions(path) do
    path
    |> stream_instructions
    |> follow
    |> calculate_distance
  end

  defp stream_instructions(path) do
    path
    |> File.stream!()
    |> Stream.map(&String.trim/1)
    |> Stream.map(fn <<instruction::binary-size(1), number::binary>> ->
      {String.to_atom(instruction), String.to_integer(number)}
    end)
  end

  defp follow_waypoint(instructions) do
    Enum.reduce(instructions, {0, 0, 10, -1}, fn instruction, x_y_facing ->
      waypoint_move(x_y_facing, instruction)
    end)
  end

  defp follow(instructions) do
    Enum.reduce(instructions, {0, 0, :E}, fn instruction, x_y_facing ->
      move(x_y_facing, instruction)
    end)
  end

  defp waypoint_move({x, y, wx, wy}, {:N, count}),
    do: {x, y, wx, wy - count}

  defp waypoint_move({x, y, wx, wy}, {:S, count}),
    do: {x, y, wx, wy + count}

  defp waypoint_move({x, y, wx, wy}, {:E, count}),
    do: {x, y, wx + count, wy}

  defp waypoint_move({x, y, wx, wy}, {:W, count}),
    do: {x, y, wx - count, wy}

  defp waypoint_move({x, y, wx, wy}, {:L, 90}), do: {x, y, wy, -wx}
  defp waypoint_move({x, y, wx, wy}, {:L, 180}), do: {x, y, -wx, -wy}
  defp waypoint_move({x, y, wx, wy}, {:L, 270}), do: {x, y, -wy, wx}
  defp waypoint_move({x, y, wx, wy}, {:R, 90}), do: {x, y, -wy, wx}
  defp waypoint_move({x, y, wx, wy}, {:R, 180}), do: {x, y, -wx, -wy}
  defp waypoint_move({x, y, wx, wy}, {:R, 270}), do: {x, y, wy, -wx}

  defp waypoint_move({x, y, wx, wy}, {:F, count}),
    do: {x + wx * count, y + wy * count, wx, wy}

  defp move({x, y, facing}, {:N, count}), do: {x, y - count, facing}
  defp move({x, y, facing}, {:S, count}), do: {x, y + count, facing}
  defp move({x, y, facing}, {:E, count}), do: {x + count, y, facing}
  defp move({x, y, facing}, {:W, count}), do: {x - count, y, facing}
  defp move({x, y, :N}, {:L, 90}), do: {x, y, :W}
  defp move({x, y, :S}, {:L, 90}), do: {x, y, :E}
  defp move({x, y, :E}, {:L, 90}), do: {x, y, :N}
  defp move({x, y, :W}, {:L, 90}), do: {x, y, :S}
  defp move({x, y, :N}, {:L, 180}), do: {x, y, :S}
  defp move({x, y, :S}, {:L, 180}), do: {x, y, :N}
  defp move({x, y, :E}, {:L, 180}), do: {x, y, :W}
  defp move({x, y, :W}, {:L, 180}), do: {x, y, :E}
  defp move({x, y, :N}, {:L, 270}), do: {x, y, :E}
  defp move({x, y, :S}, {:L, 270}), do: {x, y, :W}
  defp move({x, y, :E}, {:L, 270}), do: {x, y, :S}
  defp move({x, y, :W}, {:L, 270}), do: {x, y, :N}
  defp move({x, y, :N}, {:R, 90}), do: {x, y, :E}
  defp move({x, y, :S}, {:R, 90}), do: {x, y, :W}
  defp move({x, y, :E}, {:R, 90}), do: {x, y, :S}
  defp move({x, y, :W}, {:R, 90}), do: {x, y, :N}
  defp move({x, y, :N}, {:R, 180}), do: {x, y, :S}
  defp move({x, y, :S}, {:R, 180}), do: {x, y, :N}
  defp move({x, y, :E}, {:R, 180}), do: {x, y, :W}
  defp move({x, y, :W}, {:R, 180}), do: {x, y, :E}
  defp move({x, y, :N}, {:R, 270}), do: {x, y, :W}
  defp move({x, y, :S}, {:R, 270}), do: {x, y, :E}
  defp move({x, y, :E}, {:R, 270}), do: {x, y, :N}
  defp move({x, y, :W}, {:R, 270}), do: {x, y, :S}

  defp move({x, y, facing}, {:F, count}),
    do: move({x, y, facing}, {facing, count})

  defp calculate_distance({x, y, _wx, _wy}), do: abs(x) + abs(y)
  defp calculate_distance({x, y, _facing}), do: abs(x) + abs(y)
end

System.argv()
|> Rain.run()
|> IO.puts()
