defmodule HuiUpdateLiveTest do
  use ExUnit.Case, async: true
  import TestHelpers

  describe "Request.update (live)" do
    @describetag live: false

    test "should post binary data" do
      url = %Hui.URL{url: "http://localhost:8983/solr/gettingstarted", handler: "update", headers: [{"Content-type", "application/json"}]}
      commit_doc = File.read!("./test/data/commit.xml")
      update_doc = File.read!("./test/data/update_doc1.json")

      delete_verify_doc_deletion(url, File.read!("./test/data/delete_doc1.json"), "9780141981727")

      Hui.Request.update(url,update_doc)
      url = %Hui.URL{url | headers: [{"Content-type", "application/xml"}]}
      Hui.Request.update(url,commit_doc)

      verify_docs_exist(:default, ["9780141981727"])
    end

  end

  describe "Request.update (live / bang)" do
    @describetag live: false

    test "should post binary data" do
      url = %Hui.URL{url: "http://localhost:8983/solr/gettingstarted", handler: "update", headers: [{"Content-type", "application/xml"}]}
      delete_doc = File.read!("./test/data/delete_doc2.xml")
      commit_doc = File.read!("./test/data/commit.xml")
      update_doc = File.read!("./test/data/update_doc2.xml")

      bang = true
      Hui.Request.update(url, bang, delete_doc)
      Hui.Request.update(url, bang, commit_doc)
      resp = Hui.search!(:default, q: "*", fq: ["id:9781910701874"])
      assert resp.body["response"]["numFound"] == 0

      Hui.Request.update(url, bang, update_doc)
      Hui.Request.update(url, bang, commit_doc)

      verify_docs_exist(:default, ["9781910701874"])
    end

  end

end