defmodule Hui.Utils.ParserTypeTest do
  use ExUnit.Case, async: true

  alias Hui.Query.Common
  alias Hui.Query.DisMax
  alias Hui.Query.Facet
  alias Hui.Utils.ParserType

  @json_parser Application.compile_env(:hui, :json_parser)

  describe "infer/1 parser type" do
    test "when query is commons struct" do
      assert @json_parser == ParserType.infer(%Common{wt: "json"})
      assert @json_parser == ParserType.infer(%Common{wt: nil})
      assert @json_parser == ParserType.infer(%Common{})

      # currently no parsers for other response formats, e.g. xml, cvs  
      assert nil == ParserType.infer(%Common{wt: "xml"})
      assert nil == ParserType.infer(%Common{wt: "csv"})
    end

    test "when query is other struct" do
      struct = %DisMax{
        q: "run",
        qf: "description^2.3 title",
        mm: "2<-25% 9<-3",
        pf: "title",
        ps: 1,
        qs: 3
      }

      # default parser
      assert @json_parser == ParserType.infer(struct)
    end

    test "when query is map" do
      assert @json_parser == ParserType.infer(%{wt: "json", start: 0, q: "search this"})
      assert @json_parser == ParserType.infer(%{start: 0, q: "search this"})

      assert nil == ParserType.infer(%{wt: "xml", start: 0, q: "search this"})
      assert nil == ParserType.infer(%{wt: "ruby", start: 0, q: "search this"})
    end

    test "when query is keyword" do
      assert @json_parser == ParserType.infer(wt: "json", start: 0, q: "search this")
      assert @json_parser == ParserType.infer(start: 0, wt: "json", q: "search this")
      assert @json_parser == ParserType.infer(start: 0, q: "search this", wt: "json")

      assert @json_parser == ParserType.infer(start: 0, q: "search this")
      assert nil == ParserType.infer(start: 0, wt: "xml", q: "search this")
      assert nil == ParserType.infer(start: 0, wt: "csv", q: "search this")
    end

    test "when query is a list query structs" do
      struct1 = %DisMax{
        q: "run",
        qf: "description^2.3 title",
        mm: "2<-25% 9<-3",
        pf: "title",
        ps: 1,
        qs: 3
      }

      struct2 = %Common{rows: 10, start: 10, fq: ["edited:true"]}
      struct3 = %Facet{field: ["cat", "author_str"], mincount: 1}

      assert @json_parser == ParserType.infer([struct1, struct2, struct3])
      assert @json_parser == ParserType.infer([struct2, struct1, struct3])
      assert @json_parser == ParserType.infer([struct1, struct3, struct2])

      assert @json_parser == ParserType.infer([struct1, %{struct2 | wt: "json"}, struct3])
      assert nil == ParserType.infer([struct1, %{struct2 | wt: "xml"}, struct3])
      assert nil == ParserType.infer([struct1, %{struct2 | wt: "php"}, struct3])
    end
  end
end
