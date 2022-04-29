defmodule Fixtures.Update do
  alias Hui.Query.Update
  alias Hui.Encoder

  def single_doc() do
    %{
      "actor_ss" => ["Harrison Ford", "Rutger Hauer", "Sean Young", "Edward James Olmos"],
      "desc" =>
        "A blade runner must pursue and terminate four replicants who stole a ship in space, and have returned to Earth to find their creator.",
      "directed_by" => ["Ridley Scott"],
      "genre" => ["Sci-Fi", "Thriller"],
      "id" => "tt0083658",
      "initial_release_date" => "1982-06-25",
      "name" => "Blade Runner"
    }
  end

  def single_doc_update_json(doc \\ single_doc(), opts \\ []), do: "{#{add_doc_update_json(doc, opts)}}"

  defp add_doc_update_json(doc, opts) do
    within =
      case Keyword.get(opts, :commitWithin) do
        nil -> ""
        _ -> "\"commitWithin\":#{Keyword.get(opts, :commitWithin)}"
      end

    overwrite =
      case Keyword.get(opts, :overwrite) do
        nil -> ""
        _ -> "\"overwrite\":#{Keyword.get(opts, :overwrite)}"
      end

    doc = "\"doc\":" <> (doc |> Jason.encode!())

    clauses = [within, overwrite, doc] |> Enum.reject(&(&1 == ""))
    "\"add\":{#{clauses |> Enum.join(",")}}"
  end

  def multi_docs() do
    [
      %{
        "actor_ss" => ["János Derzsi", "Erika Bók", "Mihály Kormos", "Ricsi"],
        "desc" => "A rural farmer is forced to confront the mortality of his faithful horse.",
        "directed_by" => ["Béla Tarr", "Ágnes Hranitzky"],
        "genre" => ["Drama"],
        "id" => "tt1316540",
        "initial_release_date" => "2011-03-31",
        "name" => "The Turin Horse"
      },
      %{
        "actor_ss" => ["Masami Nagasawa", "Hiroshi Abe", "Kanna Hashimoto", "Yoshio Harada"],
        "desc" =>
          "Twelve-year-old Koichi, who has been separated from his brother Ryunosuke due to his parents' divorce, hears a rumor that the new bullet trains will precipitate a wish-granting miracle when they pass each other at top speed.",
        "directed_by" => ["Hirokazu Koreeda"],
        "genre" => ["Drame"],
        "id" => "tt1650453",
        "initial_release_date" => "2011-06-11",
        "name" => "I Wish"
      }
    ]
  end

  def multi_docs_update_json(docs \\ multi_docs(), opts \\ []) do
    "{" <> Enum.map_join(docs, ",", &add_doc_update_json(&1, opts)) <> "}"
  end

  def update_json(doc, cmds), do: %Update{struct(Update, cmds) | doc: doc} |> Encoder.encode()
  def update_json(doc), do: %Update{doc: doc} |> Encoder.encode()
end
