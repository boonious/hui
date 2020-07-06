defmodule HuiUpdateTest do
  use ExUnit.Case, async: true
  import TestHelpers

  alias Hui.Query
  alias Hui.Encoder

  # testing with Bypass
  setup do
    update_doc = File.read!("./test/data/update_doc1.json")
    bypass = Bypass.open()
    error_einval = %Hui.Error{reason: :einval}
    error_nxdomain = %Hui.Error{reason: :nxdomain}

    {:ok, bypass: bypass, update_doc: update_doc, error_einval: error_einval, error_nxdomain: error_nxdomain}
  end

  describe "update" do
    test "a single doc (Map)", context do
      url = %Hui.URL{
        url: "http://localhost:#{context.bypass.port}",
        handler: "update",
        headers: [{"Content-type", "application/json"}]
      }

      expected = File.read!("./test/data/update_doc2c.json")
      update_doc = expected |> Poison.decode!()
      doc_map = update_doc["add"]["doc"]

      setup_bypass_for_post_req(context.bypass, expected)
      test_update_req(url, doc_map)
    end

    test "a single doc without commit (Map)", context do
      url = %Hui.URL{
        url: "http://localhost:#{context.bypass.port}",
        handler: "update",
        headers: [{"Content-type", "application/json"}]
      }

      doc_map = %{
        "actor_ss" => ["János Derzsi", "Erika Bók", "Mihály Kormos", "Ricsi"],
        "desc" => "A rural farmer is forced to confront the mortality of his faithful horse.",
        "directed_by" => ["Béla Tarr", "Ágnes Hranitzky"],
        "genre" => ["Drama"],
        "id" => "tt1316540",
        "initial_release_date" => "2011-03-31",
        "name" => "The Turin Horse"
      }

      expected = %Query.Update{doc: doc_map} |> Encoder.encode()
      setup_bypass_for_post_req(context.bypass, expected)
      test_update_req(url, doc_map, false)
    end

    test "post multiple docs (Map)", context do
      url = %Hui.URL{
        url: "http://localhost:#{context.bypass.port}",
        handler: "update",
        headers: [{"Content-type", "application/json"}]
      }

      setup_bypass_for_post_req(context.bypass, File.read!("./test/data/update_doc3c.json"))

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
        "genre" => ["Drame"],
        "id" => "tt1650453",
        "initial_release_date" => "2011-06-11",
        "name" => "I Wish"
      }

      test_update_req(url, [doc_map1, doc_map2])
    end

    test "post multiple docs without commit (Map)", context do
      url = %Hui.URL{
        url: "http://localhost:#{context.bypass.port}",
        handler: "update",
        headers: [{"Content-type", "application/json"}]
      }

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
        "genre" => ["Drame"],
        "id" => "tt1650453",
        "initial_release_date" => "2011-06-11",
        "name" => "I Wish"
      }

      expected = %Query.Update{doc: [doc_map1, doc_map2]} |> Encoder.encode()
      setup_bypass_for_post_req(context.bypass, expected)
      test_update_req(url, [doc_map1, doc_map2], false)
    end

    test "post binary data", context do
      setup_bypass_for_post_req(context.bypass, context.update_doc)

      url = %Hui.URL{
        url: "http://localhost:#{context.bypass.port}",
        handler: "update",
        headers: [{"Content-type", "application/json"}]
      }

      test_update_req(url, context.update_doc)
    end

    test "work with a configured URL key" do
      update_doc = File.read!("./test/data/update_doc2.xml")
      bypass = Bypass.open(port: 8989)

      setup_bypass_for_post_req(bypass, update_doc, "application/xml")
      test_update_req(:update_test, update_doc)
    end
  end

  describe "update - other" do
    test "delete docs by ID", context do
      url = %Hui.URL{
        url: "http://localhost:#{context.bypass.port}",
        handler: "update",
        headers: [{"Content-type", "application/json"}]
      }

      query = %Query.Update{delete_id: ["tt1650453", "tt1650453"], commit: true}
      expected = query |> Encoder.encode()
      setup_bypass_for_post_req(context.bypass, expected)

      Hui.delete(url, ["tt1650453", "tt1650453"])
    end

    test "delete docs by query", context do
      url = %Hui.URL{
        url: "http://localhost:#{context.bypass.port}",
        handler: "update",
        headers: [{"Content-type", "application/json"}]
      }

      query = %Query.Update{delete_query: ["name:Persona", "genre:Drama"], commit: true}
      expected = query |> Encoder.encode()
      setup_bypass_for_post_req(context.bypass, expected)

      Hui.delete_by_query(url, ["name:Persona", "genre:Drama"])
    end

    test "commit docs", context do
      url = %Hui.URL{
        url: "http://localhost:#{context.bypass.port}",
        handler: "update",
        headers: [{"Content-type", "application/json"}]
      }

      expected = %Query.Update{commit: true, waitSearcher: true} |> Encoder.encode()
      setup_bypass_for_post_req(context.bypass, expected)

      Hui.commit(url)
    end

    test "handle missing or malformed URL", context do
      assert {:error, context.error_nxdomain} == Hui.update(nil, context.update_doc)
      assert {:error, context.error_nxdomain} == Hui.update("", context.update_doc)
      assert {:error, context.error_nxdomain} == Hui.update([], context.update_doc)
      assert {:error, context.error_nxdomain} == Hui.update(:blahblah, context.update_doc)
      assert {:error, context.error_nxdomain} == Hui.update(%Hui.URL{url: "boo"}, "")
    end
  end
end
