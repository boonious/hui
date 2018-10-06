defmodule HuiStructUpdateTest do
  use ExUnit.Case, async: true
  import TestHelpers

  # testing with Bypass
  setup do
    update_doc = File.read!("./test/data/update_doc2.json") 
    bypass = Bypass.open
    error_einval = %Hui.Error{reason: :einval}
    error_nxdomain = %Hui.Error{reason: :nxdomain}
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
      "actor_ss" => ["Masami Nagasawa", "Hiroshi Abe", "Kanna Hashimoto",
       "Yoshio Harada"],
      "desc" => "Twelve-year-old Koichi, who has been separated from his brother Ryunosuke due to his parents' divorce, hears a rumor that the new bullet trains will precipitate a wish-granting miracle when they pass each other at top speed.",
      "directed_by" => ["Hirokazu Koreeda"],
      "genre" => ["Drame"],
      "id" => "tt1650453",
      "initial_release_date" => "2011-06-11",
      "name" => "I Wish"
    }
    {:ok, bypass: bypass, multi_docs: [doc_map1, doc_map2], update_doc: update_doc, error_einval: error_einval, error_nxdomain: error_nxdomain}
  end

  describe "structured update via Hui.U" do

    test "update should post a single doc to a URL (struct)", context do
      url = %Hui.URL{url: "http://localhost:#{context.bypass.port}", handler: "update", headers: [{"Content-type", "application/json"}]}
      update_doc =  context.update_doc |> Poison.decode!
      expected_data = update_doc |> Poison.encode!
      doc_map = update_doc["add"]["doc"]
      check_post_data_bypass_setup(context.bypass, expected_data)

      x = %Hui.U{doc: doc_map}
      Hui.Request.update(url, x)
    end

    test "update should post multiple docs to a URL (struct)", context do
      url = %Hui.URL{url: "http://localhost:#{context.bypass.port}", handler: "update", headers: [{"Content-type", "application/json"}]}
      expected_data = File.read!("./test/data/update_doc3.json")
      check_post_data_bypass_setup(context.bypass, expected_data)

      x = %Hui.U{doc: context.multi_docs}
      Hui.Request.update(url, x)
    end

    test "update should post multiple docs to a URL key", context do
      bypass = Bypass.open(port: 9000)
      expected_data = File.read!("./test/data/update_doc3.json")
      check_post_data_bypass_setup(bypass, expected_data)

      x = %Hui.U{doc: context.multi_docs}
      Hui.Request.update(:update_struct_test, x)
    end

    test "update should post doc with commitWithin and overwrite parameters", context do
      url = %Hui.URL{url: "http://localhost:#{context.bypass.port}", handler: "update", headers: [{"Content-type", "application/json"}]}
      expected_data =  File.read!("./test/data/update_doc5.json")

      update_doc = expected_data |> Poison.decode!
      doc_map = update_doc["add"]["doc"]
      commitWithin = update_doc["add"]["commitWithin"]
      overwrite = update_doc["add"]["overwrite"]

      check_post_data_bypass_setup(context.bypass, expected_data)

      x = %Hui.U{doc: doc_map, commitWithin: commitWithin, overwrite: overwrite}
      Hui.Request.update(url, x)
    end

    test "update should post multiple bundled update commands", context do
      url = %Hui.URL{url: "http://localhost:#{context.bypass.port}", handler: "update", headers: [{"Content-type", "application/json"}]}
      expected_data =  File.read!("./test/data/update_doc9.json")
      check_post_data_bypass_setup(context.bypass, expected_data)

      doc_map1 = %{
        "actor_ss" => ["Ingrid Bergman", "Liv Ullmann", "Lena Nyman", "Halvar Björk"],
        "desc" => "A married daughter who longs for her mother's love is visited by the latter, a successful concert pianist.",
        "directed_by" => ["Ingmar Bergman"],
        "genre" => ["Drama", "Music"],
        "id" => "tt0077711",
        "initial_release_date" => "1978-10-08",
        "name" => "Autumn Sonata"
      }
      doc_map2 = %{
        "actor_ss" => ["Bibi Andersson", "Liv Ullmann", "Margaretha Krook"],
        "desc" => "A nurse is put in charge of a mute actress and finds that their personas are melding together.",
        "directed_by" => ["Ingmar Bergman"],
        "genre" => ["Drama", "Thriller"],
        "id" => "tt0060827",
        "initial_release_date" => "1967-09-21",
        "name" => "Persona"
      }

      x = %Hui.U{doc: [doc_map1, doc_map2], commitWithin: 50, overwrite: true}
      x = %Hui.U{x | commit: true, waitSearcher: true, expungeDeletes: false}
      Hui.Request.update(url, x)
    end

  end

end