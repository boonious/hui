defmodule HuiEncoderTest do
  use ExUnit.Case, async: true

  alias Hui.Encoder
  alias Hui.Query

  test "encode/2 map" do
    assert Encoder.encode(%{q: "loch", rows: 10}) == "q=loch&rows=10"
  end

  test "encode/2 keyword list" do
    assert Encoder.encode([q: "loch", rows: 10]) == "q=loch&rows=10"
  end

  test "encode/2 Standard struct" do
    query = %Query.Standard{df: "words_txt", q: "loch torridon", "q.op": "AND", sow: true}
    assert Encoder.encode(query) == "df=words_txt&q=loch+torridon&q.op=AND&sow=true"

    query = %Query.Standard{q: "{!q.op=OR df=series_t}black amber"}
    assert Encoder.encode(query) == "q=%7B%21q.op%3DOR+df%3Dseries_t%7Dblack+amber"
  end

  test "encode/2 Common struct" do
    query = %Query.Common{fq: ["type:image"], rows: 10, start: 50, wt: "xml", fl: "id,title,description"}
    assert Encoder.encode(query) == "fl=id%2Ctitle%2Cdescription&fq=type%3Aimage&rows=10&start=50&wt=xml"

    query = %Query.Common{wt: "json", fq: ["cat:book", "inStock:true", "price:[1.99 TO 9.99]"], fl: "id,name,author,price"}
    assert Encoder.encode(query) == "fl=id%2Cname%2Cauthor%2Cprice&fq=cat%3Abook&fq=inStock%3Atrue&fq=price%3A%5B1.99+TO+9.99%5D&wt=json"

    query = %Query.Common{rows: 10, debug: [:query, :timing], "debug.explain.structured": true}
    assert Encoder.encode(query) == "debug=query&debug=timing&debug.explain.structured=true&rows=10"
  end

  test "encode/2 Common struct for SolrCloud" do
    query = %Query.Common{
      collection: "library,common",
      distrib: true,
      shards: "localhost:7574/solr/gettingstarted,localhost:8983/solr/gettingstarted",
      "shards.tolerant": true,
      "shards.info": true
    }

    assert Encoder.encode(query) == "collection=library%2Ccommon&distrib=true&shards=localhost%3A7574%2Fsolr%2Fgettingstarted%2Clocalhost%3A8983%2Fsolr%2Fgettingstarted&shards.info=true&shards.tolerant=true"
  end

  test "encode/2 list of structs" do
    x = %Query.Common{rows: 5, fq: ["cat:book", "inStock:true", "price:[1.99 TO 9.99]"]}
    y = %Query.Standard{q: "{!q.op=OR df=series_t}black amber"}

    assert Encoder.encode([x,y]) == "fq=cat%3Abook&fq=inStock%3Atrue&fq=price%3A%5B1.99+TO+9.99%5D&rows=5&q=%7B%21q.op%3DOR+df%3Dseries_t%7Dblack+amber"
  end

  test "encode/2 DisMax struct" do
    query = %Query.DisMax{
      q: "edinburgh",
      qf: "description^2.3 title",
      mm: "2<-25% 9<-3",
      pf: "title",
      ps: 1,
      qs: 3,
      bq: "edited:true"
    }

    assert Encoder.encode(query) == "bq=edited%3Atrue&mm=2%3C-25%25+9%3C-3&pf=title&ps=1&q=edinburgh&qf=description%5E2.3+title&qs=3"
  end

  test "encode/2 Facet struct" do
    assert Encoder.encode(%Query.Facet{field: ["type", "year"], query: "year:[2000 TO NOW]", sort: :count})
    == "facet=true&facet.field=type&facet.field=year&facet.query=year%3A%5B2000+TO+NOW%5D&facet.sort=count"
  end

  test "encode/2 FacetRange struct" do
    query = %Query.FacetRange{range: "year", gap: "+10YEARS", start: 1700, end: 1799}
    assert Encoder.encode(query) == "facet.range.end=1799&facet.range.gap=%2B10YEARS&facet.range=year&facet.range.start=1700"

    query = %Query.FacetRange{range: "year", gap: "+10YEARS", start: 1700, end: 1799, per_field: true}
    assert Encoder.encode(query) == "f.year.facet.range.end=1799&f.year.facet.range.gap=%2B10YEARS&facet.range=year&f.year.facet.range.start=1700"

    query = %Query.FacetRange{range: "price", gap: "10", start: 0, end: 100, per_field: true}
    assert Encoder.encode(query) == "f.price.facet.range.end=100&f.price.facet.range.gap=10&facet.range=price&f.price.facet.range.start=0"
  end

  test "encode/2 FacetInterval struct" do
    query = %Query.FacetInterval{interval: "price", set: "[0,10]"}
    assert Encoder.encode(query) == "facet.interval=price&facet.interval.set=%5B0%2C10%5D"

    query = %Query.FacetInterval{interval: "price", set: ["[0,10]", "(10,100]"], per_field: true}
    assert Encoder.encode(query) == "facet.interval=price&f.price.facet.interval.set=%5B0%2C10%5D&f.price.facet.interval.set=%2810%2C100%5D"
  end

  test "encode/2 Facet struct in conjunction with FacetRange" do
    x = %Query.FacetRange{range: "year", gap: "+10YEARS", start: 1700, end: 1799}
    y = %Query.Facet{field: "type", range: x}

    assert Encoder.encode(y)
    == "facet=true&facet.field=type&facet.range.end=1799&facet.range.gap=%2B10YEARS&facet.range=year&facet.range.start=1700"
  end

  test "encode/2 Facet struct in conjunction with multiple FacetRanges" do
   x = %Query.FacetRange{range: "year", gap: "+10YEARS", start: 1700, end: 1799, per_field: true}
   y = %Query.FacetRange{range: "price", gap: "10", start: 0, end: 100, per_field: true}
   z = %Query.Facet{field: "type", range: [x, y]}

   assert Encoder.encode(z)
   == "facet=true&facet.field=type&" <>
   "f.year.facet.range.end=1799&f.year.facet.range.gap=%2B10YEARS&facet.range=year&f.year.facet.range.start=1700&" <>
   "f.price.facet.range.end=100&f.price.facet.range.gap=10&facet.range=price&f.price.facet.range.start=0"
  end

  test "encode/2 Facet struct in conjunction with FacetInterval" do
    x = %Query.FacetInterval{interval: "price", set: ["[0,10]", "(10,100]"]}
    y = %Query.Facet{field: "type", interval: x}

    assert Encoder.encode(y)
    == "facet=true&facet.field=type&facet.interval=price&facet.interval.set=%5B0%2C10%5D&facet.interval.set=%2810%2C100%5D"
  end

end