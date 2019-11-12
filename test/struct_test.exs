defmodule HuiStructTest do
  use ExUnit.Case, async: true
  doctest Hui.Q
  doctest Hui.F
  doctest Hui.F.Range
  doctest Hui.F.Interval
  doctest Hui.H
  doctest Hui.U

  alias Hui.Query
  alias Hui.Encoder

  describe "Standard, Common structs" do

    test "basic parameters setting" do
      x = %Hui.Query.Standard{ df: nil, q: "edinburgh", "q.op": nil, sow: nil }
      assert %Query.Standard{q: "edinburgh"} == x

      x = %Hui.Query.Standard{ q: "hui solr client" }
      assert x.q == "hui solr client"

      x = %Hui.Query.Standard{ q: "{!q.op=OR df=series_t}black amber" }
      assert x.q == "{!q.op=OR df=series_t}black amber"
    end

    test "SolrCloud parameters setting" do
      x = %Hui.Query.Common{
        _route_: nil,
        cache: nil,
        collection: "library,common",
        cursorMark: nil,
        debug: nil,
        "debug.explain.structured": nil,
        debugQuery: nil,
        defType: nil,
        distrib: true,
        "distrib.singlePass": nil,
        echoParams: nil,
        explainOther: nil,
        fl: nil,
        fq: [],
        "json.nl": nil,
        "json.wrf": nil,
        logParamsList: nil,
        omitHeader: nil,
        rows: nil,
        segmentTerminateEarly: nil,
        shards: "localhost:7574/solr/gettingstarted,localhost:8983/solr/gettingstarted",
        "shards.info": true,
        "shards.preference": nil,
        "shards.tolerant": true,
        sort: nil,
        start: nil,
        timeAllowed: nil,
        tr: nil,
        wt: nil
      }
      assert %Query.Common{
        collection: "library,common",
        distrib: true,
        "shards.tolerant": true,
        "shards.info": true,
        shards: "localhost:7574/solr/gettingstarted,localhost:8983/solr/gettingstarted"
      } == x
    end

    test "paging parameters setting" do
      x = %Query.Common{ cursorMark: "*", sort: "id asc" }
      assert x.cursorMark == "*"
      assert x.sort == "id asc"

      x = %Query.Common{ rows: 123, start: 200 }
      assert x.rows == 123
      assert x.start == 200
    end

  end

  describe "DisMax struct" do

    test "dismax parameters setting" do
      x = %Hui.Query.DisMax{
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
      assert %Hui.Query.DisMax{
        q: "edinburgh",
        qf: "description^2.3 title",
        mm: "2<-25% 9<-3",
        pf: "title",
        ps: 1,
        qs: 3,
        bq: "edited:true"
      } == x
    end

    test "extended dismax parameters setting" do
      x = %Hui.Query.DisMax{
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

      assert %Hui.Query.DisMax{
        sow: true,
        "mm.autoRelax": true,
        ps: 3,
        pf2: "description^2.3 title",
        uf: "title *_s"
      } == x
    end

  end

  describe "faceting structs" do

    test "Facet parameter setting" do
      assert %Query.Facet{
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
        pivot: nil,
        "pivot.mincount": nil,
        prefix: nil,
        query: "year:[2000 TO NOW]",
        range: nil,
        sort: nil,
        threads: nil
      } = %Query.Facet{field: ["type", "year"], query: "year:[2000 TO NOW]"}
    end

    test "FacetRange parameter setting" do
      assert %Hui.Query.FacetRange{
        per_field: false,
        range: "year",
        end: 1799,
        gap: "+10YEARS",
        hardend: nil,
        include: nil,
        method: nil,
        other: nil,
        start: 1700
      } == %Hui.Query.FacetRange{range: "year", gap: "+10YEARS", start: 1700, end: 1799}
    end

    test "FacetInterval parameter setting" do
      assert %Query.FacetInterval{
        interval: "price",
        set: ["[0,10]", "(10,100]"],
        per_field: false
      } == %Query.FacetInterval{interval: "price", set: ["[0,10]", "(10,100]"]}
    end

  end

  describe "result highlighting structs" do

    test "Highlight parameters setting" do
      x = %Query.Highlight{
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

      assert %Query.Highlight{fl: "title,words", usePhraseHighlighter: true, fragsize: 250, snippets: 3}
      == x
    end

    test "HighlighterUnified parameters setting" do
      x = %Query.HighlighterUnified{
            "bs.country": nil,
            "bs.language": nil,
            "bs.separator": nil,
            "bs.type": :SEPARATOR,
            "bs.variant": nil,
            defaultSummary: true,
            offsetSource: :POSTINGS,
            per_field: false,
            "score.b": nil,
            "score.k1": 0,
            "score.pivot": nil,
            "tag.ellipsis": nil,
            weightMatches: true
          }

      assert %Query.HighlighterUnified{offsetSource: :POSTINGS, defaultSummary: true, "score.k1": 0, "bs.type": :SEPARATOR, weightMatches: true}  
      == x
    end

    test "HighlighterOriginal parameters setting " do
      x = %Hui.Query.HighlighterOriginal{
        alternateField: nil,
        formatter: nil,
        fragmenter: nil,
        highlightAlternate: nil,
        maxAlternateFieldLength: nil,
        maxMultiValuedToExamine: nil,
        maxMultiValuedToMatch: nil,
        mergeContiguous: true,
        payloads: nil,
        per_field: false,
        preserveMulti: true,
        "regex.maxAnalyzedChars": nil,
        "regex.pattern": nil,
        "regex.slop": nil,
        "simple.post": "</b>",
        "simple.pre": "<b>"
      }

      assert x == %Query.HighlighterOriginal{mergeContiguous: true, "simple.pre": "<b>", "simple.post": "</b>", preserveMulti: true}
    end

    test "HighlighterFastVector parameters setting" do
      x = %Query.HighlighterFastVector{
        alternateField: nil,
        boundaryScanner: "breakIterator",
        "bs.chars": nil,
        "bs.country": "US",
        "bs.language": "EN",
        "bs.maxScan": nil,
        "bs.type": "WORD",
        fragListBuilder: nil,
        fragmentsBuilder: nil,
        highlightAlternate: nil,
        maxAlternateFieldLength: nil,
        multiValuedSeparatorChar: nil,
        per_field: false,
        phraseLimit: nil
      }

      assert x == %Query.HighlighterFastVector{boundaryScanner: "breakIterator", "bs.type": "WORD", "bs.language": "EN", "bs.country": "US"}
    end
  end

  describe "other query structs" do

    test "Suggest parameters setting" do
      x = %Query.Suggest{
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

      assert x == %Query.Suggest{q: "ha", count: 10, dictionary: ["name_infix", "surname_prefix"], reload: true, build: true}
    end

    test "SpellCheck parameters setting" do
      x = %Query.SpellCheck{
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

      assert x == %Query.SpellCheck{q: "delll ultra sharp", count: 10, "collateParam.q.op": "AND", dictionary: "default"}
    end

    test "MoreLikeThis parameters setting" do
      x = %Query.MoreLikeThis{
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

      assert x == %Query.MoreLikeThis{fl: "manu,cat", mindf: 10, mintf: 200, "match.include": true, count: 10}
    end
  end

  describe "update struct" do

    test "should encode a single doc" do
      update_doc =  File.read!("./test/data/update_doc2.json") |> Poison.decode!
      doc_map = update_doc["add"]["doc"]
      expected_data = update_doc |> Poison.encode!

      x = %Query.Update{doc: doc_map}
      assert Encoder.encode(x) == expected_data
    end

    test "should encode multiple docs" do
      doc_map1 = %{
        "actor_ss" => ["János Derzsi", "Erika Bók", "Mihály Kormos", "Ricsi"],
        "desc" => "A rural farmer is forced to confront the mortality of his faithful horse.",
        "directed_by" => ["Béla Tarr", "Ágnes Hranitzky"],
        "genre" => ["Drama"],
        "id" => "tt1316540",
        "initial_release_date" => "2011-03-31",
        "name" => "The Turin Horse"
      }
      doc_map2 = %{
        "actor_ss" => ["Masami Nagasawa", "Hiroshi Abe", "Kanna Hashimoto",
         "Yoshio Harada"],
        "desc" => "Twelve-year-old Koichi, who has been separated from his brother Ryunosuke due to his parents' divorce, hears a rumor that the new bullet trains will precipitate a wish-granting miracle when they pass each other at top speed.",
        "directed_by" => ["Hirokazu Koreeda"],
        "genre" => ["Drame"],
        "id" => "tt1650453",
        "initial_release_date" => "2011-06-11",
        "name" => "I Wish"
      }

      x = %Query.Update{doc: [doc_map1, doc_map2]}
      assert Encoder.encode(x) == File.read!("./test/data/update_doc3.json")
    end

    test "should encode doc with commitWithin and overwrite parameters" do
      expected_data =  File.read!("./test/data/update_doc4.json")
      update_doc = expected_data |> Poison.decode!
      doc_map = update_doc["add"]["doc"]

      x = %Query.Update{doc: doc_map, commitWithin: 5000}
      assert Encoder.encode(x) == expected_data

      x = %Query.Update{doc: doc_map, commitWithin: 10, overwrite: true}
      assert Encoder.encode(x) == File.read!("./test/data/update_doc5.json")

      x = %Query.Update{doc: doc_map, overwrite: false}
      assert Encoder.encode(x) == File.read!("./test/data/update_doc6.json")
    end

    test "should encode multiple docs with commitWithin and overwrite parameters" do
      expected_data = File.read!("./test/data/update_doc8.json")
      doc_map1 = %{
        "actor_ss" => ["Ingrid Bergman", "Liv Ullmann", "Lena Nyman", "Halvar Björk"],
        "desc" => "A married daughter who longs for her mother's love is visited by the latter, a successful concert pianist.",
        "directed_by" => ["Ingmar Bergman"],
        "genre" => ["Drama", "Music"],
        "id" => "tt0077711",
        "initial_release_date" => "1978-10-08",
        "name" => "Autumn Sonata"
      }
      doc_map2 = %{
        "actor_ss" => ["Bibi Andersson", "Liv Ullmann", "Margaretha Krook"],
        "desc" => "A nurse is put in charge of a mute actress and finds that their personas are melding together.",
        "directed_by" => ["Ingmar Bergman"],
        "genre" => ["Drama", "Thriller"],
        "id" => "tt0060827",
        "initial_release_date" => "1967-09-21",
        "name" => "Persona"
      }

      x = %Query.Update{doc: [doc_map1, doc_map2], commitWithin: 50, overwrite: true}
      assert Encoder.encode(x) == expected_data
    end

    test "should encode commit command with waitSearcher and expungeDeletes parameters" do
       x = %Query.Update{commit: true}
       assert x |> Encoder.encode == "{\"commit\":{}}"

       x = %Query.Update{commit: true, waitSearcher: true}
       assert x |> Encoder.encode == "{\"commit\":{\"waitSearcher\":true}}"

       x = %Query.Update{commit: true, waitSearcher: false}
       assert x |> Encoder.encode == "{\"commit\":{\"waitSearcher\":false}}"

       x = %Query.Update{commit: true, expungeDeletes: true}
       assert x |> Encoder.encode == "{\"commit\":{\"expungeDeletes\":true}}"

       x = %Query.Update{commit: true, waitSearcher: true, expungeDeletes: false}
       assert x |> Encoder.encode == "{\"commit\":{\"waitSearcher\":true,\"expungeDeletes\":false}}"
    end

    test "should encode optimize command with waitSearcher and maxSegment parameters" do
       x = %Query.Update{optimize: true}
       assert x |> Encoder.encode == "{\"optimize\":{}}"

       x = %Query.Update{optimize: true, waitSearcher: true}
       assert x |> Encoder.encode == "{\"optimize\":{\"waitSearcher\":true}}"

       x = %Query.Update{optimize: true, waitSearcher: false}
       assert x |> Encoder.encode == "{\"optimize\":{\"waitSearcher\":false}}"

       x = %Query.Update{optimize: true, maxSegments: 20}
       assert x |> Encoder.encode == "{\"optimize\":{\"maxSegments\":20}}"

       x = %Query.Update{optimize: true, waitSearcher: true, maxSegments: 20}
       assert x |> Encoder.encode == "{\"optimize\":{\"waitSearcher\":true,\"maxSegments\":20}}"
    end
 
    test "should encode delete by ID command" do
       x = %Query.Update{delete_id: "tt1316540"}
       assert x |> Encoder.encode == "{\"delete\":{\"id\":\"tt1316540\"}}"
       
       x = %Query.Update{delete_id: ["tt1316540", "tt1650453"]}
       assert x |> Encoder.encode == "{\"delete\":{\"id\":\"tt1316540\"},\"delete\":{\"id\":\"tt1650453\"}}"
    end

    test "should encode delete by query command" do
       x = %Query.Update{delete_query: "name:Persona"}
       assert x |> Encoder.encode == "{\"delete\":{\"query\":\"name:Persona\"}}"

       x = %Query.Update{delete_query: ["name:Persona", "genre:Drama"]}
       assert x |> Encoder.encode == "{\"delete\":{\"query\":\"name:Persona\"},\"delete\":{\"query\":\"genre:Drama\"}}"
    end

    test "should encode multiple grouped update commands (docs, commit, optimize etc.)" do
     doc_map1 = %{
       "actor_ss" => ["Ingrid Bergman", "Liv Ullmann", "Lena Nyman", "Halvar Björk"],
       "desc" => "A married daughter who longs for her mother's love is visited by the latter, a successful concert pianist.",
       "directed_by" => ["Ingmar Bergman"],
       "genre" => ["Drama", "Music"],
       "id" => "tt0077711",
       "initial_release_date" => "1978-10-08",
       "name" => "Autumn Sonata"
     }
     doc_map2 = %{
       "actor_ss" => ["Bibi Andersson", "Liv Ullmann", "Margaretha Krook"],
       "desc" => "A nurse is put in charge of a mute actress and finds that their personas are melding together.",
       "directed_by" => ["Ingmar Bergman"],
       "genre" => ["Drama", "Thriller"],
       "id" => "tt0060827",
       "initial_release_date" => "1967-09-21",
       "name" => "Persona"
     }

     x = %Query.Update{doc: [doc_map1, doc_map2], commitWithin: 50, overwrite: true}
     x = %Query.Update{x | commit: true, waitSearcher: true, expungeDeletes: false, optimize: true, maxSegments: 20}
     x = %Query.Update{x | delete_id: ["tt1316540", "tt1650453"]}
     assert x |> Encoder.encode == File.read!("./test/data/update_doc10.json")
    end

    test "should encode rollback command" do
       x = %Query.Update{rollback: true}
       assert x |> Encoder.encode == "{\"rollback\":{}}"

       x = %Query.Update{rollback: true, delete_query: "name:Persona"}
       assert x |> Encoder.encode == "{\"delete\":{\"query\":\"name:Persona\"},\"rollback\":{}}"
    end

  end

end