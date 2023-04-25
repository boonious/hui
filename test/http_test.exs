defmodule Hui.HttpTest do
  use ExUnit.Case, async: true

  import Fixtures.Update
  import Hui.Http
  import Mox

  alias Hui.Http
  alias Hui.Http.Client.Mock, as: ClientMock
  alias Hui.Query

  describe "get/3" do
    setup do
      ClientMock |> stub(:handle_response, fn resp, _req -> resp end)

      %{url: "http://localhost/solr/collection/select"}
    end

    test "via binary endpoint", %{url: url} do
      ClientMock
      |> expect(:dispatch, fn req ->
        assert url in req.url
        {:ok, %{req | status: 200}}
      end)

      {:ok, resp} = get(url, q: "solr rocks")
      assert resp.status == 200
    end

    test "via configured atomic endpoint", %{url: url} do
      Application.put_env(:hui, :test_get_endpoint, url: url, headers: [{"accept", "application/json"}])

      ClientMock |> expect(:dispatch, fn req -> {:ok, %{req | status: 200}} end)

      {:ok, resp} = get(:test_get_endpoint, q: "solr rocks")

      assert resp.status == 200
      assert resp.method == :get
      assert {"accept", "application/json"} in resp.headers
    end

    test "accepts HTTP headers", %{url: url} do
      header = {"accept", "application/json"}

      ClientMock
      |> expect(:dispatch, fn %Http{} = req ->
        assert header in req.headers
        {:ok, req}
      end)

      {:ok, _resp} = get({url, [header]}, q: "*")
    end

    # test returns raw response

    test "returns parsed JSON response" do
      resp = File.read!("./test/fixtures/search_response.json")
      resp_decoded = resp |> Jason.decode!()

      ClientMock |> expect(:dispatch, fn %Http{} = req -> {:ok, %{req | body: resp}} end)

      ClientMock
      |> expect(:handle_response, fn {:ok, %Http{body: ^resp} = resp}, _req ->
        {:ok, %{resp | body: resp_decoded}}
      end)

      assert {:ok, %Http{body: ^resp_decoded}} = get("http://solr_endpoint", q: "get test")
    end

    test "handles keyword list query", %{url: url} do
      query = [q: "*", rows: 10, fq: ["cat:electronic", "popularity:[0 TO *]"]]
      query_encoded = Hui.Encoder.encode(query)

      ClientMock
      |> expect(:dispatch, fn %Http{} = req ->
        assert [^url, "?", ^query_encoded] = req.url
        {:ok, req}
      end)

      assert {:ok, _resp} = get(url, query)
    end

    test "handles a query struct", %{url: url} do
      query = %Query.DisMax{
        q: "run",
        qf: "description^2.3 title",
        mm: "2<-25% 9<-3",
        pf: "title",
        ps: 1,
        qs: 3
      }

      query_encoded = Hui.Encoder.encode(query)

      ClientMock
      |> expect(:dispatch, fn %Http{} = req ->
        assert [^url, "?", ^query_encoded] = req.url
        {:ok, req}
      end)

      assert {:ok, _resp} = get(url, query)
    end

    test "handles a list of query structs", %{url: url} do
      struct1 = %Hui.Query.DisMax{
        q: "run",
        qf: "description^2.3 title",
        mm: "2<-25% 9<-3",
        pf: "title",
        ps: 1,
        qs: 3
      }

      struct2 = %Hui.Query.Common{rows: 10, start: 10, fq: ["edited:true"]}
      struct3 = %Hui.Query.Facet{field: ["cat", "author_str"], mincount: 1}

      query_encoded = [struct1, struct2, struct3] |> Hui.Encoder.encode()

      ClientMock
      |> expect(:dispatch, fn %Http{} = req ->
        assert [^url, "?", ^query_encoded] = req.url
        {:ok, req}
      end)

      get(url, [struct1, struct2, struct3])
    end

    # test "calls configured response parser", %{url: url}
    # test "calls global response parser", %{url: url}
  end

  describe "post/4" do
    setup do
      ClientMock |> stub(:handle_response, fn resp, _req -> resp end)
      update_json = update_json(single_doc(), commit: true)

      %{url: "http://localhost/solr/collection/select", updates: update_json}
    end

    test "via binary endpoint", %{url: url, updates: updates} do
      ClientMock |> expect(:dispatch, fn %{url: ^url} = req -> {:ok, %{req | status: 200}} end)

      {:ok, resp} = post(url, updates)
      assert resp.status == 200
    end

    test "via configured atomic endpoint", %{url: url, updates: updates} do
      Application.put_env(:hui, :test_post_endpoint, url: url, headers: [{"accept", "application/json"}])
      ClientMock |> expect(:dispatch, fn %{url: ^url} = req -> {:ok, %{req | status: 200}} end)

      {:ok, resp} = post(:test_post_endpoint, updates)

      assert resp.status == 200
      assert resp.method == :post
      assert {"accept", "application/json"} in resp.headers
    end

    test "handles binary update data", %{url: url} do
      url = {url, [{"content-type", "application/xml"}]}
      updates = "<delete><id>9780141981727</id></delete>"

      ClientMock |> expect(:dispatch, fn %Http{body: ^updates} = req -> {:ok, %{req | status: 200}} end)

      {:ok, _resp} = post(url, updates)
    end

    test "handles update struct", %{url: url} do
      updates = %Query.Update{doc: single_doc(), commit: true}
      updates_encoded = updates |> Hui.Encoder.encode()
      ClientMock |> expect(:dispatch, fn %Http{body: ^updates_encoded} = req -> {:ok, %{req | status: 200}} end)

      {:ok, _resp} = post(url, updates)
    end

    test "handles single map default update", %{url: url} do
      doc = single_doc()
      updates_encoded = update_json(doc, commit: true)
      ClientMock |> expect(:dispatch, fn %Http{body: ^updates_encoded} = req -> {:ok, %{req | status: 200}} end)

      {:ok, _resp} = post(url, doc)
    end

    test "handles single map update with commit false", %{url: url} do
      doc = single_doc()
      commit = false
      updates_encoded = update_json(doc, commit: false)
      ClientMock |> expect(:dispatch, fn %Http{body: ^updates_encoded} = req -> {:ok, %{req | status: 200}} end)

      {:ok, _resp} = post(url, doc, commit)
    end

    test "handles list of maps default update", %{url: url} do
      docs = multi_docs()
      updates_encoded = update_json(docs, commit: true)
      ClientMock |> expect(:dispatch, fn %Http{body: ^updates_encoded} = req -> {:ok, %{req | status: 200}} end)

      {:ok, _resp} = post(url, docs)
    end

    test "handles list of maps update with commit false", %{url: url} do
      docs = multi_docs()
      commit = false
      updates_encoded = update_json(docs, commit: false)
      ClientMock |> expect(:dispatch, fn %Http{body: ^updates_encoded} = req -> {:ok, %{req | status: 200}} end)

      {:ok, _resp} = post(url, docs, commit)
    end
  end
end
