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
      ClientMock |> expect(:dispatch, fn req -> {:ok, %{req | status: 200}} end)

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

  test "post/3" do
    docs = multi_docs()
    docs_encoded = docs |> Jason.encode!()

    ClientMock |> expect(:dispatch, fn %Http{body: ^docs_encoded} = req -> {:ok, req} end)
    ClientMock |> expect(:handle_response, fn {:ok, %Http{} = resp}, _req -> {:ok, resp} end)

    assert {:ok, %Http{}} = Http.post("http://solr_endpoint", docs_encoded)
  end
end
