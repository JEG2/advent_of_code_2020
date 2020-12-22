defmodule Images do
  def run(args) do
    {opts, [path]} = OptionParser.parse!(args, strict: [part_2: :boolean])

    if Keyword.get(opts, :part_2) do
      measure_waters(path)
    else
      multiply_corners(path)
    end
  end

  defp measure_waters(path) do
    path
    |> read_tiles
    |> build_orientations
    |> match_edges
    |> arrange_tiles
    |> build_image
    |> find_sea_monster
    |> count_waves
  end

  defp multiply_corners(path) do
    path
    |> read_tiles
    |> build_orientations
    |> match_edges
    |> arrange_tiles
    |> filter_down_to_corners
    |> multiply_ids
  end

  defp read_tiles(path) do
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

      {id, tile}
    end)
  end

  defp build_orientations(tiles) do
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

      edges =
        Enum.map(orientations, fn orientation ->
          [
            List.first(orientation),
            orientation
            |> Enum.map(fn row -> String.at(row, -1) end)
            |> Enum.join(),
            List.last(orientation),
            orientation
            |> Enum.map(fn row -> String.at(row, 0) end)
            |> Enum.join()
          ]
        end)

      {id, tile, orientations, edges}
    end)
  end

  defp rotate(image) do
    image
    |> Enum.reverse()
    |> Enum.reduce(List.duplicate("", length(image)), fn row, columns ->
      columns
      |> Enum.zip(String.graphemes(row))
      |> Enum.map(fn {new_row, pixel} -> new_row <> pixel end)
    end)
  end

  defp flip(image), do: Enum.reverse(image)

  defp match_edges(tiles) do
    matches =
      Enum.reduce(tiles, %{}, fn {id, _tile, _orientations, edges}, matches ->
        Enum.reduce(0..7, put_in(matches, [id], %{}), fn oi, matches ->
          Enum.reduce(0..3, put_in(matches, [id, oi], %{}), fn ei, matches ->
            edge = edges |> Enum.at(oi) |> Enum.at(ei)

            edges =
              tiles
              |> Stream.reject(fn
                {other_id, _other_tile, _other_orientations, _other_edges} ->
                  other_id == id
              end)
              |> Stream.flat_map(fn
                {other_id, _other_tile, _other_orientations, other_edges} ->
                  Enum.flat_map(0..7, fn other_oi ->
                    Enum.map(0..3, fn other_ei ->
                      other_edge =
                        other_edges
                        |> Enum.at(other_oi)
                        |> Enum.at(other_ei)

                      {other_id, other_oi, other_ei, other_edge}
                    end)
                  end)
              end)
              |> Stream.filter(fn
                {_other_id, _other_oi, _other_ei, other_edge} ->
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

    {tiles, matches}
  end

  defp arrange_tiles({tiles, matches}) do
    grid_size = tiles |> length |> :math.sqrt() |> trunc

    grid =
      matches
      |> place_northwest_corner
      |> finish_row(grid_size, 0)
      |> place_remaining_rows(grid_size)

    {tiles, grid}
  end

  defp place_northwest_corner(matches) do
    {corner, orientations} =
      Enum.find(matches, fn {_id, orientations} ->
        Enum.all?(orientations, fn {_orientation, edges} ->
          map_size(edges) == 2
        end)
      end)

    {orientation, _edges} =
      Enum.find(orientations, fn {_orientation, edges} ->
        Enum.sort(Map.keys(edges)) == [1, 2]
      end)

    {%{{0, 0} => {corner, orientation}}, matches}
  end

  defp finish_row({grid, matches}, grid_size, y) do
    new_grid =
      Enum.reduce(1..(grid_size - 1), grid, fn x, g ->
        {left_id, left_orientation} = Map.fetch!(g, {x - 1, y})

        connection =
          matches
          |> Stream.flat_map(fn {id, orientations} ->
            Enum.flat_map(orientations, fn {orientation, edges} ->
              Enum.flat_map(edges, fn {edge, borders} ->
                Enum.map(
                  borders,
                  fn {other_id, other_orientation, other_edge} ->
                    {
                      id,
                      orientation,
                      edge,
                      other_id,
                      other_orientation,
                      other_edge
                    }
                  end
                )
              end)
            end)
          end)
          |> Enum.find(fn
            {_id, _orientation, 3, ^left_id, ^left_orientation, 1} -> true
            _non_match -> false
          end)

        Map.put(g, {x, y}, {elem(connection, 0), elem(connection, 1)})
      end)

    {new_grid, matches}
  end

  defp start_row({grid, matches}, y) do
    {up_id, up_orientation} = Map.fetch!(grid, {0, y - 1})

    {id, orientation, _edge} =
      matches
      |> get_in([up_id, up_orientation, 2])
      |> Enum.find(fn
        {_id, _orientation, 0} -> true
        _non_match -> false
      end)

    {Map.put(grid, {0, y}, {id, orientation}), matches}
  end

  defp place_remaining_rows({grid, matches}, grid_size) do
    Enum.reduce(1..(grid_size - 1), grid, fn y, g ->
      {g, matches}
      |> start_row(y)
      |> finish_row(grid_size, y)
      |> elem(0)
    end)
  end

  defp filter_down_to_corners({_tiles, grid}) do
    max_x = grid |> Map.keys() |> Enum.map(fn {x, _y} -> x end) |> Enum.max()
    max_y = grid |> Map.keys() |> Enum.map(fn {_x, y} -> y end) |> Enum.max()

    Enum.map(
      [{0, 0}, {max_x, 0}, {0, max_y}, {max_x, max_y}],
      fn xy -> grid |> Map.fetch!(xy) |> elem(0) end
    )
  end

  defp multiply_ids(corners), do: Enum.reduce(corners, &Kernel.*/2)

  defp build_image({tiles, grid}) do
    trimmed =
      Enum.into(grid, Map.new(), fn {xy, {id, orientation}} ->
        tile =
          tiles
          |> Enum.find(fn tile -> elem(tile, 0) == id end)
          |> elem(2)
          |> Enum.at(orientation)
          |> Enum.slice(1..-2)
          |> Enum.map(fn row -> String.slice(row, 1..-2) end)

        {xy, tile}
      end)

    max_y = grid |> Map.keys() |> Enum.map(fn {_x, y} -> y end) |> Enum.max()
    height = trimmed |> Map.fetch!({0, 0}) |> length

    0..max_y
    |> Enum.flat_map(fn y ->
      trimmed
      |> Enum.filter(fn
        {{_x, ^y}, _tile} -> true
        _non_match -> false
      end)
      |> Enum.sort_by(fn {{x, ^y}, _tile} -> x end)
      |> Enum.reduce(List.duplicate("", height), fn {_xy, lines}, joined ->
        joined
        |> Enum.zip(lines)
        |> Enum.map(fn {j, l} -> j <> l end)
      end)
    end)
  end

  defp find_sea_monster(image) do
    image
    |> Stream.iterate(&rotate/1)
    |> Enum.take(4)
    |> Kernel.++(
      image
      |> flip
      |> Stream.iterate(&rotate/1)
      |> Enum.take(4)
    )
    |> Enum.find(&contains_sea_monster?/1)
  end

  @sea_monster [
    {0, 1},
    {1, 2},
    {4, 2},
    {5, 1},
    {6, 1},
    {7, 2},
    {10, 2},
    {11, 1},
    {12, 1},
    {13, 2},
    {16, 2},
    {17, 1},
    {18, 0},
    {18, 1},
    {19, 1}
  ]

  defp contains_sea_monster?(image), do: count_sea_monsters(image) > 0

  defp count_sea_monsters(image) do
    max_x = image |> hd() |> String.length() |> Kernel.-(19)
    max_y = image |> length |> Kernel.-(3)

    Enum.reduce(0..max_y, 0, fn y, count ->
      Enum.reduce(0..max_x, count, fn x, c ->
        sea_monster_here? =
          Enum.all?(@sea_monster, fn {x_offset, y_offset} ->
            image
            |> Enum.at(y + y_offset)
            |> String.at(x + x_offset)
            |> Kernel.==("#")
          end)

        if sea_monster_here? do
          c + 1
        else
          c
        end
      end)
    end)
  end

  defp count_waves(image) do
    image
    |> Enum.join()
    |> String.graphemes()
    |> Enum.count(fn calm_or_wave -> calm_or_wave == "#" end)
    |> Kernel.-(length(@sea_monster) * count_sea_monsters(image))
  end
end

System.argv()
|> Images.run()
|> IO.inspect()
