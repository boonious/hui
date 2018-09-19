defmodule HuiStructTest do
  use ExUnit.Case, async: true
  doctest Hui.Q
  doctest Hui.F
  doctest Hui.F.Range
  doctest Hui.F.Interval

  describe "query struct Hui.Q" do

    test "set basic parameters" do
     x = %Hui.Q{
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
       omitHeader: nil,
       q: "edinburgh",
       "q.op": nil,
       rows: 15,
       segmentTerminateEarly: nil,
       sort: nil,
       sow: nil,
       start: nil,
       timeAllowed: nil,
       tr: nil,
       wt: nil
     }
     assert x == %Hui.Q{q: "edinburgh", fl: "id,title", fq: ["type:image"], rows: 15}
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

  describe "dismax struct Hui.D" do

   test "set dismax parameters" do
    x = %Hui.D{
      bf: nil,
      boost: nil,
      bq: "edited:true",
      lowercaseOperators: nil,
      mm: "2<-25% 9<-3",
      "mm.autoRelax": nil,
      pf: "title",
      pf2: nil,
      pf3: nil,
      ps: 1,
      ps2: nil,
      ps3: nil,
      q: "edinburgh",
      "q.alt": nil,
      qf: "description^2.3 title",
      qs: 3,
      sow: nil,
      stopwords: nil,
      tie: nil,
      uf: nil
    }
    assert x == %Hui.D{q: "edinburgh", qf: "description^2.3 title", mm: "2<-25% 9<-3", pf: "title", ps: 1, qs: 3, bq: "edited:true"}
   end

   test "set extended dismax parameters" do
    x = %Hui.D{
      bf: nil,
      boost: nil,
      bq: nil,
      lowercaseOperators: nil,
      mm: nil,
      "mm.autoRelax": true,
      pf: nil,
      pf2: "description^2.3 title",
      pf3: nil,
      ps: 3,
      ps2: nil,
      ps3: nil,
      q: nil,
      "q.alt": nil,
      qf: nil,
      qs: nil,
      sow: true,
      stopwords: nil,
      tie: nil,
      uf: "title *_s"
    }
    assert x == %Hui.D{sow: true, "mm.autoRelax": true, ps: 3, pf2: "description^2.3 title", uf: "title *_s"}
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