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

    test "set basic parameters" do
     x = %Hui.Q{
       bf: nil,
       bq: nil,
       cache: nil,
       debug: nil,
       debugQuery: nil,
       defType: nil,
       df: nil,
       echoParams: nil,
       explainOther: nil,
       fl: "id,title",
       fq: ["type:image"],
       "json.nl": nil,
       "json.wrf": nil,
       logParamsList: nil,
       mm: nil,
       omitHeader: nil,
       pf: nil,
       ps: nil,
       q: "edinburgh",
       "q.alt": nil,
       "q.op": nil,
       qf: nil,
       qs: nil,
       rows: 15,
       segmentTerminateEarly: nil,
       sort: nil,
       sow: nil,
       start: nil,
       tie: nil,
       timeAllowed: nil,
       tr: nil,
       wt: nil
     }
     assert x == %Hui.Q{q: "edinburgh", fl: "id,title", fq: ["type:image"], rows: 15}
    end

    test "set dismax parameters" do
     x = %Hui.Q{
       bf: nil,
       bq: "edited:true",
       cache: nil,
       debug: nil,
       debugQuery: nil,
       defType: nil,
       df: nil,
       echoParams: nil,
       explainOther: nil,
       fl: nil,
       fq: [],
       "json.nl": nil,
       "json.wrf": nil,
       logParamsList: nil,
       mm: "2<-25% 9<-3",
       omitHeader: nil,
       pf: "title",
       ps: 1,
       q: "edinburgh",
       "q.alt": nil,
       "q.op": nil,
       qf: "description^2.3 title",
       qs: 3,
       rows: nil,
       segmentTerminateEarly: nil,
       sort: nil,
       sow: nil,
       start: nil,
       tie: nil,
       timeAllowed: nil,
       tr: nil,
       wt: nil
     }
     assert x == %Hui.Q{q: "edinburgh", qf: "description^2.3 title", mm: "2<-25% 9<-3", pf: "title", ps: 1, qs: 3, bq: "edited:true"}
    end

    test "provide 'q' query setting" do
      x = %Hui.Q{q: "hui solr client"}
      assert "hui solr client" = x.q
      x = %Hui.Q{q: "{!q.op=AND df=title}solr rocks"}
      assert "{!q.op=AND df=title}solr rocks" = x.q
    end

    test "can be encoded into URL query string" do
      x = %Hui.Q{fl: "id,title", q: "loch", fq: ["type:image/jpeg", "year:2001"]}
      assert "fl=id%2Ctitle&fq=type%3Aimage%2Fjpeg&fq=year%3A2001&q=loch" = x |> Hui.URL.encode_query
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
        end: 1799,
        gap: "+10YEARS",
        hardend: nil,
        include: nil,
        method: nil,
        other: nil,
        start: 1700
      } = %Hui.F.Range{range: "year", gap: "+10YEARS", start: 1700, end: 1799}
    end

    test "interval parameter setting" do
      assert %Hui.F.Interval{
        interval: "price",
        set: ["[0,10]", "(10,100]"],
        per_field: false
      } = %Hui.F.Interval{interval: "price", set: ["[0,10]", "(10,100]"]}
    end

    test "can be encoded into URL query string" do
      assert "facet=true&facet.field=type&facet.field=year&facet.query=year%3A%5B2000+TO+NOW%5D" 
      = %Hui.F{field: ["type", "year"], query: "year:[2000 TO NOW]"} |> Hui.URL.encode_query
    end

    test "range can be encoded into URL query string" do
      x = %Hui.F.Range{range: "year", gap: "+10YEARS", start: 1700, end: 1799}
      assert "facet.range.end=1799&facet.range.gap=%2B10YEARS&facet.range=year&facet.range.start=1700"
      = x |> Hui.URL.encode_query

      y = %Hui.F{field: "type", range: x}
      assert "facet=true&facet.field=type&facet.range.end=1799&facet.range.gap=%2B10YEARS&facet.range=year&facet.range.start=1700" 
      = y |> Hui.URL.encode_query
    end

    test "interval can be encoded into URL query string" do
      x = %Hui.F.Interval{interval: "price", set: ["[0,10]", "(10,100]"]}
      assert "facet.interval=price&facet.interval.set=%5B0%2C10%5D&facet.interval.set=%2810%2C100%5D"
      = x |> Hui.URL.encode_query

      y = %Hui.F{field: "type", interval: x}
      assert "facet=true&facet.field=type&facet.interval=price&facet.interval.set=%5B0%2C10%5D&facet.interval.set=%2810%2C100%5D"
      = y |> Hui.URL.encode_query
    end

    test "range per field URL encoding" do
     x = %Hui.F.Range{range: "year", gap: "+10YEARS", start: 1700, end: 1799, per_field: true}
     assert "f.year.facet.range.end=1799&f.year.facet.range.gap=%2B10YEARS&facet.range=year&f.year.facet.range.start=1700"
     = x |> Hui.URL.encode_query

     y = %Hui.F.Range{range: "price", gap: "10", start: 0, end: 100, per_field: true}
     assert "f.price.facet.range.end=100&f.price.facet.range.gap=10&facet.range=price&f.price.facet.range.start=0"
     = y |> Hui.URL.encode_query

     z = %Hui.F{field: "type", range: [x, y]}
     assert "facet=true&facet.field=type&" <>
     "f.year.facet.range.end=1799&f.year.facet.range.gap=%2B10YEARS&facet.range=year&f.year.facet.range.start=1700&" <>
     "f.price.facet.range.end=100&f.price.facet.range.gap=10&facet.range=price&f.price.facet.range.start=0"
     = z |> Hui.URL.encode_query     
    end

    test "interval per field URL encoding" do
     x = %Hui.F.Interval{interval: "price", set: ["[0,10]", "(10,100]"], per_field: true}
     assert "facet.interval=price&f.price.facet.interval.set=%5B0%2C10%5D&f.price.facet.interval.set=%2810%2C100%5D"
     = x |> Hui.URL.encode_query

     y = %Hui.F.Interval{interval: "age", set: ["[0,30]", "(30,60]", "[60, 100]"], per_field: true}
     assert "facet.interval=age&f.age.facet.interval.set=%5B0%2C30%5D&f.age.facet.interval.set=%2830%2C60%5D&f.age.facet.interval.set=%5B60%2C+100%5D"
     = y |> Hui.URL.encode_query

     z = %Hui.F{field: "type", interval: [x, y]}
     assert "facet=true&facet.field=type&" <>
     "facet.interval=price&f.price.facet.interval.set=%5B0%2C10%5D&f.price.facet.interval.set=%2810%2C100%5D&" <>
     "facet.interval=age&f.age.facet.interval.set=%5B0%2C30%5D&f.age.facet.interval.set=%2830%2C60%5D&f.age.facet.interval.set=%5B60%2C+100%5D"
     = z |> Hui.URL.encode_query
    end

  end


end