defmodule Seating do
  defmodule Simulation do
    import Kernel, except: [to_string: 1]

    defstruct seats: Map.new(), width: nil, height: nil

    def new, do: %__MODULE__{}

    def open_seat(sim, x, y) do
      %__MODULE__{sim | seats: Map.put(sim.seats, {x, y}, :open)}
    end

    def find_dimensions(sim) do
      %__MODULE__{
        sim
        | width: find_edge(sim.seats, fn {{x, _y}, _seat} -> x end),
          height: find_edge(sim.seats, fn {{_x, y}, _seat} -> y end)
      }
    end

    def advance(sim) do
      new_seats =
        Enum.reduce(sim.seats, sim.seats, fn
          {{x, y}, :open}, next ->
            case occupied_adjacent_count(sim, x, y) do
              0 ->
                Map.put(next, {x, y}, :full)

              _not_empty ->
                next
            end

          {{x, y}, :full}, next ->
            case occupied_adjacent_count(sim, x, y) do
              count when count >= 4 ->
                Map.put(next, {x, y}, :open)

              _not_empty ->
                next
            end
        end)

      %__MODULE__{sim | seats: new_seats}
    end

    def advance_with_line_of_sight(sim) do
      new_seats =
        Enum.reduce(sim.seats, sim.seats, fn
          {{x, y}, :open}, next ->
            case occupied_in_sight_count(sim, x, y) do
              0 ->
                Map.put(next, {x, y}, :full)

              _not_empty ->
                next
            end

          {{x, y}, :full}, next ->
            case occupied_in_sight_count(sim, x, y) do
              count when count >= 5 ->
                Map.put(next, {x, y}, :open)

              _not_empty ->
                next
            end
        end)

      %__MODULE__{sim | seats: new_seats}
    end

    def count_occupied(sim) do
      Enum.count(sim.seats, fn {_xy, seat} -> seat == :full end)
    end

    defp occupied_adjacent_count(sim, x, y) do
      [{-1, -1}, {0, -1}, {1, -1}, {-1, 0}, {1, 0}, {-1, 1}, {0, 1}, {1, 1}]
      |> Enum.map(fn {x_offset, y_offset} -> {x + x_offset, y + y_offset} end)
      |> Enum.reject(fn nxy -> off_grid?(sim, nxy) end)
      |> Enum.reduce(0, fn nxy, sum ->
        if Map.get(sim.seats, nxy) == :full do
          sum + 1
        else
          sum
        end
      end)
    end

    defp occupied_in_sight_count(sim, x, y) do
      [{-1, -1}, {0, -1}, {1, -1}, {-1, 0}, {1, 0}, {-1, 1}, {0, 1}, {1, 1}]
      |> Enum.map(fn {x_offset, y_offset} ->
        next_seat(sim, x, y, x_offset, y_offset)
      end)
      |> Enum.reject(fn nxy -> is_nil(nxy) or off_grid?(sim, nxy) end)
      |> Enum.reduce(0, fn nxy, sum ->
        if Map.get(sim.seats, nxy) == :full do
          sum + 1
        else
          sum
        end
      end)
      |> IO.inspect(label: "{#{x}, #{y}}")
    end

    defp next_seat(sim, x, y, x_offset, y_offset) do
      new_xy = {x + x_offset, y + y_offset}

      if Map.has_key?(sim.seats, new_xy) do
        new_xy
      else
        if off_grid?(sim, new_xy) do
          nil
        else
          next_seat(sim, elem(new_xy, 0), elem(new_xy, 1), x_offset, y_offset)
        end
      end
    end

    defp off_grid?(sim, {x, y}) do
      not (x >= 0 and x < sim.width and y >= 0 and y < sim.height)
    end

    defp find_edge(seats, coord_fun) do
      seats
      |> Enum.map(coord_fun)
      |> Enum.max()
      |> Kernel.+(1)
    end

    def to_string(sim) do
      Enum.map(0..(sim.height - 1), fn y ->
        Enum.map(0..(sim.width - 1), fn x ->
          case Map.get(sim.seats, {x, y}, :floor) do
            :open -> "L"
            :full -> "#"
            :floor -> "."
          end
        end)
        |> Enum.join("")
      end)
      |> Enum.join("\n")
    end
  end

  def run(args) do
    {opts, [path]} = OptionParser.parse!(args, strict: [part_2: :boolean])

    if Keyword.get(opts, :part_2) do
      simulate_with_sight_until_stable(path)
    else
      simulate_until_stable(path)
    end
  end

  def simulate_with_sight_until_stable(path) do
    path
    |> read_seats
    |> stabilize_with_sight
    |> count_occupied
  end

  def simulate_until_stable(path) do
    path
    |> read_seats
    |> stabilize
    |> count_occupied
  end

  defp read_seats(path) do
    path
    |> File.stream!()
    |> Stream.with_index()
    |> Enum.reduce(Simulation.new(), fn {row, y}, sim ->
      row
      |> String.trim()
      |> String.graphemes()
      |> Enum.with_index()
      |> Enum.reduce(sim, fn
        {"L", x}, s ->
          Simulation.open_seat(s, x, y)

        {_floor, _x}, s ->
          s
      end)
    end)
    |> Simulation.find_dimensions()
  end

  defp stabilize_with_sight(sim) do
    new_sim = Simulation.advance_with_line_of_sight(sim)

    if sim == new_sim do
      sim
    else
      stabilize_with_sight(new_sim)
    end
  end

  defp stabilize(sim) do
    new_sim = Simulation.advance(sim)

    if sim == new_sim do
      sim
    else
      stabilize(new_sim)
    end
  end

  defp count_occupied(sim) do
    Simulation.count_occupied(sim)
  end
end

System.argv()
|> Seating.run()
|> IO.inspect()
