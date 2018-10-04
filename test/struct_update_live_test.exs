defmodule HuiStructUpdateLiveTest do
  use ExUnit.Case, async: true

  describe "Hui.U struct update (live)" do
    @describetag live: false

    test "should post a single doc" do
     default_url = Hui.URL.default_url!
       url = %Hui.URL{default_url | handler: "update", headers: [{"Content-type", "application/json"}]}
       # change the following update calls from binary to struct-based later when 'delete', 'commit' ops exist
       Hui.Request.update(url, File.read!("./test/data/delete_doc2.json"))
       Hui.Request.update(url, File.read!("./test/data/commit.json"))
       resp = Hui.search!(:default, q: "*", fq: ["id:tt0083658"])
       assert resp.body["response"]["numFound"] == 0

       update_doc = File.read!("./test/data/update_doc2.json") |> Poison.decode!
       doc_map = update_doc["add"]["doc"]
       x = %Hui.U{doc: doc_map}

       Hui.Request.update(url, x)
       Hui.Request.update(url, File.read!("./test/data/commit.json"))
       resp = Hui.search!(:default, q: "*", fq: ["id:tt0083658"])

       assert resp.body["response"]["numFound"] == 1
       doc = resp.body["response"]["docs"] |> hd
       assert doc["id"] == "tt0083658"
    end

    test "should post multiple docs" do
     default_url = Hui.URL.default_url!
       url = %Hui.URL{default_url | handler: "update", headers: [{"Content-type", "application/json"}]}
       # change the following update calls from binary to struct-based later with 'delete', 'commit' ops exist
       Hui.Request.update(url, File.read!("./test/data/delete_doc3.json"))
       Hui.Request.update(url, File.read!("./test/data/commit.json"))
       resp = Hui.search!(:default, q: "*", fq: ["id:(tt1316540 OR tt1650453)"])
       assert resp.body["response"]["numFound"] == 0

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
       resp = Hui.search!(:default, q: "*", fq: ["id:(tt1316540 OR tt1650453)"])
       assert resp.body["response"]["numFound"] == 2
       docs = resp.body["response"]["docs"] |> Enum.map(&(Map.get(&1, "id")))
       assert Enum.member? docs, "tt1316540"
       assert Enum.member? docs, "tt1650453"
    end

  end


end