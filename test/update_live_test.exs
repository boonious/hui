defmodule HuiUpdateLiveTest do
  use ExUnit.Case, async: true
  import TestHelpers

  describe "Request.update (live)" do
    @describetag live: false

    test "should post binary data" do
      url = %Hui.URL{url: "http://localhost:8983/solr/gettingstarted", handler: "update", headers: [{"Content-type", "application/json"}]}
      update_doc = File.read!("./test/data/update_doc1.json")

      delete_verify_doc_deletion(url, File.read!("./test/data/delete_doc1.json"), "9780141981727")

      Hui.Request.update(url,update_doc)
      url = %Hui.URL{url | headers: [{"Content-type", "application/xml"}]}
      Hui.Request.update(url,"<commit/>")

      verify_docs_exist(:default, ["9780141981727"])
    end

    test "should post binary data with commitWithin and overwrite" do
      url = %Hui.URL{url: "http://localhost:8983/solr/gettingstarted", handler: "update", headers: [{"Content-type", "application/json"}]}
      delete_verify_doc_deletion(url, "{\"delete\":\"tt0062622\"}", "tt0062622")

      Hui.Request.update(url, File.read!("./test/data/update_doc7.json"))
      :timer.sleep(100)

      verify_docs_exist(:default, ["tt0062622"])
    end

  end

  describe "Request.update (live / bang)" do
    @describetag live: false

    test "should post binary data" do
      url = %Hui.URL{url: "http://localhost:8983/solr/gettingstarted", handler: "update", headers: [{"Content-type", "application/xml"}]}

      bang = true
      Hui.Request.update(url, bang, File.read!("./test/data/delete_doc2.xml"))
      Hui.Request.update(url, bang, "<commit/>")
      resp = Hui.search!(:default, q: "*", fq: ["id:9781910701874"])
      assert resp.body["response"]["numFound"] == 0

      Hui.Request.update(url, bang, File.read!("./test/data/update_doc2.xml"))
      Hui.Request.update(url, bang, "<commit/>")

      verify_docs_exist(:default, ["9781910701874"])
    end

  end

end