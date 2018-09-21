defmodule HuiStructTest do
  use ExUnit.Case, async: true
  doctest Hui.Q
  doctest Hui.F
  doctest Hui.F.Range
  doctest Hui.F.Interval
  doctest Hui.H

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

  describe "higlighting struct Hui.H" do

    test "set Hui.H parameters" do
      x = %Hui.H{
        encoder: nil,
        field: nil,
        fl: "title,words",
        fragsize: 250,
        highlightMultiTerm: nil,
        hl: true,
        maxAnalyzedChars: nil,
        method: nil,
        per_field: false,
        q: nil,
        qparser: nil,
        requireFieldMatch: nil,
        snippets: 3,
        "tag.post": nil,
        "tag.pre": nil,
        usePhraseHighlighter: true
      }
      assert x == %Hui.H{fl: "title,words", usePhraseHighlighter: true, fragsize: 250, snippets: 3}
    end

    test "set unified highlighter Hui.H1 parameters" do
      x = %Hui.H1{
        "bs.country": nil,
        "bs.language": nil,
        "bs.separator": nil,
        "bs.type": nil,
        "bs.variant": nil,
        defaultSummary: true,
        encoder: nil,
        field: nil,
        fl: "title,words",
        fragsize: nil,
        highlightMultiTerm: nil,
        hl: true,
        maxAnalyzedChars: nil,
        method: "unified",
        offsetSource: "POSTINGS",
        per_field: false,
        q: nil,
        qparser: nil,
        requireFieldMatch: nil,
        "score.b": nil,
        "score.k1": 0,
        "score.pivot": nil,
        snippets: nil,
        "tag.ellipsis": nil,
        "tag.post": nil,
        "tag.pre": nil,
        usePhraseHighlighter: nil
      }
      assert x == %Hui.H1{fl: "title,words", offsetSource: "POSTINGS", defaultSummary: true, "score.k1": 0}
    end

    test "set original highlighter Hui.H2 parameters" do
      x = %Hui.H2{
        alternateField: nil,
        encoder: nil,
        field: nil,
        fl: "features",
        formatter: nil,
        fragmenter: nil,
        fragsize: nil,
        highlightAlternate: nil,
        highlightMultiTerm: nil,
        hl: true,
        maxAlternateFieldLength: nil,
        maxAnalyzedChars: nil,
        maxMultiValuedToExamine: nil,
        maxMultiValuedToMatch: nil,
        mergeContiguous: true,
        method: "original",
        payloads: nil,
        per_field: false,
        preserveMulti: true,
        q: nil,
        qparser: nil,
        "regex.maxAnalyzedChars": nil,
        "regex.pattern": nil,
        "regex.slop": nil,
        requireFieldMatch: nil,
        "simple.post": "</b>",
        "simple.pre": "<b>",
        snippets: nil,
        "tag.post": nil,
        "tag.pre": nil,
        usePhraseHighlighter: nil
      }
      assert x == %Hui.H2{fl: "features", mergeContiguous: true, "simple.pre": "<b>", "simple.post": "</b>", preserveMulti: true}
    end

    test "set fastVector highlighter Hui.H3 parameters" do
      x = %Hui.H3{
        alternateField: nil,
        boundaryScanner: "breakIterator",
        "bs.chars": nil,
        "bs.country": "US", 
        "bs.language": "EN",
        "bs.maxScan": nil,
        "bs.type": "WORD",
        encoder: nil,
        field: nil,
        fl: "features",
        fragListBuilder: nil,
        fragmentsBuilder: nil,
        fragsize: nil,
        highlightAlternate: nil,
        highlightMultiTerm: nil,
        hl: true,
        maxAlternateFieldLength: nil,
        maxAnalyzedChars: nil,
        method: "fastVector",
        multiValuedSeparatorChar: nil,
        per_field: false,
        per_field_method: nil,
        phraseLimit: nil,
        q: nil,
        qparser: nil,
        requireFieldMatch: nil,
        "simple.post": nil,
        "simple.pre": nil,
        snippets: nil,
        "tag.post": nil,
        "tag.pre": nil,
        usePhraseHighlighter: nil
      }
      assert x == %Hui.H3{fl: "features", boundaryScanner: "breakIterator", "bs.type": "WORD", "bs.language": "EN", "bs.country": "US"}
    end

    test "can be encoded into URL query string" do
      x = %Hui.H{fl: "title,words", usePhraseHighlighter: true, fragsize: 250, snippets: 3}
      assert "hl.fl=title%2Cwords&hl.fragsize=250&hl=true&hl.snippets=3&hl.usePhraseHighlighter=true" = x |> Hui.URL.encode_query

      x = %Hui.H1{fl: "features", offsetSource: "POSTINGS", defaultSummary: true, "score.k1": 0}
      assert "hl.defaultSummary=true&hl.fl=features&hl=true&hl.method=unified&hl.offsetSource=POSTINGS&hl.score.k1=0" = x |> Hui.URL.encode_query

      x = %Hui.H2{fl: "features", mergeContiguous: true, "simple.pre": "<b>", "simple.post": "</b>", preserveMulti: true}
      assert "hl.fl=features&hl=true&hl.mergeContiguous=true&hl.method=original&hl.preserveMulti=true&hl.simple.post=%3C%2Fb%3E&hl.simple.pre=%3Cb%3E" = x |> Hui.URL.encode_query

      x = %Hui.H3{fl: "features", boundaryScanner: "breakIterator", "bs.type": "WORD", "bs.language": "EN", "bs.country": "US"}
      assert "hl.boundaryScanner=breakIterator&hl.bs.country=US&hl.bs.language=EN&hl.bs.type=WORD&hl.fl=features&hl=true&hl.method=fastVector" = x |> Hui.URL.encode_query
    end
  end

  describe "other structs" do

    test "set suggester Hui.S parameters" do
      x = %Hui.S{
        build: true,
        buildAll: nil,
        cfq: nil,
        count: 10,
        dictionary: ["name_infix", "surname_prefix"],
        q: "ha",
        reload: true,
        reloadAll: nil,
        suggest: true
      }
      assert x == %Hui.S{q: "ha", count: 10, dictionary: ["name_infix", "surname_prefix"], reload: true, build: true}
    end

    test "set spell checking Hui.Sp parameters" do
      x = %Hui.Sp{
        accuracy: nil,
        alternativeTermCount: nil,
        build: nil,
        collate: nil,
        collateExtendedResults: nil,
        collateMaxCollectDocs: nil,
        "collateParam.mm": nil,
        "collateParam.q.op": "AND",
        count: 10,
        dictionary: "default",
        extendedResults: nil,
        maxCollationEvaluations: nil,
        maxCollationTries: nil,
        maxCollations: nil,
        maxResultsForSuggest: nil,
        onlyMorePopular: nil,
        q: "delll ultra sharp",
        queryAnalyzerFieldtype: nil,
        reload: nil,
        shards: nil,
        "shards.qt": nil,
        spellcheck: true
      }
      assert x == %Hui.Sp{q: "delll ultra sharp", count: 10, "collateParam.q.op": "AND", dictionary: "default"}
    end

    test "set MoreLikeThis Hui.M parameters" do
      x = %Hui.M{
        boost: nil,
        count: 10,
        fl: "manu,cat",
        interestingTerms: nil,
        "match.include": true,
        "match.offset": nil,
        maxdf: nil,
        maxdfpct: nil,
        maxntp: nil,
        maxqt: nil,
        maxwl: nil,
        mindf: 10,
        mintf: 200,
        minwl: nil,
        mlt: true,
        qf: nil
      }
      assert x == %Hui.M{fl: "manu,cat", mindf: 10, mintf: 200, "match.include": true, count: 10}
    end

    test "Hui.S can be encoded into URL query string" do
      x = %Hui.S{q: "ha", count: 10, dictionary: ["name_infix", "surname_prefix"], reload: true, build: true}
      y = "suggest.build=true&suggest.count=10&suggest.dictionary=name_infix&suggest.dictionary=surname_prefix&suggest.q=ha&suggest.reload=true&suggest=true"
      assert y == x |> Hui.URL.encode_query
    end

    test "Hui.Sp can be encoded into URL query string" do
      x = %Hui.Sp{q: "delll ultra sharp", count: 10, "collateParam.q.op": "AND", dictionary: "default"}
      y = "spellcheck.collateParam.q.op=AND&spellcheck.count=10&spellcheck.dictionary=default&spellcheck.q=delll+ultra+sharp&spellcheck=true"
      assert y == x |> Hui.URL.encode_query
    end

    test "Hui.M can be encoded into URL query string" do
      x = %Hui.M{fl: "manu,cat", mindf: 10, mintf: 200, "match.include": true, count: 10}
      y = "mlt.count=10&mlt.fl=manu%2Ccat&mlt.match.include=true&mlt.mindf=10&mlt.mintf=200&mlt=true"
      assert y == x |> Hui.URL.encode_query
    end
  end

end