defmodule HuiTest do
  use ExUnit.Case, async: true
  doctest Hui.URL
  doctest Hui.Q
  doctest Hui.F
  doctest Hui.F.Range
  doctest Hui.F.Interval

  describe "Hui.URL" do

    # Using the config :hui, :default_url example in config.exs
    test "default_url! should return %Hui.URL stuct" do
      x = Hui.URL.default_url!
      assert  Hui.URL = x.__struct__
      assert "http://localhost:8983/solr/gettingstarted" = x.url
      assert "select" = x.handler
    end

    # Using the config :hui examples in config.exs
    test "configured_url should return %Hui.URL stuct for a given config key" do
      assert {:ok, %Hui.URL{url: "http://localhost:8983/solr/gettingstarted", handler: "select"}} = Hui.URL.configured_url(:default)
      assert {:ok, %Hui.URL{url: "http://localhost:8983/solr/collection", handler: "suggest"}} = Hui.URL.configured_url(:suggester)
      assert {:error, "URL not found in configuration"} = Hui.URL.configured_url(:random_url_not_in_config)
    end

    # Using the config :hui examples in config.exs
    test "configured_url should return configured headers and options in %Hui.URL stuct" do
      {:ok, %Hui.URL{url: _, handler: _, headers: headers, options: options}} = Hui.URL.configured_url(:default)
      refute headers == []
      refute options == []
    end

    test "to_string should return a URL" do
      x = %Hui.URL{url: "http://localhost:8983/solr/newspapers", handler: "suggest"}
      y = %Hui.URL{url: "http://localhost:8983/solr/newspapers"}
      assert "http://localhost:8983/solr/newspapers/suggest" = x |> Hui.URL.to_string
      assert "http://localhost:8983/solr/newspapers/select" = y |> Hui.URL.to_string
    end

    test "encode_query should handle empty, nil values / lists" do
      assert "" = Hui.URL.encode_query(nil)
      assert "" = Hui.URL.encode_query("")
      assert "" = Hui.URL.encode_query(q: "")
      assert "" = Hui.URL.encode_query(fq: [])
      assert "" = Hui.URL.encode_query(fl: nil)
      assert "" = Hui.URL.encode_query(nil)
      assert "" = Hui.URL.encode_query("")
      assert "" = Hui.URL.encode_query(q: nil, fq: "")
      assert "" = Hui.URL.encode_query(q: nil, fq: [])
      assert "fq=date&fq=year" = Hui.URL.encode_query(q: nil, fq: ["", "date", nil, "", "year"])
    end

  end

  describe "query struct Hui.Q" do

    test "parameter setting" do
      assert %Hui.Q{
        cache: nil,
        debug: nil,
        debugQuery: nil,
        defType: nil,
        df: nil,
        echoParams: nil,
        explainOther: nil,
        facet: nil,
        fl: "id,title",
        fq: ["type:image"],
        logParamsList: nil,
        omitHeader: nil,
        q: "edinburgh",
        "q.op": nil,
        rows: 15,
        segmentTerminateEarly: nil,
        sort: nil,
        sow: nil,
        start: nil,
        timeAllowed: nil,
        wt: nil
      } = %Hui.Q{q: "edinburgh", fl: "id,title", fq: ["type:image"], rows: 15}
    end

    test "provide 'q' query setting" do
      x = %Hui.Q{q: "hui solr client"}
      assert "hui solr client" = x.q
      x = %Hui.Q{q: "{!q.op=AND df=title}solr rocks"}
      assert "{!q.op=AND df=title}solr rocks" = x.q
    end

    test "can be encoded into URL request string format" do
      x = %Hui.Q{fl: "id,title", q: "loch", fq: ["type:image/jpeg", "year:2001"]}
      assert "fl=id%2Ctitle&fq=type%3Aimage%2Fjpeg&fq=year%3A2001&q=loch" = x |> Hui.Q.encode_query
    end

  end

  describe "facet struct Hui.F" do

    test "parameter setting" do
      assert %Hui.F{
        contains: nil,
        "contains.ignoreCase": nil,
        "enum.cache.minDf": nil,
        excludeTerms: nil,
        exists: nil,
        facet: true,
        field: ["type", "year"],
        interval: nil,
        limit: nil,
        matches: nil,
        method: nil,
        mincount: nil,
        missing: nil,
        offset: nil,
        "overrequest.count": nil,
        "overrequest.ratio": nil,
        pivot: [],
        "pivot.mincount": nil,
        prefix: nil,
        query: "year:[2000 TO NOW]",
        range: nil,
        sort: nil,
        threads: nil
      } = %Hui.F{field: ["type", "year"], query: "year:[2000 TO NOW]"}
    end

    test "range parameter setting" do
      assert %Hui.F.Range{
        per_field: false,
        range: "year",
        "range.end": 1799,
        "range.gap": "+10YEARS",
        "range.hardend": nil,
        "range.include": nil,
        "range.method": nil,
        "range.other": nil,
        "range.start": 1700
      } = %Hui.F.Range{range: "year", "range.gap": "+10YEARS", "range.start": 1700, "range.end": 1799}
    end

    test "interval parameter setting" do
      assert %Hui.F.Interval{
        interval: "price",
        "interval.set": ["[0,10]", "(10,100]"],
        per_field: false
      } = %Hui.F.Interval{interval: "price", "interval.set": ["[0,10]", "(10,100]"]}
    end

  end


end