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

  test "encode/2 Query.Standard struct" do
    query = %Query.Standard{df: "words_txt", q: "loch torridon", "q.op": "AND", sow: true}
    assert Encoder.encode(query) == "df=words_txt&q=loch+torridon&q.op=AND&sow=true"

    query = %Query.Standard{q: "{!q.op=OR df=series_t}black amber"}
    assert Encoder.encode(query) == "q=%7B%21q.op%3DOR+df%3Dseries_t%7Dblack+amber"
  end

  test "encode/2 Query.Common struct" do
    query = %Query.Common{fq: ["type:image"], rows: 10, start: 50, wt: "xml", fl: "id,title,description"}
    assert Encoder.encode(query) == "fl=id%2Ctitle%2Cdescription&fq=type%3Aimage&rows=10&start=50&wt=xml"

    query = %Query.Common{wt: "json", fq: ["cat:book", "inStock:true", "price:[1.99 TO 9.99]"], fl: "id,name,author,price"}
    assert Encoder.encode(query) == "fl=id%2Cname%2Cauthor%2Cprice&fq=cat%3Abook&fq=inStock%3Atrue&fq=price%3A%5B1.99+TO+9.99%5D&wt=json"
  end

  test "encode/2 Query.Common struct for SolrCloud" do
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

  test "encode/2 Query.DisMax struct" do
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

end