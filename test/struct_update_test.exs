defmodule HuiStructUpdateTest do
  use ExUnit.Case, async: true
  import TestHelpers

  alias Hui.Query

  # testing with Bypass
  setup do
    bypass = Bypass.open()
    error_einval = %Hui.Error{reason: :einval}
    error_nxdomain = %Hui.Error{reason: :nxdomain}

    {:ok, bypass: bypass}
  end

  describe "update via Query.Update" do
    test "docs with commitWithin, overwrite", context do
      url = %Hui.URL{
        url: "http://localhost:#{context.bypass.port}",
        handler: "update",
        headers: [{"Content-type", "application/json"}]
      }

      expected_data = File.read!("./test/data/update_doc5.json")
      update_doc = expected_data |> Poison.decode!()
      doc_map = update_doc["add"]["doc"]
      commitWithin = update_doc["add"]["commitWithin"]
      overwrite = update_doc["add"]["overwrite"]

      x = %Query.Update{doc: doc_map, commitWithin: commitWithin, overwrite: overwrite}
      setup_bypass_for_post_req(context.bypass, expected_data)
      test_update_req(url, x)
    end

    test "delete by ID", context do
      url = %Hui.URL{
        url: "http://localhost:#{context.bypass.port}",
        handler: "update",
        headers: [{"Content-type", "application/json"}]
      }

      expected_data = File.read!("./test/data/delete_doc3.json")
      setup_bypass_for_post_req(context.bypass, expected_data)

      x = %Query.Update{delete_id: ["tt1316540", "tt1650453"]}
      test_update_req(url, x)
    end

    test "delete by query", context do
      url = %Hui.URL{
        url: "http://localhost:#{context.bypass.port}",
        handler: "update",
        headers: [{"Content-type", "application/json"}]
      }

      expected_data =
        "{\"delete\":{\"query\":\"name:Persona\"},\"delete\":{\"query\":\"genre:Drama\"}}"

      x = %Query.Update{delete_query: ["name:Persona", "genre:Drama"]}
      setup_bypass_for_post_req(context.bypass, expected_data)
      test_update_req(url, x)
    end

    test "rollback", context do
      url = %Hui.URL{
        url: "http://localhost:#{context.bypass.port}",
        handler: "update",
        headers: [{"Content-type", "application/json"}]
      }

      expected_data = "{\"delete\":{\"query\":\"name:Persona\"},\"rollback\":{}}"

      x = %Query.Update{delete_query: "name:Persona", rollback: true}
      setup_bypass_for_post_req(context.bypass, expected_data)
      test_update_req(url, x)
    end

    test "multiple grouped update commands", context do
      url = %Hui.URL{
        url: "http://localhost:#{context.bypass.port}",
        handler: "update",
        headers: [{"Content-type", "application/json"}]
      }

      expected_data = File.read!("./test/data/update_doc9.json")

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
      x = %Query.Update{x | commit: true, waitSearcher: true, expungeDeletes: false}

      setup_bypass_for_post_req(context.bypass, expected_data)
      test_update_req(url, x)
    end
  end
end
