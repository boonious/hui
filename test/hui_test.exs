defmodule HuiTest do
  use ExUnit.Case, async: true
  use Hammox.Protect, module: Hui.ResponseParsers.JsonParser, behaviour: Hui.ResponseParsers.Parser

  import Mox
  import TestHelpers
  import Fixtures.Admin
  import Fixtures.Update

  alias Hui.Query
  alias Hui.ResponseParsers.JsonParser.Mock, as: JsonParserMock

  @client Hui.Http.Client.impl()

  doctest Hui

  setup :verify_on_exit!

  setup do
    %{url: {"http://localhost/solr/endpoint", [{"content-type", "application/json"}]}}
  end

  test "search/3", %{url: url} do
    @client |> expect(:dispatch, fn req -> {:ok, %{req | status: 200}} end)
    @client |> expect(:handle_response, fn resp, _req -> resp end)

    assert {:ok, _resp} = Hui.search(url, [q: "solr rocks"], @client)
  end

  test "update/4", %{url: url} do
    docs = multi_docs()
    query = %Query.Update{doc: docs, commit: true} |> Hui.Encoder.encode()

    @client |> expect(:dispatch, fn %{body: ^query} = req -> {:ok, %{req | status: 200}} end)
    @client |> expect(:handle_response, fn resp, _req -> resp end)
    assert {:ok, _resp} = Hui.update(url, docs)

    commit = false
    query = %Query.Update{doc: docs, commit: false} |> Hui.Encoder.encode()
    @client |> expect(:dispatch, fn %{body: ^query} = req -> {:ok, %{req | status: 200}} end)
    @client |> expect(:handle_response, fn resp, _req -> resp end)
    assert {:ok, _resp} = Hui.update(url, docs, commit, @client)
  end

  test "delete docs via delete_by_id", %{url: url} do
    ids = ["tt1650453", "tt1650453"]
    commit = true
    query = %Query.Update{delete_id: ids, commit: true} |> Hui.Encoder.encode()

    @client |> expect(:dispatch, 2, fn %{body: ^query} = req -> {:ok, %{req | status: 200}} end)
    @client |> expect(:handle_response, 2, fn resp, _req -> resp end)

    assert {:ok, _resp} = Hui.delete_by_id(url, ids)
    assert {:ok, _resp} = Hui.delete_by_id(url, ids, commit, @client)
  end

  test "delete single doc via delete_by_id", %{url: url} do
    id = "tt1650453"
    commit = true
    query = %Query.Update{delete_id: id, commit: true} |> Hui.Encoder.encode()

    @client |> expect(:dispatch, 2, fn %{body: ^query} = req -> {:ok, %{req | status: 200}} end)
    @client |> expect(:handle_response, 2, fn resp, _req -> resp end)

    assert {:ok, _resp} = Hui.delete_by_id(url, id)
    assert {:ok, _resp} = Hui.delete_by_id(url, id, commit, @client)
  end

  test "delete_by_query/4", %{url: url} do
    filters = ["name:Persona", "genre:Drama"]
    query = %Query.Update{delete_query: filters, commit: true} |> Hui.Encoder.encode()

    @client |> expect(:dispatch, fn %{body: ^query} = req -> {:ok, %{req | status: 200}} end)
    @client |> expect(:handle_response, fn resp, _req -> resp end)
    Hui.delete_by_query(url, filters)

    commit = false
    query_without_commit = %Query.Update{delete_query: filters, commit: false} |> Hui.Encoder.encode()
    @client |> expect(:dispatch, fn %{body: ^query_without_commit} = req -> {:ok, %{req | status: 200}} end)
    @client |> expect(:handle_response, fn resp, _req -> resp end)
    Hui.delete_by_query(url, filters, commit, @client)
  end

  test "commit/3", %{url: url} do
    query = %Query.Update{commit: true, waitSearcher: true} |> Hui.Encoder.encode()

    @client |> expect(:dispatch, fn %{body: ^query} = req -> {:ok, %{req | status: 200}} end)
    @client |> expect(:handle_response, fn resp, _req -> resp end)
    Hui.commit(url)

    wait_searcher = false
    query_wait_searcher = %Query.Update{commit: true, waitSearcher: false} |> Hui.Encoder.encode()
    @client |> expect(:dispatch, fn %{body: ^query_wait_searcher} = req -> {:ok, %{req | status: 200}} end)
    @client |> expect(:handle_response, fn resp, _req -> resp end)
    Hui.commit(url, wait_searcher, @client)
  end

  test "suggest/2", %{url: url} do
    @client |> expect(:dispatch, 2, fn req -> {:ok, %{req | status: 200}} end)
    @client |> expect(:handle_response, 2, fn resp, _req -> resp end)

    assert {:ok, _resp} = Hui.suggest(url, %Query.Suggest{q: "ha", count: 10})
    assert {:ok, _resp} = Hui.suggest(url, "ha")
  end

  test "suggest/5", %{url: url} do
    @client |> expect(:dispatch, fn req -> {:ok, %{req | status: 200}} end)
    @client |> expect(:handle_response, fn resp, _req -> resp end)

    assert {:ok, _resp} = Hui.suggest(url, "ha", 10, ["ln_infix"], "1939")
  end

  test "metrics/2", %{url: url} do
    @client |> expect(:dispatch, fn req -> {:ok, %{req | status: 200}} end)
    @client |> expect(:handle_response, fn resp, _req -> resp end)

    assert {:ok, _resp} = Hui.metrics(url, group: "core", type: "timer")
  end

  test "ping/2", %{url: url} do
    ok_resp = successful_ping_json_response() |> Jason.decode!()

    @client |> expect(:dispatch, 2, fn req -> {:ok, %{req | status: 200}} end)
    @client |> expect(:handle_response, 2, fn {:ok, resp}, _req -> {:ok, %{resp | body: ok_resp}} end)

    assert {:pong, _qtime} = Hui.ping(url)
    assert {:pong, _qtime} = Hui.ping(url, wt: "json")
  end

  # Eventually move this to integration tests
  describe "get/2 handles" do
    setup do
      stub_with(JsonParserMock, Hui.ResponseParsers.JsonParser)
      %{bypass: Bypass.open()}
    end

    test "other highlighting structs", context do
      Bypass.expect(context.bypass, fn conn ->
        Plug.Conn.resp(conn, 200, "")
      end)

      url = "http://localhost:#{context.bypass.port}/select"

      x = %Query.Standard{q: "features:photo"}
      y = %Query.Highlight{fl: "features"}

      y1 = %Query.HighlighterUnified{
        offsetSource: "POSTINGS",
        defaultSummary: true,
        "score.k1": 0
      }

      y2 = %Query.HighlighterOriginal{
        mergeContiguous: true,
        "simple.pre": "<b>",
        "simple.post": "</b>",
        preserveMulti: true
      }

      y3 = %Query.HighlighterFastVector{
        boundaryScanner: "breakIterator",
        "bs.type": "WORD",
        "bs.language": "EN",
        "bs.country": "US"
      }

      test_get_req_url(url, [x, %{y | method: :unified}, y1])
      test_get_req_url(url, [x, %{y | method: :original}, y2])
      test_get_req_url(url, [x, %{y | method: :fastVector}, y3])
    end

    test "suggester struct", context do
      Bypass.expect_once(context.bypass, fn conn ->
        Plug.Conn.resp(conn, 200, "")
      end)

      url = "http://localhost:#{context.bypass.port}/suggester"
      x = %Query.Suggest{q: "ha", count: 10, dictionary: ["name_infix", "ln_prefix", "fn_prefix"]}

      test_get_req_url(url, x)
    end

    test "spellchecking struct", context do
      Bypass.expect_once(context.bypass, fn conn ->
        Plug.Conn.resp(conn, 200, "")
      end)

      url = "http://localhost:#{context.bypass.port}/spellcheck"

      x = %Query.SpellCheck{
        q: "delll ultra sharp",
        count: 10,
        "collateParam.q.op": "AND",
        dictionary: "default"
      }

      test_get_req_url(url, x)

      # {_status, resp} = Hui.spellcheck(url, solr_params)
      # assert String.match?(resp.request_url, ~r/#{experted_url}/)

      # solr_params_q = %Hui.Q{df: "text", wt: "xml"}
      # {_status, resp} = Hui.spellcheck(url, solr_params, solr_params_q)
      # assert String.match?(resp.request_url, ~r/df=text&wt=xml&#{experted_url}/)
    end

    test "more-like-this struct", context do
      Bypass.expect_once(context.bypass, fn conn ->
        Plug.Conn.resp(conn, 200, "")
      end)

      url = "http://localhost:#{context.bypass.port}/mlt"

      x = %Query.MoreLikeThis{
        fl: "manu,cat",
        mindf: 10,
        mintf: 200,
        "match.include": true,
        count: 10
      }

      y = %Query.Standard{q: "apache"}
      z = %Query.Common{rows: 5, wt: "xml"}

      test_get_req_url(url, [x, y, z])

      # {_status, resp} = Hui.mlt(url, solr_params_q, solr_params)
      # assert String.match?(resp.request_url, ~r/#{experted_url}/)
    end
  end
end
