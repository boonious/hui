defmodule HuiSearchLiveBangTest do
  use ExUnit.Case, async: true
  
  # tests using live Solr cores/collections that are
  # excluded by default, use '--include live' or
  # change tag value to true to run tests
  #
  # this required a configured working Solr core/collection
  # see: Configuration for further details
  # 
  # the tests below use is based on the demo collection
  # which can be setup quickly
  # http://lucene.apache.org/solr/guide/solr-tutorial.html#solr-tutorial
  # e.g. http://localhost:8983/solr/gettingstarted
  #

  describe "search (bang)" do
    @describetag live: false

    test "should perform keywords query" do
      resp = Hui.q!("*")
      assert length(resp.body["response"]["docs"]) >= 0
      assert String.match?(resp.request_url, ~r/q=*/)

      #{_status, resp} = Hui.search(:default, q: "*")
      #assert length(resp.body["response"]["docs"]) >= 0
      #assert String.match?(resp.request_url, ~r/q=*/)
    end

    test "should query with other Solr parameters" do
      solr_params = [q: "*", rows: 10, facet: true, fl: "*"]
      resp = Hui.q!(solr_params)
      assert length(resp.body["response"]["docs"]) >= 0
      assert String.match?(resp.request_url, ~r/q=%2A&rows=10&facet=true&fl=%2A/)

      #{_status, resp} = Hui.search(:default, solr_params)
      #assert length(resp.body["response"]["docs"]) >= 0
      #assert String.match?(resp.request_url, ~r/q=%2A&rows=10&facet=true&fl=%2A/)
    end

    test "should query via Hui.Q struct" do
      solr_params = %Hui.Q{q: "*", rows: 10, fq: ["cat:electronics", "popularity:[0 TO *]"], echoParams: "explicit"}
      expected_response_header_params = %{
        "echoParams" => "explicit",
        "fq" => ["cat:electronics", "popularity:[0 TO *]"],
        "q" => "*",
        "rows" => "10"
      }

      #{_status, resp} = Hui.Request.search(:default, [solr_params])
      #requested_params = resp.body["responseHeader"]["params"]
      #assert expected_response_header_params == requested_params
      #assert String.match?(resp.request_url, ~r/fq=cat%3Aelectronics&fq=popularity%3A%5B0\+TO\+%2A%5D&q=%2A&rows=10/)

      #{_status, resp} = Hui.search(:default, solr_params)
      #requested_params = resp.body["responseHeader"]["params"]
      #assert expected_response_header_params == requested_params
      #assert String.match?(resp.request_url, ~r/fq=cat%3Aelectronics&fq=popularity%3A%5B0\+TO\+%2A%5D&q=%2A&rows=10/)

      resp = Hui.q!(solr_params)
      requested_params = resp.body["responseHeader"]["params"]
      assert expected_response_header_params == requested_params
      assert String.match?(resp.request_url, ~r/fq=cat%3Aelectronics&fq=popularity%3A%5B0\+TO\+%2A%5D&q=%2A&rows=10/)
    end

    test "should query via Hui.F faceting struct" do
      x = %Hui.Q{q: "author:I*", rows: 5, echoParams: "explicit"}
      y = %Hui.F{field: ["cat", "author_str"], mincount: 1}
      solr_params = [x, y]

      resp = Hui.Request.search(:default, true, solr_params)
      requested_params = resp.body["responseHeader"]["params"]
      assert x.q == requested_params["q"]
      assert x.rows |> to_string == requested_params["rows"]
      assert "true" == requested_params["facet"]
      assert String.match?(resp.request_url, ~r/q=author%3AI%2A&rows=5&facet=true&facet.field=cat&facet.field=author_str&facet.mincount=1/)

      resp =  Hui.q!(x,y)
      assert x.q == requested_params["q"]
      assert x.rows |> to_string == requested_params["rows"]
      assert "true" == requested_params["facet"]
      assert String.match?(resp.request_url, ~r/q=author%3AI%2A&rows=5&facet=true&facet.field=cat&facet.field=author_str&facet.mincount=1/)

      #{_status, resp} =  Hui.search(:default,x,y)
      #assert x.q == requested_params["q"]
      #assert x.rows |> to_string == requested_params["rows"]
      #assert "true" == requested_params["facet"]
      #assert String.match?(resp.request_url, ~r/q=author%3AI%2A&rows=5&facet=true&facet.field=cat&facet.field=author_str&facet.mincount=1/)
    end
    
  end

end
