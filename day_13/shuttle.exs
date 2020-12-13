defmodule Shuttle do
  def run(args) do
    {opts, [path]} = OptionParser.parse!(args, strict: [part_2: :boolean])

    if Keyword.get(opts, :part_2) do
      win_contest(path)
    else
      ignore_xs(path)
    end
  end

  def win_contest(path) do
    path
    |> read_schedule
    |> prepare_offsets
    |> find_timeset
  end

  def ignore_xs(path) do
    path
    |> read_schedule
    |> remove_xs
    |> find_earliest_depature
    |> multiply
  end

  defp read_schedule(path) do
    File.open!(path, fn f ->
      available =
        f
        |> IO.read(:line)
        |> String.trim()
        |> String.to_integer()

      busses =
        f
        |> IO.read(:line)
        |> String.trim()
        |> String.split(",")
        |> Enum.map(fn
          "x" -> :x
          bus_id -> String.to_integer(bus_id)
        end)

      {available, busses}
    end)
  end

  defp prepare_offsets({_available, busses}) do
    busses
    |> Enum.with_index()
    |> Enum.reject(fn {bus_id, _offset} -> bus_id == :x end)
  end

  defp find_timeset([{first, 0} | rest]) do
    rest
    |> Enum.reduce({first, first}, fn {bus_id, offset}, {t, step} ->
      new_t =
        t
        |> Stream.iterate(fn t -> t + step end)
        |> Enum.find(fn t -> rem(t + offset, bus_id) == 0 end)

      {new_t, step * bus_id}
    end)
    |> elem(0)
  end

  defp remove_xs({available, busses}) do
    {available, Enum.reject(busses, fn bus_id -> bus_id == :x end)}
  end

  defp find_earliest_depature({available, busses}) do
    busses
    |> Enum.map(fn bus_id ->
      departure =
        bus_id
        |> Stream.iterate(fn time -> time + bus_id end)
        |> Enum.find(fn time -> time >= available end)

      {bus_id, departure}
    end)
    |> Enum.min_by(fn {_id, departure} -> departure end)
    |> Tuple.append(available)
  end

  defp multiply({id, departure, available}), do: id * (departure - available)
end

System.argv()
|> Shuttle.run()
|> IO.puts()
