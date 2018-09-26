defmodule HuiSearchBangTest do
  use ExUnit.Case, async: true
  import TestHelpers

  doctest Hui

  # testing with Bypass
  setup do
    resp = File.read!("./test/data/simple_search_response.json")
    resp_xml = File.read!("./test/data/simple_search_response.xml")
    bypass = Bypass.open
    error_einval = %Hui.Error{reason: :einval}
    error_nxdomain = %Hui.Error{reason: :nxdomain}
    {:ok, bypass: bypass, simple_search_response_sample: resp, simple_search_response_sample_xml: resp_xml,
    error_einval: error_einval, error_nxdomain: error_nxdomain}
  end

  describe "http client" do

  end

  describe "search (bang)" do
    # tests for Hui.Request.search/3 (bang = true)

    test "should perform keywords query", context do
      Bypass.expect context.bypass, fn conn ->
        Plug.Conn.resp(conn, 200, "")
      end
      assert check_search_req_url!("http://localhost:#{context.bypass.port}", [q: "*"], ~r/q=*/)
    end

    test "should query with other Solr parameters", context do
      Bypass.expect context.bypass, fn conn ->
        Plug.Conn.resp(conn, 200, context.simple_search_response_sample)
      end

      solr_params = [q: "*", rows: 10, fq: ["cat:electronics", "popularity:[0 TO *]"] ]
      assert check_search_req_url!("http://localhost:#{context.bypass.port}", solr_params, ~r/q=%2A&rows=10&fq=cat%3Aelectronics&fq=popularity%3A%5B0\+TO\+%2A%5D/)

      #{_status, resp} = Hui.search!("http://localhost:#{context.bypass.port}", solr_params)
      #assert length(resp.body["response"]["docs"]) > 0
    end

    test "should work with %Hui.URL{}", context do
      Bypass.expect context.bypass, fn conn ->
        Plug.Conn.resp(conn, 200, "")
      end

      solr_params = [suggest: true, "suggest.dictionary": "mySuggester", "suggest.q": "el"]
      url = %Hui.URL{url: "http://localhost:#{context.bypass.port}/solr/newspapers", handler: "suggest"}
      experted_request_url = Hui.URL.encode_query(solr_params)

      assert check_search_req_url!(url, solr_params, ~r/#{experted_request_url}/)
    end

    test "should facilitate HTTP headers setting via %Hui.URL{}", context do
      test_header = {"accept", "application/json"}
      Bypass.expect context.bypass, fn conn ->
         assert Enum.member?(conn.req_headers, test_header)
         Plug.Conn.resp(conn, 200, "")
      end
      url = %Hui.URL{url: "http://localhost:#{context.bypass.port}", headers: [test_header]}
      bang = true
      Hui.Request.search(url, bang, q: "*")
      #Hui.search!(url, q: "*")
    end

    test "should facilitate HTTPoison options setting via %Hui.URL{}", context do
      # test with the HTTPoison "timeout" option, "0" setting mimicking a request timeout
      url = %Hui.URL{url: "http://localhost:#{context.bypass.port}/", options: [timeout: 0]}
      assert {:error, %Hui.Error{reason: :checkout_timeout}} = Hui.search(url, q: "*")
      assert {:error, %Hui.Error{reason: :checkout_timeout}} = Hui.Request.search(url, q: "*")

      # test with the low-level HTTPoison "params" option, for appending additional query string params
      Bypass.expect context.bypass, fn conn -> Plug.Conn.resp(conn, 200, "") end
      url = %Hui.URL{url: "http://localhost:#{context.bypass.port}/", options: [params: [test: "from_test"]]}
      
      assert check_search_req_url!(url, [q: "*"], ~r/test=from_test/)
    end

    test "should work with configured URL via a config key" do
      bypass = Bypass.open(port: 8984)
      Bypass.expect bypass, fn conn ->
        Plug.Conn.resp(conn, 200, "")
      end

      solr_params = [q: "edinburgh", rows: 10]
      bang = true
      {_, url} = Hui.URL.configured_url(:library)
      resp = Hui.Request.search(:library, bang, solr_params)
      experted_request_url = Hui.URL.to_string(url) <> "?" <> Hui.URL.encode_query(solr_params)
      assert experted_request_url == resp.request_url
    end

    test "should decode and return raw JSON Solr response as Map", context do
      Bypass.expect context.bypass, fn conn ->
        Plug.Conn.resp(conn, 200, context.simple_search_response_sample)
      end

      bang = true
      resp = Hui.Request.search("http://localhost:#{context.bypass.port}", bang, q: "test")
      assert is_map(resp.body)
    end

    test "should not decode and just return raw XML Solr response as text", context do
      Bypass.expect context.bypass, fn conn ->
        Plug.Conn.resp(conn, 200, context.simple_search_response_sample_xml)
      end

      bang = true
      resp = Hui.Request.search("http://localhost:#{context.bypass.port}", bang, q: "*")
      refute is_map(resp.body)
      assert is_binary(resp.body)
    end

    test "should handle malformed queries" do
      bang = true
      #assert {:error, context.error_einval} == Hui.q!(nil)
      #assert {:error, context.error_einval} == Hui.search!(:default, nil)
      assert_raise Hui.Error, ":einval", fn -> Hui.Request.search(:default, bang, nil) end
      assert_raise Hui.Error, ":einval", fn -> Hui.Request.search(:default, bang, ["tes"]) end
    end

    test "should handle missing or malformed URL" do
      bang = true
      #assert {:error, context.error_einval} == Hui.search!(nil, nil)
      assert_raise Hui.Error, ":einval", fn -> Hui.Request.search(nil, bang, nil) end
      assert_raise Hui.Error, ":einval", fn -> Hui.Request.search("", bang, q: "*") end
      assert_raise Hui.Error, ":einval", fn -> Hui.Request.search([], bang, q: "*") end
      #assert {:ok, context.error_einval} == Hui.Request.search(nil, bang, nil)
      #assert {:ok, context.error_einval} == Hui.Request.search("", bang, q: "*")
      #assert {:ok, context.error_einval} == Hui.Request.search([], bang, q: "*")
    end

  end

end
