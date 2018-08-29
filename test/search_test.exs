defmodule HuiSearchTest do
  use ExUnit.Case, async: true
  doctest Hui

  setup do
    resp = File.read!("./test/data/simple_search_response.json")
    bypass = Bypass.open
    {:ok, bypass: bypass, simple_search_response_sample: resp}
  end

  describe "http client" do
    # malformed Solr endpoints, unable cores or bad query params (404, 400 etc.)
    test "handling errors", context do
      Bypass.expect context.bypass, fn conn ->
        Plug.Conn.resp(conn, 404, "")
      end
      {_, resp} = Hui.Search.search("http://localhost:#{context.bypass.port}","http test")
      assert 404 = resp.status_code
    end

    test "handling unreachable host or offline server", context do
      Bypass.down(context.bypass)
      assert {:error, %HTTPoison.Error{id: nil, reason: :econnrefused}} = Hui.Search.search("http://localhost:#{context.bypass.port}", "http test")
    end

  end

  describe "simple" do

    test "keywords search", context do
      Bypass.expect context.bypass, fn conn ->
        Plug.Conn.resp(conn, 200, context.simple_search_response_sample)
      end
      {_status, resp} = Hui.Search.search("http://localhost:#{context.bypass.port}", "*")
      resp_h = resp.body |> Poison.decode!
      assert length(resp_h["response"]["docs"]) > 0
      assert String.match?(resp.request_url, ~r/q=*/)
    end

  end

end
