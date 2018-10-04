defmodule HuiStructUpdateLiveTest do
  use ExUnit.Case, async: true

  describe "Hui.U struct update (live)" do
    @describetag live: false

    test "should post binary data" do
     default_url = Hui.URL.default_url!
       url = %Hui.URL{default_url | handler: "update", headers: [{"Content-type", "application/json"}]}
       # change the following update calls from binary to struct-based later with 'delete', 'commit' op exist
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

  end


end