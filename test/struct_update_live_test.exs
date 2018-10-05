defmodule HuiStructUpdateLiveTest do
  use ExUnit.Case, async: true
  import TestHelpers

  describe "structured update via Hui.U (live)" do
    @describetag live: false

    test "should post a single doc" do
      default_url = Hui.URL.default_url!
      url = %Hui.URL{default_url | handler: "update", headers: [{"Content-type", "application/json"}]}
      delete_verify_doc_deletion(url, File.read!("./test/data/delete_doc2.json"), "tt0083658")

      update_doc = File.read!("./test/data/update_doc2.json") |> Poison.decode!
      doc_map = update_doc["add"]["doc"]
      x = %Hui.U{doc: doc_map}

      Hui.Request.update(url, x)
      Hui.Request.update(url, File.read!("./test/data/commit.json"))

      verify_docs_exist(:default, ["tt0083658"])
    end

    test "should post a single doc with commitWithin and overwrite parameters" do
      default_url = Hui.URL.default_url!
      url = %Hui.URL{default_url | handler: "update", headers: [{"Content-type", "application/json"}]}
      delete_verify_doc_deletion(url, File.read!("./test/data/delete_doc4.json"), "tt0078748")

      update_doc = File.read!("./test/data/update_doc5.json") |> Poison.decode!
      doc_map = update_doc["add"]["doc"]
      commitWithin = update_doc["add"]["commitWithin"]
      overwrite = update_doc["add"]["overwrite"]
      x = %Hui.U{doc: doc_map, commitWithin: commitWithin, overwrite: overwrite}

      Hui.Request.update(url, x)
      :timer.sleep(100)
      
      verify_docs_exist(:default, ["tt0078748"])
    end

    test "should post multiple docs" do
      default_url = Hui.URL.default_url!
      url = %Hui.URL{default_url | handler: "update", headers: [{"Content-type", "application/json"}]}
      delete_verify_doc_deletion(url, File.read!("./test/data/delete_doc3.json"), ["tt1316540", "tt1650453"])

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
      x = %Hui.U{doc: [doc_map1, doc_map2]}

      Hui.Request.update(url, x)
      Hui.Request.update(url, File.read!("./test/data/commit.json"))

      verify_docs_exist(:default, ["tt1316540", "tt1650453"])
    end

  end


end