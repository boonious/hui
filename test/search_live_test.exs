defmodule HuiSearchLiveTest do
  use ExUnit.Case, async: true
  import TestHelpers

  alias Hui.Query
  # tests using live Solr cores/collections that are
  # excluded by default, use '--only live' or
  # change tag value of :live to true to run tests
  #
  # this required a configured working Solr core/collection
  # see: Configuration for further details
  # 
  # the tests below is based on the demo collection
  # which can be setup quickly
  # http://lucene.apache.org/solr/guide/solr-tutorial.html#solr-tutorial
  # i.e. http://localhost:8983/solr/gettingstarted
  #
  describe "search functions" do
    @describetag live: false

    test "perform keywords query" do
      {_, resp} = Hui.q("*")
      assert length(resp.body["response"]["docs"]) >= 0
      assert String.match?(resp.request_url, ~r/q=*/)

      {_, resp} = Hui.search(:default, q: "*")
      assert length(resp.body["response"]["docs"]) >= 0
      assert String.match?(resp.request_url, ~r/q=*/)
    end

    test "query with various Solr parameters" do
      {_, resp} = Hui.q("apache documentation")
      assert String.match?(resp.request_url, ~r/q=apache\+documentation/)

      expected = "q=a&fq=type%3Atext&rows=1&start=5&facet=true&facet.field=subject"

      {_, resp} = Hui.q("a", 1, 5, "type:text", ["subject"])
      assert String.match?(resp.request_url, ~r/#{expected}/)

      {_, resp} = Hui.search(:default, "a", 1, 5, "type:text", ["subject"])
      assert String.match?(resp.request_url, ~r/#{expected}/)
    end

    test "work with other URL endpoint access types" do
      {_, resp} = Hui.search("http://localhost:8983/solr/gettingstarted", q: "*")
      assert length(resp.body["response"]["docs"]) >= 0
      assert String.match?(resp.request_url, ~r/q=*/)

      {_, resp} = Hui.search(%Hui.URL{url: "http://localhost:8983/solr/gettingstarted"}, q: "*")

      assert length(resp.body["response"]["docs"]) >= 0
      assert String.match?(resp.request_url, ~r/q=*/)
    end

    test "query with other Solr parameters" do
      query = [q: "*", rows: 10, facet: true, fl: "*"]

      expected_url = ~r/q=%2A&rows=10&facet=true&fl=%2A/
      expected_params = %{"facet" => "true", "fl" => "*", "q" => "*", "rows" => "10"}
      test_all_search_live(query, expected_params, expected_url)
    end

    test "query via structs" do
      x = %Query.Standard{q: "*"}

      y = %Query.Common{
        rows: 10,
        fq: ["cat:electronics", "popularity:[0 TO *]"],
        echoParams: "explicit"
      }

      expected_params = %{
        "echoParams" => "explicit",
        "fq" => ["cat:electronics", "popularity:[0 TO *]"],
        "q" => "*",
        "rows" => "10"
      }

      expected_url =
        ~r/q=%2A&echoParams=explicit&fq=cat%3Aelectronics&fq=popularity%3A%5B0\+TO\+%2A%5D&rows=10/

      test_all_search_live([x, y], expected_params, expected_url)
    end

    test "query via more complex structs" do
      x = %Query.DisMax{
        q: "edinburgh",
        qf: "description^2.3 title",
        mm: "2<-25% 9<-3",
        pf: "title",
        ps: 1,
        qs: 3,
        bq: "edited:true"
      }

      y = %Query.Common{
        rows: 10,
        fq: ["cat:electronics", "popularity:[0 TO *]"],
        echoParams: "explicit"
      }

      z = %Query.Facet{field: ["cat", "author_str"], mincount: 1}

      expected_url =
        "bq=edited%3Atrue&mm=2%3C-25%25\\\+9%3C-3&pf=title&ps=1&q=edinburgh&qf=description%5E2.3\\\+title&qs=3" <>
          "&echoParams=explicit&fq=cat%3Aelectronics&fq=popularity%3A%5B0\\\+TO\\\+%2A%5D&" <>
          "rows=10&facet=true&facet.field=cat&facet.field=author_str&facet.mincount=1"

      expected_params = %{
        "bq" => "edited:true",
        "echoParams" => "explicit",
        "facet" => "true",
        "facet.field" => ["cat", "author_str"],
        "facet.mincount" => "1",
        "fq" => ["cat:electronics", "popularity:[0 TO *]"],
        "mm" => "2<-25% 9<-3",
        "pf" => "title",
        "ps" => "1",
        "q" => "edinburgh",
        "qf" => "description^2.3 title",
        "qs" => "3",
        "rows" => "10"
      }

      test_all_search_live([x, y, z], expected_params, ~r/#{expected_url}/)
    end

    test "provide results highlighting via struct" do
      x = %Query.Standard{q: "features:photo"}
      y = %Query.Common{rows: 1, echoParams: "explicit"}
      z = %Query.Highlight{fl: "features", usePhraseHighlighter: true, fragsize: 250, snippets: 3}

      expected_url =
        "q=features%3Aphoto&echoParams=explicit&rows=1&hl.fl=features&hl.fragsize=250&" <>
          "hl=true&hl.snippets=3&hl.usePhraseHighlighter=true"

      expected_params = %{
        "echoParams" => "explicit",
        "hl" => "true",
        "hl.fl" => "features",
        "hl.fragsize" => "250",
        "hl.snippets" => "3",
        "hl.usePhraseHighlighter" => "true",
        "q" => "features:photo",
        "rows" => "1"
      }

      test_all_search_live([x, y, z], expected_params, ~r/#{expected_url}/)
    end
  end

  describe "suggest" do
    @describetag live: false

    test "query via Hui.S" do
      x = %Hui.S{q: "ha", count: 10, dictionary: ["name_infix", "ln_prefix", "fn_prefix"]}

      expected_response_header_params = %{
        "suggest" => "true",
        "suggest.count" => "10",
        "suggest.dictionary" => ["name_infix", "ln_prefix", "fn_prefix"],
        "suggest.q" => "ha"
      }

      {_, resp} = Hui.suggest(:default, x)
      requested_params = resp.body["responseHeader"]["params"]
      assert expected_response_header_params == requested_params

      assert String.match?(
               resp.request_url,
               ~r/suggest.count=10&suggest.dictionary=name_infix&suggest.dictionary=ln_prefix&suggest.dictionary=fn_prefix&suggest.q=ha&suggest=true/
             )
    end

    test "convenience function" do
      expected_response_header_params = %{
        "suggest" => "true",
        "suggest.count" => "5",
        "suggest.dictionary" => ["name_infix", "ln_prefix", "fn_prefix"],
        "suggest.q" => "ha",
        "suggest.cfq" => "1939"
      }

      {_, resp} = Hui.suggest(:default, "ha", 5, ["name_infix", "ln_prefix", "fn_prefix"], "1939")

      requested_params = resp.body["responseHeader"]["params"]

      expected_url_str =
        "suggest.cfq=1939&suggest.count=5&suggest.dictionary=name_infix&suggest.dictionary=ln_prefix&suggest.dictionary=fn_prefix&suggest.q=ha&suggest=true"

      assert expected_response_header_params == requested_params
      assert String.match?(resp.request_url, ~r/#{expected_url_str}/)
    end
  end

  describe "suggest!" do
    @describetag live: false

    test "should query via Hui.S" do
      x = %Hui.S{q: "ha", count: 10, dictionary: ["name_infix", "ln_prefix", "fn_prefix"]}

      expected_response_header_params = %{
        "suggest" => "true",
        "suggest.count" => "10",
        "suggest.dictionary" => ["name_infix", "ln_prefix", "fn_prefix"],
        "suggest.q" => "ha"
      }

      resp = Hui.suggest!(:default, x)
      requested_params = resp.body["responseHeader"]["params"]
      assert expected_response_header_params == requested_params

      assert String.match?(
               resp.request_url,
               ~r/suggest.count=10&suggest.dictionary=name_infix&suggest.dictionary=ln_prefix&suggest.dictionary=fn_prefix&suggest.q=ha&suggest=true/
             )
    end

    test "convenience function" do
      expected_response_header_params = %{
        "suggest" => "true",
        "suggest.count" => "5",
        "suggest.dictionary" => ["name_infix", "ln_prefix", "fn_prefix"],
        "suggest.q" => "ha",
        "suggest.cfq" => "1939"
      }

      resp = Hui.suggest!(:default, "ha", 5, ["name_infix", "ln_prefix", "fn_prefix"], "1939")
      requested_params = resp.body["responseHeader"]["params"]

      expected_url_str =
        "suggest.cfq=1939&suggest.count=5&suggest.dictionary=name_infix&suggest.dictionary=ln_prefix&suggest.dictionary=fn_prefix&suggest.q=ha&suggest=true"

      assert expected_response_header_params == requested_params
      assert String.match?(resp.request_url, ~r/#{expected_url_str}/)
    end
  end
end
