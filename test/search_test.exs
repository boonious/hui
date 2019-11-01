defmodule HuiSearchTest do
  use ExUnit.Case, async: true
  import TestHelpers

  doctest Hui

  # testing with Bypass
  setup do
    resp = File.read!("./test/data/simple_search_response.json")
    resp_xml = File.read!("./test/data/simple_search_response.xml")
    bypass = Bypass.open()

    error_einval = %Hui.Error{reason: :einval}
    error_nxdomain = %Hui.Error{reason: :nxdomain}

    {:ok,
     bypass: bypass,
     simple_search_response_sample: resp,
     simple_search_response_sample_xml: resp_xml,
     error_einval: error_einval,
     error_nxdomain: error_nxdomain}
  end

  describe "http client" do
    # malformed Solr endpoints, unable cores or bad query params (404, 400 etc.)
    test "handle errors", context do
      Bypass.expect(context.bypass, fn conn ->
        Plug.Conn.resp(conn, 404, "")
      end)

      {_, resp} = Hui.search("http://localhost:#{context.bypass.port}", q: "http test")
      assert 404 = resp.status_code
    end

    test "handle unreachable host or offline server", context do
      Bypass.down(context.bypass)

      assert {:error, %Hui.Error{reason: :econnrefused}} =
               Hui.search("http://localhost:#{context.bypass.port}", q: "http test")
    end

    test "raise error when host unreachable", context do
      Bypass.down(context.bypass)

      assert_raise HTTPoison.Error, ":econnrefused", fn ->
        Hui.search!("http://localhost:#{context.bypass.port}", q: "http test")
      end
    end
  end

  describe "search functions" do
    test "perform keywords query", context do
      Bypass.expect(context.bypass, fn conn ->
        Plug.Conn.resp(conn, 200, "")
      end)

      test_search_req_url("http://localhost:#{context.bypass.port}", q: "*")
    end

    test "handle a list of query parameters", context do
      Bypass.expect(context.bypass, fn conn ->
        Plug.Conn.resp(conn, 200, context.simple_search_response_sample)
      end)

      query = [q: "*", rows: 10, fq: ["cat:electronics", "popularity:[0 TO *]"]]
      test_search_req_url("http://localhost:#{context.bypass.port}", query)
    end

    test "handle a Hui struct", context do
      Bypass.expect(context.bypass, fn conn ->
        Plug.Conn.resp(conn, 200, context.simple_search_response_sample)
      end)

      query = %Hui.Query.DisMax{
        q: "run",
        qf: "description^2.3 title",
        mm: "2<-25% 9<-3",
        pf: "title",
        ps: 1,
        qs: 3
      }

      test_search_req_url("http://localhost:#{context.bypass.port}", query)

      query = %Hui.Query.Common{rows: 10, start: 10, fq: ["edited:true"]}
      test_search_req_url("http://localhost:#{context.bypass.port}", query)
    end

    test "handle a list of Hui structs", context do
      Bypass.expect(context.bypass, fn conn ->
        Plug.Conn.resp(conn, 200, context.simple_search_response_sample)
      end)

      x = %Hui.Query.DisMax{
        q: "run",
        qf: "description^2.3 title",
        mm: "2<-25% 9<-3",
        pf: "title",
        ps: 1,
        qs: 3
      }

      y = %Hui.Query.Common{rows: 10, start: 10, fq: ["edited:true"]}
      z = %Hui.Query.Facet{field: ["cat", "author_str"], mincount: 1}

      test_search_req_url("http://localhost:#{context.bypass.port}", [x, y, z])
    end
  end

  describe "search functions (misc)" do
    test "work with %Hui.URL{}", context do
      Bypass.expect(context.bypass, fn conn ->
        Plug.Conn.resp(conn, 200, "")
      end)

      url = %Hui.URL{
        url: "http://localhost:#{context.bypass.port}/solr/newspapers",
        handler: "suggest"
      }

      query = [suggest: true, "suggest.dictionary": "mySuggester", "suggest.q": "el"]
      test_search_req_url(url, query)
    end

    test "facilitate HTTP headers setting via %Hui.URL{}", context do
      test_header = {"accept", "application/json"}

      Bypass.expect(context.bypass, fn conn ->
        assert Enum.member?(conn.req_headers, test_header)
        Plug.Conn.resp(conn, 200, "")
      end)

      url = %Hui.URL{url: "http://localhost:#{context.bypass.port}", headers: [test_header]}
      Hui.search(url, q: "*")

      url = %Hui.URL{url: "http://localhost:#{context.bypass.port}", headers: [test_header]}
      Hui.search!(url, q: "*")
    end

    test "facilitate HTTPoison options setting via %Hui.URL{}", context do
      # test with the HTTPoison "timeout" option, "0" setting mimicking a request timeout
      url = %Hui.URL{url: "http://localhost:#{context.bypass.port}/", options: [timeout: 0]}
      assert {:error, %Hui.Error{reason: :checkout_timeout}} = Hui.search(url, q: "*")

      # test with the low-level HTTPoison "params" option, for appending additional query string params
      Bypass.expect(context.bypass, fn conn -> Plug.Conn.resp(conn, 200, "") end)

      url = %Hui.URL{
        url: "http://localhost:#{context.bypass.port}/",
        options: [params: [test: "from_test"]]
      }

      test_search_req_url(url, [q: "*"], ~r/test=from_test/)
    end

    test "work with configured URL via a config key" do
      bypass = Bypass.open(port: 8984)

      Bypass.expect(bypass, fn conn ->
        Plug.Conn.resp(conn, 200, "")
      end)

      query = [q: "edinburgh", rows: 10]
      {_, url} = Hui.URL.configured_url(:library)
      experted_request_url = Hui.URL.to_string(url) <> "?" <> Hui.URL.encode_query(query)

      {_, resp} = Hui.search(:library, query)
      assert experted_request_url == resp.request_url

      resp = Hui.search!(:library, query)
      assert experted_request_url == resp.request_url
    end

    test "handle bad URL" do
      # TODO: need fixing
      assert true
    end

    test "decode and return raw JSON Solr response as Map", context do
      Bypass.expect(context.bypass, fn conn ->
        Plug.Conn.resp(conn, 200, context.simple_search_response_sample)
      end)

      {_, resp} = Hui.search("http://localhost:#{context.bypass.port}", q: "*")
      assert is_map(resp.body)

      resp = Hui.search!("http://localhost:#{context.bypass.port}", q: "*")
      assert is_map(resp.body)
    end

    test "not decode and just return raw XML Solr response as text", context do
      Bypass.expect(context.bypass, fn conn ->
        Plug.Conn.resp(conn, 200, context.simple_search_response_sample_xml)
      end)

      {_, resp} = Hui.search("http://localhost:#{context.bypass.port}", q: "*")
      refute is_map(resp.body)
      assert is_binary(resp.body)

      resp = Hui.search!("http://localhost:#{context.bypass.port}", q: "*")
      refute is_map(resp.body)
      assert is_binary(resp.body)
    end

    test "handle malformed queries", context do
      assert {:error, context.error_einval} == Hui.q(nil)
      assert {:error, context.error_einval} == Hui.search(nil, nil)
      assert_raise Hui.Error, ":einval", fn -> Hui.q!(nil) end
      assert_raise Hui.Error, ":einval", fn -> Hui.search!(:default, nil) end
    end

    test "handle missing or malformed URL", context do
      assert {:error, context.error_einval} == Hui.search(nil, nil)
      assert {:error, context.error_nxdomain} == Hui.search("", q: "*")
      assert {:error, context.error_nxdomain} == Hui.search([], q: "*")
      assert {:error, context.error_nxdomain} == Hui.search(:not_in_config_url, q: "*")
      assert {:error, context.error_nxdomain} == Hui.search("boo", q: "*")
    end

    test "(bang) handle missing or malformed URL" do
      assert_raise Hui.Error, ":einval", fn -> Hui.search!(nil, nil) end
      assert_raise Hui.Error, ":nxdomain", fn -> Hui.search!("", q: "*") end
      assert_raise Hui.Error, ":nxdomain", fn -> Hui.search!([], q: "*") end
      assert_raise Hui.Error, ":nxdomain", fn -> Hui.search!(:not_in_config_url, q: "*") end
      assert_raise Hui.Error, ":nxdomain", fn -> Hui.search!("boo", q: "*") end
    end
  end

  describe "search/7" do
    test "query with various Solr parameters", context do
      Bypass.expect(context.bypass, fn conn ->
        Plug.Conn.resp(conn, 200, "")
      end)

      url = "http://localhost:#{context.bypass.port}"

      {_, resp} = Hui.search(url, "apache documentation")
      assert String.match?(resp.request_url, ~r/q=apache\+documentation/)

      expected = "q=a&fq=type%3Atext&rows=1&start=5&facet=true&facet.field=type&facet.field=year"

      {_, resp} = Hui.search(url, "a", 1, 5, "type:text", ["type", "year"])
      assert String.match?(resp.request_url, ~r/#{expected}/)
    end
  end

  describe "search!/7" do
    test "query with various Solr parameters", context do
      Bypass.expect(context.bypass, fn conn ->
        Plug.Conn.resp(conn, 200, "")
      end)

      url = "http://localhost:#{context.bypass.port}"

      resp = Hui.search!(url, "apache documentation")
      assert String.match?(resp.request_url, ~r/q=apache\+documentation/)

      expected = "q=a&fq=type%3Atext&rows=1&start=5&facet=true&facet.field=type&facet.field=year"

      resp = Hui.search!(url, "a", 1, 5, "type:text", ["type", "year"])
      assert String.match?(resp.request_url, ~r/#{expected}/)
    end
  end

  describe "suggester" do
    test "convenience function", context do
      Bypass.expect(context.bypass, fn conn ->
        Plug.Conn.resp(conn, 200, "")
      end)

      url = %Hui.URL{url: "http://localhost:#{context.bypass.port}"}

      {_, resp} = Hui.suggest(url, "t")
      assert String.match?(resp.request_url, ~r/suggest.q=t&suggest=true/)

      expected =
        "suggest.cfq=1939&suggest.count=5&" <>
          "suggest.dictionary=name_infix&suggest.dictionary=ln_prefix&suggest.dictionary=fn_prefix&" <>
          "suggest.q=ha&suggest=true"

      {_, resp} = Hui.suggest(url, "ha", 5, ["name_infix", "ln_prefix", "fn_prefix"], "1939")
      assert String.match?(resp.request_url, ~r/#{expected}/)
    end

    test "handle malformed parameters", context do
      assert {:error, context.error_einval} == Hui.suggest(nil, nil)
      assert {:error, context.error_einval} == Hui.suggest(:default, "")
    end
  end

  describe "suggester (bang)" do
    test "convenience function", context do
      Bypass.expect(context.bypass, fn conn ->
        Plug.Conn.resp(conn, 200, "")
      end)

      experted_url =
        "suggest.cfq=1939&suggest.count=5&" <>
          "suggest.dictionary=name_infix&suggest.dictionary=ln_prefix&suggest.dictionary=fn_prefix&" <>
          "suggest.q=ha&suggest=true"

      url = %Hui.URL{url: "http://localhost:#{context.bypass.port}"}

      resp = Hui.suggest!(url, "t")
      assert String.match?(resp.request_url, ~r/suggest.q=t&suggest=true/)

      resp = Hui.suggest!(url, "ha", 5, ["name_infix", "ln_prefix", "fn_prefix"], "1939")
      assert String.match?(resp.request_url, ~r/#{experted_url}/)
    end

    test "handle malformed parameters" do
      assert_raise Hui.Error, ":einval", fn -> Hui.suggest!(nil, nil) end
      assert_raise Hui.Error, ":einval", fn -> Hui.suggest!(:default, "") end
    end
  end
end
