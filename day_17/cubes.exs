defmodule Cubes do
  defmodule Simulation do
    defstruct cubes: MapSet.new(),
              min_x: 0,
              max_x: 0,
              min_y: 0,
              max_y: 0,
              min_z: 0,
              max_z: 0

    def new(fields \\ []), do: struct!(__MODULE__, fields)

    def activate(sim, {x, y, z} = xyz) do
      new_cubes = MapSet.put(sim.cubes, xyz)
      new_min_x = Enum.min([x, sim.min_x])
      new_max_x = Enum.max([x, sim.max_x])
      new_min_y = Enum.min([y, sim.min_y])
      new_max_y = Enum.max([y, sim.max_y])
      new_min_z = Enum.min([z, sim.min_z])
      new_max_z = Enum.max([z, sim.max_z])

      %__MODULE__{
        sim
        | cubes: new_cubes,
          min_x: new_min_x,
          max_x: new_max_x,
          min_y: new_min_y,
          max_y: new_max_y,
          min_z: new_min_z,
          max_z: new_max_z
      }
    end

    def deactivate(sim, xyz) do
      new_cubes = MapSet.delete(sim.cubes, xyz)
      %__MODULE__{sim | cubes: new_cubes}
    end

    def active?(sim, xyz), do: MapSet.member?(sim.cubes, xyz)

    def advance(sim) do
      Enum.reduce((sim.min_z - 1)..(sim.max_z + 1), sim, fn z, s__ ->
        Enum.reduce((sim.min_y - 1)..(sim.max_y + 1), s__, fn y, s_ ->
          Enum.reduce((sim.min_x - 1)..(sim.max_x + 1), s_, fn x, s ->
            case {active?(sim, {x, y, z}), count_neighbors(sim, {x, y, z})} do
              {true, count} when count not in [2, 3] ->
                Simulation.deactivate(s, {x, y, z})

              {false, count} when count == 3 ->
                Simulation.activate(s, {x, y, z})

              _other ->
                s
            end
          end)
        end)
      end)
      |> shrink
    end

    def shrink(sim) do
      {new_min_x, new_max_x} =
        sim.cubes
        |> Enum.map(fn {x, _y, _z} -> x end)
        |> Enum.min_max()

      {new_min_y, new_max_y} =
        sim.cubes
        |> Enum.map(fn {_x, y, _z} -> y end)
        |> Enum.min_max()

      {new_min_z, new_max_z} =
        sim.cubes
        |> Enum.map(fn {_x, _y, z} -> z end)
        |> Enum.min_max()

      %__MODULE__{
        sim
        | min_x: new_min_x,
          max_x: new_max_x,
          min_y: new_min_y,
          max_y: new_max_y,
          min_z: new_min_z,
          max_z: new_max_z
      }
    end

    def count_neighbors(sim, {x, y, z}) do
      for z_offset <- -1..1,
          y_offset <- -1..1,
          x_offset <- -1..1,
          not (x_offset == 0 and y_offset == 0 and z_offset == 0) do
        {x + x_offset, y + y_offset, z + z_offset}
      end
      |> Enum.reduce(0, fn xyz, count ->
        if Simulation.active?(sim, xyz) do
          count + 1
        else
          count
        end
      end)
    end

    def count_cubes(sim), do: MapSet.size(sim.cubes)
  end

  defimpl String.Chars, for: Simulation do
    def to_string(sim) do
      Enum.reduce(sim.min_z..sim.max_z, "", fn z, output ->
        Enum.reduce(sim.min_y..sim.max_y, output <> "z=#{z}\n", fn y, out ->
          Enum.reduce(sim.min_x..sim.max_x, out, fn x, o ->
            if Simulation.active?(sim, {x, y, z}) do
              o <> "#"
            else
              o <> "."
            end
          end)
          |> Kernel.<>("\n")
        end)
        |> Kernel.<>("\n")
      end)
    end
  end

  def run(args) do
    {opts, [path]} = OptionParser.parse!(args, strict: [part_2: :boolean])

    # if Keyword.get(opts, :part_2) do
    #   identify_field_names(path)
    # else
    simulate_boot(path)
    # end
  end

  def simulate_boot(path) do
    path
    |> read_initial_state
    |> boot
  end

  defp read_initial_state(path) do
    path
    |> File.stream!()
    |> Stream.map(&String.trim/1)
    |> Stream.with_index()
    |> Enum.reduce(Simulation.new(), fn {row, y}, sim ->
      row
      |> String.graphemes()
      |> Enum.with_index()
      |> Enum.reduce(sim, fn
        {"#", x}, s ->
          Simulation.activate(s, {x, y, 0})

        {".", _x}, s ->
          s
      end)
    end)
  end

  def boot(sim) do
    sim
    |> Stream.iterate(&Simulation.advance/1)
    |> Stream.drop(6)
    |> Enum.take(1)
    |> hd
    |> Simulation.count_cubes()
  end
end

System.argv()
|> Cubes.run()
|> IO.inspect()
