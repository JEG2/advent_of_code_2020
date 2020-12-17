defmodule Tickets do
  def run(args) do
    {opts, [path]} = OptionParser.parse!(args, strict: [part_2: :boolean])

    if Keyword.get(opts, :part_2) do
      identify_field_names(path)
    else
      calculate_ticket_scanning_error_rate(path)
    end
  end

  def identify_field_names(path) do
    path
    |> read_tickets
    |> prep_tickets
    |> identify_names
  end

  def calculate_ticket_scanning_error_rate(path) do
    path
    |> read_tickets
    |> sum_completely_invalid_fields
  end

  defp read_tickets(path) do
    File.open!(path, fn f ->
      fields =
        f
        |> read_lines_to("")
        |> parse_fields

      read_lines_to(f, "your ticket:")

      [yours] =
        f
        |> read_lines_to("")
        |> parse_tickets

      read_lines_to(f, "nearby tickets:")

      nearby =
        f
        |> read_lines_to(:eof)
        |> parse_tickets

      {fields, yours, nearby}
    end)
  end

  defp read_lines_to(file, target) do
    Stream.repeatedly(fn -> IO.read(file, :line) end)
    |> Stream.map(fn
      line when is_binary(line) ->
        String.trim(line)

      other ->
        other
    end)
    |> Enum.take_while(fn line -> line != target end)
  end

  defp parse_fields(fields) do
    Enum.into(fields, Map.new(), fn field ->
      case Regex.named_captures(
             ~r{\A(?<name>[^:]+):\s+(?<validation>.+)\z},
             field
           ) do
        %{"name" => name, "validation" => validation} ->
          ranges =
            validation
            |> String.split(" or ")
            |> Enum.map(fn range ->
              case Regex.named_captures(
                     ~r{\A(?<from>\d+)-(?<to>\d+)\z},
                     range
                   ) do
                %{"from" => from, "to" => to} ->
                  String.to_integer(from)..String.to_integer(to)

                nil ->
                  raise "Unexpected range definition:  #{range}"
              end
            end)

          {name, ranges}

        nil ->
          raise "Unexpected field definition:  #{field}"
      end
    end)
  end

  defp parse_tickets(tickets) do
    Enum.map(tickets, fn ticket ->
      ticket
      |> String.split(",")
      |> Enum.map(&String.to_integer/1)
    end)
  end

  defp sum_completely_invalid_fields({fields, _yours, nearby}) do
    validations =
      fields
      |> Map.values()
      |> List.flatten()

    nearby
    |> List.flatten()
    |> Enum.filter(fn n ->
      not Enum.any?(validations, fn validation -> n in validation end)
    end)
    |> Enum.sum()
  end

  defp prep_tickets({fields, yours, nearby}) do
    valid = Enum.filter(nearby, fn ticket -> valid?(fields, ticket) end)
    {fields, yours, valid}
  end

  defp valid?(fields, ticket) do
    validations =
      fields
      |> Map.values()
      |> List.flatten()

    Enum.all?(ticket, fn n ->
      Enum.any?(validations, fn validation -> n in validation end)
    end)
  end

  defp identify_names({fields, yours, nearby}) do
    [yours | nearby]
    |> identify_possibilities(fields)
    |> reduce_possibilities
    |> until_stable(&reduce_names/1)
    |> multiply_departures(yours)
  end

  defp identify_possibilities(tickets, fields) do
    Enum.map(tickets, fn ticket ->
      Enum.map(ticket, fn n ->
        fields
        |> Enum.filter(fn {_name, ranges} ->
          Enum.any?(ranges, fn range -> n in range end)
        end)
        |> Enum.map(fn {name, _ranges} -> name end)
        |> MapSet.new()
      end)
    end)
  end

  defp reduce_possibilities(possibilities) do
    possibilities
    |> Enum.reduce(fn names, acc ->
      names
      |> Enum.zip(acc)
      |> Enum.map(fn {l, r} -> MapSet.intersection(l, r) end)
    end)
  end

  defp until_stable(possibilities, change) do
    if Enum.all?(possibilities, fn names -> MapSet.size(names) == 1 end) do
      Enum.map(possibilities, fn names -> names |> MapSet.to_list() |> hd end)
    else
      until_stable(change.(possibilities), change)
    end
  end

  defp reduce_names(possibilities) do
    named =
      possibilities
      |> Enum.filter(fn names -> MapSet.size(names) == 1 end)
      |> Enum.map(fn names -> names |> MapSet.to_list() |> hd end)

    Enum.map(possibilities, fn names ->
      if MapSet.size(names) > 1 do
        MapSet.difference(names, MapSet.new(named))
      else
        names
      end
    end)
  end

  defp multiply_departures(names, ticket) do
    names
    |> Enum.zip(ticket)
    |> Enum.filter(fn {name, _n} -> String.starts_with?(name, "departure") end)
    |> Enum.map(fn {_name, n} -> n end)
    |> Enum.reduce(&Kernel.*/2)
  end
end

System.argv()
|> Tickets.run()
|> IO.puts()
