defmodule Hui.SuggestTest do
  use ExUnit.Case, async: true

  import Mox
  import Hui.Suggest

  alias Hui.Http.Client.Mock, as: ClientMock
  alias Hui.Query

  describe "suggest/2" do
    test "request query string" do
      url = "http://localhost/suggest"
      suggest_struct = %Query.Suggest{q: "ha", count: 10, dictionary: "name_infix"}

      ClientMock |> expect(:dispatch, fn req -> {:ok, %{req | status: 200}} end)
      ClientMock |> expect(:handle_response, fn resp, _req -> resp end)

      {:ok, resp} = suggest(url, suggest_struct)

      assert [^url, "?", query_string] = resp.url
      assert query_string == Hui.Encoder.encode(suggest_struct)
    end

    test "returns parsed JSON response" do
      url = "http://localhost/suggest"
      suggest_resp = File.read!("./test/fixtures/search_response.json")

      ClientMock |> expect(:dispatch, fn req -> {:ok, %{req | body: suggest_resp}} end)

      ClientMock
      |> expect(:handle_response, fn {:ok, %{body: ^suggest_resp} = resp}, _req ->
        {:ok, %{resp | body: suggest_resp |> Jason.decode!()}}
      end)

      assert {:ok, resp} = suggest(url, %Query.Suggest{q: "ha", count: 10, dictionary: "name_infix"})
      assert resp.body == suggest_resp |> Jason.decode!()
    end
  end

  test "suggest/5" do
    url = "http://localhost/suggest"

    q = "ha"
    count = 10
    dictionaries = ["name_infix", "ln_prefix", "fn_prefix"]
    context = "1939"

    query = %Query.Suggest{q: q, count: count, dictionary: dictionaries, cfq: context}
    query_string = Hui.Encoder.encode(query)

    ClientMock
    |> expect(:dispatch, fn req ->
      assert [url, "?", query_string] == req.url
      {:ok, %{req | status: 200}}
    end)

    ClientMock |> expect(:handle_response, fn resp, _req -> resp end)

    suggest(url, q, count, dictionaries, context)
  end
end
