defmodule Images do
  def run(args) do
    {opts, [path]} = OptionParser.parse!(args, strict: [part_2: :boolean])

    # if Keyword.get(opts, :part_2) do
    #   recursively_match(path)
    # else
    find_corners(path)
    # end
  end

  def find_corners(path) do
    path
    |> read_tile_borders
    |> flip_and_rotate
    |> match_edges
    |> filter_down_to_corners
    |> multiply_ids
  end

  defp read_tile_borders(path) do
    path
    |> File.stream!()
    |> Stream.map(&String.trim/1)
    |> Stream.chunk_by(fn line -> line != "" end)
    |> Stream.reject(fn chunk -> chunk == [""] end)
    |> Enum.map(fn ["Tile " <> name | tile] ->
      id =
        name
        |> String.slice(0..-2)
        |> String.to_integer()

      edges = [
        List.first(tile),
        tile
        |> Enum.map(fn row -> String.at(row, -1) end)
        |> Enum.join(),
        List.last(tile),
        tile
        |> Enum.map(fn row -> String.at(row, 0) end)
        |> Enum.join()
      ]

      {id, edges}
    end)
  end

  defp flip_and_rotate(tiles) do
    Enum.map(tiles, fn {id, tile} ->
      orientations =
        tile
        |> Stream.iterate(&rotate/1)
        |> Enum.take(4)
        |> Kernel.++(
          tile
          |> flip
          |> Stream.iterate(&rotate/1)
          |> Enum.take(4)
        )

      {id, orientations}
    end)
  end

  defp flip([n, e, s, w]), do: [s, w, n, e]

  defp rotate([n, e, s, w]), do: [String.reverse(w), n, String.reverse(e), s]

  defp match_edges(tiles) do
    Enum.reduce(tiles, %{}, fn {id, tile}, matches ->
      Enum.reduce(0..7, put_in(matches, [id], %{}), fn oi, matches ->
        Enum.reduce(0..3, put_in(matches, [id, oi], %{}), fn ei, matches ->
          edge = tile |> Enum.at(oi) |> Enum.at(ei)

          edges =
            tiles
            |> Stream.reject(fn {other_id, _other_tile} -> other_id == id end)
            |> Stream.flat_map(fn {other_id, other_tile} ->
              Enum.flat_map(0..7, fn other_oi ->
                Enum.map(0..3, fn other_ei ->
                  other_edge =
                    other_tile
                    |> Enum.at(other_oi)
                    |> Enum.at(other_ei)

                  {other_id, other_oi, other_ei, other_edge}
                end)
              end)
            end)
            |> Stream.filter(fn {_other_id, _other_oi, _other_ei, other_edge} ->
              other_edge == edge
            end)
            |> Enum.map(fn {other_id, other_oi, other_ei, _other_edge} ->
              {other_id, other_oi, other_ei}
            end)

          if edges == [] do
            matches
          else
            put_in(matches, [id, oi, ei], edges)
          end
        end)
      end)
    end)
  end

  defp filter_down_to_corners(matches) do
    Enum.filter(matches, fn {_id, orientations} ->
      Enum.all?(orientations, fn {_oi, edges} -> map_size(edges) == 2 end)
    end)
  end

  defp multiply_ids(corners) do
    corners
    |> Enum.map(fn {id, _orientations} -> id end)
    |> Enum.reduce(&Kernel.*/2)
  end
end

System.argv()
|> Images.run()
|> IO.inspect()
