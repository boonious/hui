defmodule HuiStructUpdateLiveTest do
  use ExUnit.Case, async: true
  import TestHelpers

  alias Hui.Query

  describe "structured update (live)" do
    @describetag live: false

    test "should post a single doc" do
      default_url = Hui.URL.default_url!()

      url = %Hui.URL{
        default_url
        | handler: "update",
          headers: [{"Content-type", "application/json"}]
      }

      delete_verify_doc_deletion(
        url,
        %Query.Update{delete_id: "tt0083658", commit: true},
        "tt0083658"
      )

      update_doc = File.read!("./test/data/update_doc2.json") |> Poison.decode!()
      doc_map = update_doc["add"]["doc"]
      x = %Query.Update{doc: doc_map}

      Hui.update(url, x)
      Hui.update(url, "{\"commit\":{}}")

      verify_docs_exist(:default, ["tt0083658"])
    end

    test "should post a single doc with commitWithin and overwrite parameters" do
      default_url = Hui.URL.default_url!()

      url = %Hui.URL{
        default_url
        | handler: "update",
          headers: [{"Content-type", "application/json"}]
      }

      delete_verify_doc_deletion(
        url,
        %Query.Update{delete_id: "tt0078748", commit: true},
        "tt0078748"
      )

      update_doc = File.read!("./test/data/update_doc5.json") |> Poison.decode!()
      doc_map = update_doc["add"]["doc"]
      commitWithin = update_doc["add"]["commitWithin"]
      overwrite = update_doc["add"]["overwrite"]
      x = %Query.Update{doc: doc_map, commitWithin: commitWithin, overwrite: overwrite}

      Hui.update(url, x)
      :timer.sleep(300)

      verify_docs_exist(:default, ["tt0078748"])
    end

    test "should post multiple docs" do
      default_url = Hui.URL.default_url!()

      url = %Hui.URL{
        default_url
        | handler: "update",
          headers: [{"Content-type", "application/json"}]
      }

      delete_verify_doc_deletion(
        url,
        %Query.Update{delete_id: ["tt1316540", "tt1650453"], commit: true},
        ["tt1316540", "tt1650453"]
      )

      doc_map1 = %{
        "actor_ss" => ["János Derzsi", "Erika Bók", "Mihály Kormos", "Ricsi"],
        "desc" => "A rural farmer is forced to confront the mortality of his faithful horse.",
        "directed_by" => ["Béla Tarr", "Ágnes Hranitzky"],
        "genre" => ["Drama"],
        "id" => "tt1316540",
        "initial_release_date" => "2011-03-31",
        "name" => "The Turin Horse"
      }

      doc_map2 = %{
        "actor_ss" => ["Masami Nagasawa", "Hiroshi Abe", "Kanna Hashimoto", "Yoshio Harada"],
        "desc" =>
          "Twelve-year-old Koichi, who has been separated from his brother Ryunosuke due to his parents' divorce, hears a rumor that the new bullet trains will precipitate a wish-granting miracle when they pass each other at top speed.",
        "directed_by" => ["Hirokazu Koreeda"],
        "genre" => ["Drama"],
        "id" => "tt1650453",
        "initial_release_date" => "2011-06-11",
        "name" => "I Wish"
      }

      x = %Query.Update{doc: [doc_map1, doc_map2]}

      Hui.update(url, x)
      Hui.update(url, "{\"commit\":{}}")

      verify_docs_exist(:default, ["tt1316540", "tt1650453"])
    end

    test "should post multiple docs with commitWithin and overwrite parameters" do
      default_url = Hui.URL.default_url!()

      url = %Hui.URL{
        default_url
        | handler: "update",
          headers: [{"Content-type", "application/json"}]
      }

      delete_verify_doc_deletion(
        url,
        %Query.Update{delete_id: ["tt0077711", "tt0060827"], commit: true},
        ["tt0077711", "tt0060827"]
      )

      doc_map1 = %{
        "actor_ss" => ["Ingrid Bergman", "Liv Ullmann", "Lena Nyman", "Halvar Björk"],
        "desc" =>
          "A married daughter who longs for her mother's love is visited by the latter, a successful concert pianist.",
        "directed_by" => ["Ingmar Bergman"],
        "genre" => ["Drama", "Music"],
        "id" => "tt0077711",
        "initial_release_date" => "1978-10-08",
        "name" => "Autumn Sonata"
      }

      doc_map2 = %{
        "actor_ss" => ["Bibi Andersson", "Liv Ullmann", "Margaretha Krook"],
        "desc" =>
          "A nurse is put in charge of a mute actress and finds that their personas are melding together.",
        "directed_by" => ["Ingmar Bergman"],
        "genre" => ["Drama", "Thriller"],
        "id" => "tt0060827",
        "initial_release_date" => "1967-09-21",
        "name" => "Persona"
      }

      x = %Query.Update{doc: [doc_map1, doc_map2], commitWithin: 50, overwrite: true}

      Hui.update(url, x)
      :timer.sleep(300)

      verify_docs_exist(:default, ["tt0077711", "tt0060827"])
    end
  end
end
