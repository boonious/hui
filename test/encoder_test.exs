defmodule HuiEncoderTest do
  use ExUnit.Case, async: true
  import Fixtures.Update

  alias Hui.Encoder
  alias Hui.Query

  describe "encode map" do
    setup do
      %{
        query: %{
          q: "harry",
          rows: 10,
          fq: ["cat:book", "price:[1.99 TO 9.99]"],
          fl: "id,name"
        }
      }
    end

    test "in binary format", %{query: query} do
      assert Encoder.encode(query) == "fl=id%2Cname&fq=cat%3Abook&fq=price%3A%5B1.99+TO+9.99%5D&q=harry&rows=10"
    end

    test "in iolist format", %{query: query} do
      assert Encoder.encode_to_iodata(query) == [
               "fl",
               61,
               "id%2Cname",
               38,
               [
                 "fq",
                 61,
                 "cat%3Abook",
                 38,
                 ["fq", 61, "price%3A%5B1.99+TO+9.99%5D", 38, ["q", 61, "harry", 38, ["rows", 61, "10"]]]
               ]
             ]
    end
  end

  describe "encode keyword list" do
    test "in binary format" do
      assert Encoder.encode(q: "loch", rows: 10) == "q=loch&rows=10"
    end

    test "in iolist format" do
      assert Encoder.encode_to_iodata(q: "harry", rows: 10, start: 100) == [
               "q",
               61,
               "harry",
               38,
               ["rows", 61, "10", 38, ["start", 61, "100"]]
             ]
    end
  end

  test "encoder should raise error when query encoding is not defined" do
    assert_raise Protocol.UndefinedError, fn -> Hui.Encoder.encode(nil) end
    assert_raise Protocol.UndefinedError, fn -> Hui.Encoder.encode("") end
  end

  test "encodes Standard struct" do
    query = %Query.Standard{df: "words_txt", q: "loch torridon", "q.op": "AND", sow: true}
    assert Encoder.encode(query) == "df=words_txt&q=loch+torridon&q.op=AND&sow=true"

    query = %Query.Standard{q: "{!q.op=OR df=series_t}black amber"}
    assert Encoder.encode(query) == "q=%7B%21q.op%3DOR+df%3Dseries_t%7Dblack+amber"
  end

  test "encodes Common struct" do
    query = %Query.Common{
      fq: ["type:image"],
      rows: 10,
      start: 50,
      wt: "xml",
      fl: "id,title,description"
    }

    assert Encoder.encode(query) ==
             "fl=id%2Ctitle%2Cdescription&fq=type%3Aimage&rows=10&start=50&wt=xml"

    query = %Query.Common{
      wt: "json",
      fq: ["cat:book", "inStock:true", "price:[1.99 TO 9.99]"],
      fl: "id,name,author,price"
    }

    assert Encoder.encode(query) ==
             "fl=id%2Cname%2Cauthor%2Cprice&fq=cat%3Abook&fq=inStock%3Atrue&fq=price%3A%5B1.99+TO+9.99%5D&wt=json"

    query = %Query.Common{rows: 10, debug: [:query, :timing], "debug.explain.structured": true}

    assert Encoder.encode(query) ==
             "debug=query&debug=timing&debug.explain.structured=true&rows=10"
  end

  test "encodes Common struct for SolrCloud" do
    query = %Query.Common{
      collection: "library,common",
      distrib: true,
      shards: "localhost:7574/solr/gettingstarted,localhost:8983/solr/gettingstarted",
      "shards.tolerant": true,
      "shards.info": true
    }

    assert Encoder.encode(query) ==
             "collection=library%2Ccommon&distrib=true&shards=localhost%3A7574%2Fsolr%2Fgettingstarted%2Clocalhost%3A8983%2Fsolr%2Fgettingstarted&shards.info=true&shards.tolerant=true"
  end

  test "encodes list of structs" do
    x = %Query.Common{rows: 5, fq: ["cat:book", "inStock:true", "price:[1.99 TO 9.99]"]}
    y = %Query.Standard{q: "{!q.op=OR df=series_t}black amber"}

    assert Encoder.encode([x, y]) ==
             "fq=cat%3Abook&fq=inStock%3Atrue&fq=price%3A%5B1.99+TO+9.99%5D&rows=5&q=%7B%21q.op%3DOR+df%3Dseries_t%7Dblack+amber"
  end

  test "encodes DisMax struct" do
    query = %Query.DisMax{
      q: "edinburgh",
      qf: "description^2.3 title",
      mm: "2<-25% 9<-3",
      pf: "title",
      ps: 1,
      qs: 3,
      bq: "edited:true"
    }

    assert Encoder.encode(query) ==
             "bq=edited%3Atrue&defType=dismax&mm=2%3C-25%25+9%3C-3&pf=title&ps=1&q=edinburgh&qf=description%5E2.3+title&qs=3"
  end

  test "encodes Facet struct" do
    assert Encoder.encode(%Query.Facet{
             field: ["type", "year"],
             query: "year:[2000 TO NOW]",
             sort: :count
           }) ==
             "facet=true&facet.field=type&facet.field=year&facet.query=year%3A%5B2000+TO+NOW%5D&facet.sort=count"
  end

  test "encodes FacetRange struct" do
    query = %Query.FacetRange{range: "year", gap: "+10YEARS", start: 1700, end: 1799}

    assert Encoder.encode(query) ==
             "facet.range.end=1799&facet.range.gap=%2B10YEARS&facet.range=year&facet.range.start=1700"

    query = %Query.FacetRange{
      range: "year",
      gap: "+10YEARS",
      start: 1700,
      end: 1799,
      per_field: true
    }

    assert Encoder.encode(query) ==
             "f.year.facet.range.end=1799&f.year.facet.range.gap=%2B10YEARS&facet.range=year&f.year.facet.range.start=1700"

    query = %Query.FacetRange{range: "price", gap: "10", start: 0, end: 100, per_field: true}

    assert Encoder.encode(query) ==
             "f.price.facet.range.end=100&f.price.facet.range.gap=10&facet.range=price&f.price.facet.range.start=0"
  end

  test "encodes FacetInterval struct" do
    query = %Query.FacetInterval{interval: "price", set: "[0,10]"}
    assert Encoder.encode(query) == "facet.interval=price&facet.interval.set=%5B0%2C10%5D"

    query = %Query.FacetInterval{interval: "price", set: ["[0,10]", "(10,100]"], per_field: true}

    assert Encoder.encode(query) ==
             "facet.interval=price&f.price.facet.interval.set=%5B0%2C10%5D&f.price.facet.interval.set=%2810%2C100%5D"
  end

  test "encodes Facet struct in conjunction with FacetRange" do
    x = %Query.FacetRange{range: "year", gap: "+10YEARS", start: 1700, end: 1799}
    y = %Query.Facet{field: "type", range: x}

    assert Encoder.encode(y) ==
             "facet=true&facet.field=type&facet.range.end=1799&facet.range.gap=%2B10YEARS&facet.range=year&facet.range.start=1700"
  end

  test "encodes Facet struct in conjunction with multiple FacetRanges" do
    x = %Query.FacetRange{range: "year", gap: "+10YEARS", start: 1700, end: 1799, per_field: true}
    y = %Query.FacetRange{range: "price", gap: "10", start: 0, end: 100, per_field: true}
    z = %Query.Facet{field: "type", range: [x, y]}

    assert Encoder.encode(z) ==
             "facet=true&facet.field=type&" <>
               "f.year.facet.range.end=1799&f.year.facet.range.gap=%2B10YEARS&facet.range=year&f.year.facet.range.start=1700&" <>
               "f.price.facet.range.end=100&f.price.facet.range.gap=10&facet.range=price&f.price.facet.range.start=0"
  end

  test "encodes Facet struct in conjunction with FacetInterval" do
    x = %Query.FacetInterval{interval: "price", set: ["[0,10]", "(10,100]"]}
    y = %Query.Facet{field: "type", interval: x}

    assert Encoder.encode(y) ==
             "facet=true&facet.field=type&facet.interval=price&facet.interval.set=%5B0%2C10%5D&facet.interval.set=%2810%2C100%5D"
  end

  test "encodes Facet struct in conjunction with multiple FacetIntervals" do
    x = %Query.FacetInterval{interval: "price", set: ["[0,10]", "(10,100]"], per_field: true}

    y = %Query.FacetInterval{
      interval: "age",
      set: ["[0,30]", "(30,60]", "[60, 100]"],
      per_field: true
    }

    z = %Query.Facet{field: "type", interval: [x, y]}

    assert Hui.Encoder.encode(z) ==
             "facet=true&facet.field=type&" <>
               "facet.interval=price&f.price.facet.interval.set=%5B0%2C10%5D&f.price.facet.interval.set=%2810%2C100%5D&" <>
               "facet.interval=age&f.age.facet.interval.set=%5B0%2C30%5D&f.age.facet.interval.set=%2830%2C60%5D&f.age.facet.interval.set=%5B60%2C+100%5D"
  end

  test "encodes Highlight struct" do
    assert Encoder.encode(%Query.Highlight{
             fl: "title,words",
             usePhraseHighlighter: true,
             fragsize: 250,
             snippets: 3
           }) ==
             "hl.fl=title%2Cwords&hl.fragsize=250&hl=true&hl.snippets=3&hl.usePhraseHighlighter=true"
  end

  test "encodes HighlighterOriginal struct - original highlighter" do
    assert Encoder.encode(%Query.HighlighterOriginal{
             mergeContiguous: true,
             "simple.pre": "<b>",
             "simple.post": "</b>",
             preserveMulti: true
           }) ==
             "hl.mergeContiguous=true&hl.preserveMulti=true&hl.simple.post=%3C%2Fb%3E&hl.simple.pre=%3Cb%3E"
  end

  test "encodes HighlighterUnified struct" do
    assert Encoder.encode(%Query.HighlighterUnified{
             offsetSource: :POSTINGS,
             defaultSummary: true,
             "score.k1": 0,
             "bs.type": :SEPARATOR,
             weightMatches: true
           }) ==
             "hl.bs.type=SEPARATOR&hl.defaultSummary=true&hl.offsetSource=POSTINGS&hl.score.k1=0&hl.weightMatches=true"
  end

  test "encodes HighlighterFastVector struct" do
    assert Encoder.encode(%Query.HighlighterFastVector{
             boundaryScanner: "breakIterator",
             "bs.type": "WORD",
             "bs.language": "EN",
             "bs.country": "US"
           }) ==
             "hl.boundaryScanner=breakIterator&hl.bs.country=US&hl.bs.language=EN&hl.bs.type=WORD"
  end

  test "encodes MoreLikeThis struct" do
    assert Encoder.encode(%Query.MoreLikeThis{
             fl: "manu,cat",
             mindf: 10,
             mintf: 200,
             "match.include": true,
             count: 10
           }) ==
             "mlt.count=10&mlt.fl=manu%2Ccat&mlt.match.include=true&mlt.mindf=10&mlt.mintf=200&mlt=true"
  end

  test "encodes Suggest struct" do
    assert Encoder.encode(%Query.Suggest{
             q: "ha",
             count: 10,
             dictionary: ["name_infix", "surname_prefix"],
             reload: true,
             build: true
           }) ==
             "suggest.build=true&suggest.count=10&suggest.dictionary=name_infix&suggest.dictionary=surname_prefix&suggest.q=ha&suggest.reload=true&suggest=true"
  end

  test "encodes SpellCheck struct" do
    assert Encoder.encode(%Query.SpellCheck{
             q: "delll ultra sharp",
             count: 10,
             "collateParam.q.op": "AND",
             dictionary: "default"
           }) ==
             "spellcheck.collateParam.q.op=AND&spellcheck.count=10&spellcheck.dictionary=default&spellcheck.q=delll+ultra+sharp&spellcheck=true"
  end

  test "encodes Update struct - single doc" do
    encoded = Encoder.encode(%Query.Update{doc: single_doc()})

    assert encoded =~ single_doc() |> Jason.encode!()
    assert encoded == single_doc_update_json()
  end

  test "encodes Update struct - single doc with commit option" do
    encoded = Encoder.encode(%Query.Update{doc: single_doc(), commit: true})

    assert encoded =~ single_doc() |> Jason.encode!()
    assert encoded == update_json(single_doc(), commit: true)

    encoded = Encoder.encode(%Query.Update{doc: single_doc(), commit: false})
    assert encoded =~ single_doc() |> Jason.encode!()
    assert encoded == update_json(single_doc())
  end

  test "encodes Update struct - multiple docs" do
    encoded = Encoder.encode(%Query.Update{doc: multi_docs()})

    for doc <- multi_docs() do
      assert encoded =~ doc |> Jason.encode!()
    end

    assert encoded == multi_docs_update_json()
  end

  test "encodes Update struct - single doc with commitWithin, overwrite commands" do
    x = %Query.Update{doc: single_doc(), commitWithin: 5000}
    assert Encoder.encode(x) == single_doc_update_json(single_doc(), commitWithin: 5000)

    x = %Query.Update{doc: single_doc(), commitWithin: 10, overwrite: true}
    assert Encoder.encode(x) == single_doc_update_json(single_doc(), commitWithin: 10, overwrite: true)

    x = %Query.Update{doc: single_doc(), overwrite: false}
    assert Encoder.encode(x) == single_doc_update_json(single_doc(), overwrite: false)
  end

  test "encodes Update struct - multiple docs with commitWithin, overwrite commands" do
    x = %Query.Update{doc: multi_docs(), commitWithin: 1000}
    assert Encoder.encode(x) == multi_docs_update_json(multi_docs(), commitWithin: 1000)

    x = %Query.Update{doc: multi_docs(), commitWithin: 10, overwrite: true}
    assert Encoder.encode(x) == multi_docs_update_json(multi_docs(), commitWithin: 10, overwrite: true)

    x = %Query.Update{doc: multi_docs(), overwrite: false}
    assert Encoder.encode(x) == multi_docs_update_json(multi_docs(), overwrite: false)
  end

  test "encodes Update struct with commit, waitSearcher, expungeDeletes commands" do
    x = %Query.Update{commit: true}
    assert x |> Encoder.encode() == "{\"commit\":{}}"

    x = %Query.Update{commit: false}
    assert x |> Encoder.encode() == "{}"

    x = %Query.Update{commit: true, waitSearcher: true}
    assert x |> Encoder.encode() == "{\"commit\":{\"waitSearcher\":true}}"

    x = %Query.Update{commit: true, waitSearcher: false}
    assert x |> Encoder.encode() == "{\"commit\":{\"waitSearcher\":false}}"

    x = %Query.Update{commit: true, expungeDeletes: true}
    assert x |> Encoder.encode() == "{\"commit\":{\"expungeDeletes\":true}}"

    x = %Query.Update{commit: true, waitSearcher: true, expungeDeletes: false}

    assert x |> Encoder.encode() ==
             "{\"commit\":{\"expungeDeletes\":false,\"waitSearcher\":true}}"
  end

  test "encodes Update struct with optimize, waitSearcher, maxSegment commands" do
    x = %Query.Update{optimize: true}
    assert x |> Encoder.encode() == "{\"optimize\":{}}"

    x = %Query.Update{optimize: false}
    assert x |> Encoder.encode() == "{}"

    x = %Query.Update{optimize: true, waitSearcher: true}
    assert x |> Encoder.encode() == "{\"optimize\":{\"waitSearcher\":true}}"

    x = %Query.Update{optimize: true, waitSearcher: false}
    assert x |> Encoder.encode() == "{\"optimize\":{\"waitSearcher\":false}}"

    x = %Query.Update{optimize: true, maxSegments: 20}
    assert x |> Encoder.encode() == "{\"optimize\":{\"maxSegments\":20}}"

    x = %Query.Update{optimize: true, waitSearcher: true, maxSegments: 20}
    assert x |> Encoder.encode() == "{\"optimize\":{\"maxSegments\":20,\"waitSearcher\":true}}"
  end

  test "encodes Update struct with delete by ID command" do
    x = %Query.Update{delete_id: "tt1316540"}
    assert x |> Encoder.encode() == "{\"delete\":{\"id\":\"tt1316540\"}}"

    x = %Query.Update{delete_id: ["tt1316540", "tt1650453"]}

    assert x |> Encoder.encode() ==
             "{\"delete\":{\"id\":\"tt1316540\"},\"delete\":{\"id\":\"tt1650453\"}}"
  end

  test "encodes Update struct with delete by query command" do
    x = %Query.Update{delete_query: "name:Persona"}
    assert x |> Encoder.encode() == "{\"delete\":{\"query\":\"name:Persona\"}}"

    x = %Query.Update{delete_query: ["name:Persona", "genre:Drama"]}

    assert x |> Encoder.encode() ==
             "{\"delete\":{\"query\":\"name:Persona\"},\"delete\":{\"query\":\"genre:Drama\"}}"
  end

  test "encodes Update struct - grouped update commands" do
    update_cmd = [
      commitWithin: 50,
      overwrite: true,
      commit: true,
      waitSearcher: true,
      expungeDeletes: false,
      optimize: true,
      maxSegments: 20,
      delete_id: ["tt1316540", "tt1650453"]
    ]

    encoded = Encoder.encode(%Query.Update{struct(Query.Update, update_cmd) | doc: multi_docs()})

    for doc <- multi_docs() do
      assert encoded =~ doc |> Jason.encode!()
    end

    assert encoded =~
             multi_docs_update_json(multi_docs(), commitWithin: 50, overwrite: true) |> String.trim_trailing("}")

    assert encoded =~ "\"commit\":{\"expungeDeletes\":false,\"waitSearcher\":true}"
    assert encoded =~ "\"optimize\":{\"maxSegments\":20,\"waitSearcher\":true}"
    assert encoded =~ "\"delete\":{\"id\":\"tt1316540\"},\"delete\":{\"id\":\"tt1650453\"}"
    assert encoded == File.read!("test/fixtures/update_doc_multi_cmds.json")
  end

  test "encodes Update struct - rollback" do
    x = %Query.Update{rollback: true}
    assert x |> Encoder.encode() == "{\"rollback\":{}}"

    x = %Query.Update{rollback: true, delete_query: ["name:Persona"]}
    assert x |> Encoder.encode() == "{\"delete\":{\"query\":\"name:Persona\"},\"rollback\":{}}"
  end
end
