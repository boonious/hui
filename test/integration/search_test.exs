for client <- Hui.Http.Client.all_clients() do
  test_module = Module.concat(client, Integration.SearchTest)

  defmodule test_module do
    @moduledoc """
    Integration tests for searching involving #{client}
    """

    use ExUnit.Case, async: true

    alias Hui.Http
    alias Hui.Query

    @moduletag :integration

    @endpoint Application.compile_env(:hui, :test_url)
    @client client |> Module.split() |> List.last()

    setup do
      %{http_client: unquote(client)}
    end

    describe "#{@client} search/3" do
      test "keyword list query", %{http_client: client} do
        query = [q: "*", rows: 10, fq: ["cat:electronics"]]
        query_string = query |> Hui.Encoder.encode()

        assert {:ok, %Http{body: body, status: 200, url: url}} = Hui.search(@endpoint, query, client)
        assert url |> IO.iodata_to_binary() =~ [@endpoint, "?", query_string] |> IO.iodata_to_binary()

        assert %{
                 "response" => %{"docs" => docs, "numFound" => hits, "start" => 0},
                 "responseHeader" => %{"params" => params}
               } = body

        assert length(docs) == 10
        assert hits > 0
        assert params == %{"fq" => "cat:electronics", "q" => "*", "rows" => "10"}

        assert is_integer(hd(docs)["_version_"])
        assert "electronics" in hd(docs)["cat"]
      end

      test "structs query", %{http_client: client} do
        x = %Query.Common{
          rows: 5,
          fq: ["cat:book", "inStock:true", "price:[1.99 TO 9.99]"],
          cursorMark: "*",
          sort: "id asc"
        }

        y = %Query.Standard{q: "{!q.op=OR df=series_t}black amber"}

        query_string = [x, y] |> Hui.Encoder.encode()

        assert {:ok, %Http{body: body, status: 200, url: url}} = Hui.search(@endpoint, [x, y], client)
        assert url |> IO.iodata_to_binary() =~ [@endpoint, "?", query_string] |> IO.iodata_to_binary()

        assert %{"response" => %{"numFound" => hits, "start" => 0}, "responseHeader" => %{"params" => params}} = body
        assert hits > 0

        assert params == %{
                 "q" => "{!q.op=OR df=series_t}black amber",
                 "fq" => ["cat:book", "inStock:true", "price:[1.99 TO 9.99]"],
                 "rows" => "5",
                 "cursorMark" => "*",
                 "sort" => "id asc"
               }
      end

      test "DisMax struct query", %{http_client: client} do
        query = %Query.DisMax{
          q: "game george",
          qf: "name^2.3 author",
          mm: "2",
          pf: "name",
          ps: 1,
          qs: 3
        }

        query_string = query |> Hui.Encoder.encode()

        assert {:ok, %Http{body: body, status: 200, url: url}} = Hui.search(@endpoint, query, client)
        assert url |> IO.iodata_to_binary() =~ [@endpoint, "?", query_string] |> IO.iodata_to_binary()
        assert %{"response" => %{"numFound" => hits, "start" => 0}, "responseHeader" => %{"params" => params}} = body
        assert hits > 0

        assert params == %{
                 "defType" => "dismax",
                 "mm" => "2",
                 "pf" => "name",
                 "ps" => "1",
                 "q" => "game george",
                 "qf" => "name^2.3 author",
                 "qs" => "3"
               }
      end

      # use Bypass for now until a test cluster is available
      test "SolrCloud struct query", %{http_client: client} do
        bypass = Bypass.open()
        endpoint = "http://localhost:#{bypass.port}/select"
        Bypass.expect_once(bypass, fn conn -> Plug.Conn.resp(conn, 200, "") end)

        query = %Query.Common{
          distrib: true,
          "shards.tolerant": true,
          "shards.info": true,
          collection: "library,common"
        }

        query_string = query |> Hui.Encoder.encode()

        assert {:ok, %Http{body: body, status: 200, url: url}} = Hui.search(endpoint, query, client)
        assert url |> IO.iodata_to_binary() =~ [endpoint, "?", query_string] |> IO.iodata_to_binary()
      end

      test "faceting", %{http_client: client} do
        x = %Query.Standard{q: "author:I*"}
        y = %Query.Common{rows: 5, echoParams: "explicit"}
        z = %Query.Facet{field: ["cat", "author_str"], mincount: 1}

        query_string = [x, y, z] |> Hui.Encoder.encode()

        assert {:ok, %Http{body: body, status: 200, url: url}} = Hui.search(@endpoint, [x, y, z], client)
        assert url |> IO.iodata_to_binary() =~ [@endpoint, "?", query_string] |> IO.iodata_to_binary()
        assert %{"response" => %{"numFound" => hits, "start" => 0}, "responseHeader" => %{"params" => params}} = body
        assert hits > 0

        assert %{
                 "facet_counts" => %{
                   "facet_fields" => %{
                     "author_str" => ["Isaac Asimov", 1],
                     "cat" => ["book", 1]
                   }
                 }
               } = body

        assert params == %{
                 "q" => "author:I*",
                 "echoParams" => "explicit",
                 "facet" => "true",
                 "facet.field" => ["cat", "author_str"],
                 "facet.mincount" => "1",
                 "rows" => "5"
               }
      end

      test "highlighting", %{http_client: client} do
        x = %Query.Standard{q: "features:photo"}
        y = %Query.Highlight{fl: "features", usePhraseHighlighter: true, fragsize: 250, snippets: 3}

        query_string = [x, y] |> Hui.Encoder.encode()

        assert {:ok, %Http{body: body, status: 200, url: url}} = Hui.search(@endpoint, [x, y], client)
        assert url |> IO.iodata_to_binary() =~ [@endpoint, "?", query_string] |> IO.iodata_to_binary()
        assert %{"response" => %{"numFound" => hits, "start" => 0}, "responseHeader" => %{"params" => params}} = body
        assert hits > 0

        assert %{
                 "highlighting" => %{
                   "0579B002" => %{
                     "features" => ["Multifunction ink-jet color <em>photo</em> printer"]
                   },
                   "MA147LL/A" => %{
                     "features" => [
                       "Notes, Calendar, Phone book, Hold button, Date display, <em>Photo</em> wallet, Built-in games, JPEG <em>photo</em> playback, Upgradeable firmware, USB 2.0 compatibility, Playback speed control, Rechargeable capability, Battery level indication"
                     ]
                   }
                 }
               } = body

        assert params == %{
                 "q" => "features:photo",
                 "hl" => "true",
                 "hl.fl" => "features",
                 "hl.fragsize" => "250",
                 "hl.snippets" => "3",
                 "hl.usePhraseHighlighter" => "true"
               }
      end

      # need to test other highlighting, spellchecking, MLT
    end
  end
end
