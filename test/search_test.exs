defmodule HuiSearchTest do
  use ExUnit.Case, async: true
  doctest Hui
  doctest Hui.URL

  setup do
    resp = File.read!("./test/data/simple_search_response.json")
    bypass = Bypass.open
    {:ok, bypass: bypass, simple_search_response_sample: resp}
  end

  describe "http client" do

    # malformed Solr endpoints, unable cores or bad query params (404, 400 etc.)
    test "should handle errors", context do
      Bypass.expect context.bypass, fn conn ->
        Plug.Conn.resp(conn, 404, "")
      end
      {_, resp} = Hui.Search.search("http://localhost:#{context.bypass.port}", q: "http test")
      assert 404 = resp.status_code
    end

    test "should handle unreachable host or offline server", context do
      Bypass.down(context.bypass)
      assert {:error, %HTTPoison.Error{id: nil, reason: :econnrefused}} = Hui.Search.search("http://localhost:#{context.bypass.port}", "http test")
    end

  end

  describe "simple search" do
    # test for Hui.search(query)

    test "should perform keywords query", context do
      Bypass.expect context.bypass, fn conn ->
        Plug.Conn.resp(conn, 200, context.simple_search_response_sample)
      end
      {_status, resp} = Hui.Search.search("http://localhost:#{context.bypass.port}", q: "*")
      resp_h = resp.body |> Poison.decode!
      assert length(resp_h["response"]["docs"]) > 0
      assert String.match?(resp.request_url, ~r/q=*/)
    end

    test "should query with other Solr parameters", context do
      Bypass.expect context.bypass, fn conn ->
        Plug.Conn.resp(conn, 200, context.simple_search_response_sample)
      end

      solr_params = [q: "*", rows: 10, fq: ["cat:electronics", "popularity:[0 TO *]"] ]

      {_status, resp} = Hui.Search.search("http://localhost:#{context.bypass.port}", solr_params)
      resp_h = resp.body |> Poison.decode!
      assert length(resp_h["response"]["docs"]) > 0
      assert String.match?(resp.request_url, ~r/q=%2A&rows=10&fq=cat%3Aelectronics&fq=popularity%3A%5B0\+TO\+%2A%5D/)
    end

    test "should handle malformed and unsupported queries" do
      assert {:error, "unsupported or malformed query"} = Hui.search(nil)
    end

  end

  # tests using live Solr cores/collections that are
  # excluded by default, use '--include live' or
  # change tag value to true to run tests
  #
  # this required a configured working Solr core/collection
  # see: Configuration for further details
  describe "live SOLR API" do
    @describetag live: false

    test "should perform keywords query" do
      {_status, resp} = Hui.search("*")
      resp_h = resp.body |> Poison.decode!
      assert length(resp_h["response"]["docs"]) >= 0
      assert String.match?(resp.request_url, ~r/q=*/)
    end

    test "should query with other Solr parameters" do
      solr_params = [q: "*", rows: 10, facet: true, fl: "*"]
      {_status, resp} = Hui.search(solr_params)

      resp_h = resp.body |> Poison.decode!
      assert length(resp_h["response"]["docs"]) >= 0
      assert String.match?(resp.request_url, ~r/q=%2A&rows=10&facet=true&fl=%2A/)
    end

  end

end
