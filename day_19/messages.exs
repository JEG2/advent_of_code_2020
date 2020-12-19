defmodule Messages do
  def run(args) do
    {opts, [path]} = OptionParser.parse!(args, strict: [part_2: :boolean])

    if Keyword.get(opts, :part_2) do
      recursively_match(path)
    else
      complete_matches_for_rule_0(path)
    end
  end

  def recursively_match(path) do
    path
    |> read_rules_and_messages
    |> rules_to_regex(%{"8" => ~w[42 +], "11" => ~w[42 31 | 42 & 31]})
    |> count_matches
  end

  def complete_matches_for_rule_0(path) do
    path
    |> read_rules_and_messages
    |> rules_to_regex
    |> count_matches
  end

  defp read_rules_and_messages(path) do
    path
    |> File.stream!()
    |> Stream.map(&String.trim/1)
    |> Stream.chunk_by(fn line -> line != "" end)
    |> Enum.reject(fn chunk -> chunk == [""] end)
    |> List.to_tuple()
  end

  defp rules_to_regex({rules, messages}, overrides \\ Map.new()) do
    regex =
      rules
      |> parse_rules
      |> Map.merge(overrides)
      |> build_regex("0")

    {regex, messages}
  end

  defp parse_rules(rules) do
    Enum.into(rules, Map.new(), fn rule ->
      [name, match] = String.split(rule, ": ", parts: 2)

      character_or_sub_rules =
        case match do
          <<?", character::binary-size(1), ?">> ->
            <<character::binary>>

          sub_rules ->
            String.split(sub_rules, " ")
        end

      {name, character_or_sub_rules}
    end)
  end

  defp build_regex(_rules, "+"), do: "+"

  defp build_regex(rules, name) do
    rule = Map.fetch!(rules, name)

    regex =
      cond do
        is_binary(rule) ->
          rule

        "&" in rule ->
          group =
            rule
            |> Enum.map(fn
              "|" -> "|"
              "&" -> "(?&rec)"
              reference -> build_regex(rules, reference)
            end)
            |> Enum.join()

          "(?<rec>#{group})"

        "|" in rule ->
          group =
            rule
            |> Enum.map(fn
              "|" -> "|"
              reference -> build_regex(rules, reference)
            end)
            |> Enum.join()

          "(?:#{group})"

        rule ->
          rule
          |> Enum.map(fn reference -> build_regex(rules, reference) end)
          |> Enum.join()
      end

    if name == "0" do
      Regex.compile!("\\A#{regex}\\z")
    else
      regex
    end
  end

  defp count_matches({regex, messages}) do
    Enum.count(messages, fn message -> String.match?(message, regex) end)
  end
end

System.argv()
|> Messages.run()
|> IO.inspect()
