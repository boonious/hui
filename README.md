# Hui 辉 [![Build Status](https://travis-ci.org/boonious/hui.svg?branch=master)](https://travis-ci.org/boonious/hui) [![Hex pm](http://img.shields.io/hexpm/v/hui.svg?style=flat)](https://hex.pm/packages/hui) [![Coverage Status](https://coveralls.io/repos/github/boonious/hui/badge.svg?branch=master)](https://coveralls.io/github/boonious/hui?branch=master)

Hui 辉 ("shine" in Chinese) is a [Solr](http://lucene.apache.org/solr/) client and library for Elixir.

## Usage

Hui enables [Solr](http://lucene.apache.org/solr/) querying, updating and other forms of interaction
in [Elixir](https://elixir-lang.org) or [Phoenix](https://phoenixframework.org) applications.
Typical Solr data can be contained within a core (index) held on a single server or 
a data collection in distributed server architecture (cloud).

### Example - searching

```elixir

  Hui.q("scott") # keywords search
  Hui.q(q: "loch", rows: 5) # arbitrary keyword list
  
  # with query structs
  alias Hui.Query

  Hui.q([%Query.Standard{q: "author:I*"}, %Query.Facet{field: ["cat", "author_str"], mincount: 1}])

  # `:library` is a URL reference key - see below
  Hui.search(:library, [%Qeury.Standard{q: "loch"}, %Query.Common{fq: ["type:illustration", "format:image/jpeg"]}])

  # Suggester query
  suggest_query = %Query.Suggest{q: "ha", count: 10, dictionary: ["name_infix", "ln_prefix", "fn_prefix"]}
  Hui.suggest(:library, suggest_query)

  # DisMax and SolrCloud query
  x = %Query.DisMax{q: "market", qf: "description^2.3 title", mm: "2<-25% 9<-3", pf: "title", ps: 1, qs: 3}
  y = %Query.Common{collection: "library,commons", rows: 10, distrib: true, "shards.tolerant": true, "shards.info": true}
  Hui.search(:library, [x, y])

  # with MoreLikeThis
  z = %Query.MoreLikeThis{fl: "manu,cat", mindf: 10, mintf: 200, "match.include": true, count: 10}
  Hui.search(:library, [x, y, z])

  # with faceting
  z = %Query.Facet{field: ["cat", "author_str"], mincount: 1}
  Hui.search(:library, [x, y, z])

  # with results highlighting
  z = %Query.Highlight{fl: "features", usePhraseHighlighter: true, fragsize: 250, snippets: 3 } 
  Hui.search(:library, [x, y, z])

  # more elaborated faceting query
  range1 = %Query.FacetRange{range: "price", start: 0, end: 100, gap: 10, per_field: true}
  range2 = %Query.FacetRange{range: "popularity", start: 0, end: 5, gap: 1, per_field: true}
  z = %Query.Facet{field: ["cat", "author_str"], mincount: 1, range: [range1, range2]}
  Hui.search(:library, [x, y, z])

  # the above spawns a request with the following query string
  #
  # q=...&
  # f.price.facet.range.end=100&
  # f.price.facet.range.gap=10&facet.range=price&
  # f.price.facet.range.start=0&
  # f.popularity.facet.range.end=5&
  # f.popularity.facet.range.gap=1&
  # facet.range=popularity&
  # f.popularity.facet.range.start=0

  # convenience functions
  Hui.search(:library, "apache documentation", 1, 5, "stream_content_type_str:text/html", ["subject"])
  Hui.suggest(:autocomplete, "ha", 5, ["name_infix", "ln_prefix", "fn_prefix"], "1939")

```

The `q` examples send requests to a `:default` configured endpoint (see `Configuration` below).
Query parameters could be a string,
a [Keyword list](https://elixir-lang.org/getting-started/keywords-and-maps.html#keyword-lists) or
built-in query [Structs](https://elixir-lang.org/getting-started/structs.html)
providing a structured way for invoking the comprehensive and powerful features of Solr.

Queries may also be issued to other endpoints and request handlers:

```elixir
  # URL binary string
  Hui.search("http://localhost:8983/solr/collection", q: "loch")

  # URL key referring to an endpoint in configuration - see "Configuration"
  url = :library
  Hui.search(url, q: "edinburgh", rows: 10)

  # URL in a struct
  url = %Hui.URL{url: "http://localhost:8983/solr/collection", handler: "suggest"}
  Hui.search(url, %Hui.Query.Suggest{q: "el", dictionary: "mySuggester"})
  # spawns => http://http://localhost:8983/solr/collection/suggest?suggest=true&suggest.dictionary=mySuggester&suggest.q=el

```

See the [API reference](https://hexdocs.pm/hui/api-reference.html#content)
and [Solr reference guide](http://lucene.apache.org/solr/guide/searching.html)
for more details on available search parameters.

### Example - updating

Hui provides functions to add, update and delete Solr documents, as well as optimised search indexes.

```elixir
  # Specify an update handler endpoint for JSON-formatted update
  headers = [{"Content-type", "application/json"}]
  url = %Hui.URL{url: "http://localhost:8983/solr/collection", handler: "update", headers: headers}

  # Solr documents
  doc1 = %{
    "actors" => ["Ingrid Bergman", "Liv Ullmann", "Lena Nyman", "Halvar Björk"],
    "desc" => "A married daughter who longs for her mother's love is visited by the latter, a successful concert pianist.",
    "directed_by" => ["Ingmar Bergman"],
    "genre" => ["Drama", "Music"],
    "id" => "tt0077711",
    "initial_release_date" => "1978-10-08",
    "name" => "Autumn Sonata"
  }
  doc2 = %{
    "actors" => ["Bibi Andersson", "Liv Ullmann", "Margaretha Krook"],
    "desc" => "A nurse is put in charge of a mute actress and finds that their personas are melding together.",
    "directed_by" => ["Ingmar Bergman"],
    "genre" => ["Drama", "Thriller"],
    "id" => "tt0060827",
    "initial_release_date" => "1967-09-21",
    "name" => "Persona"
  }

  # Add the docs and commit them to the index immediately
  Hui.update(url, [doc1, doc2])

  # Send documents to another pre-configured endpoint
  Hui.update(:updater, [doc1, doc2])

  Hui.delete(url, "tt0077711") # delete one doc
  Hui.delete(url, ["tt0077711", "tt0060827"]) # delete a list of docs
  Hui.delete_by_query(url, ["genre:Drama", "name:Persona"]) # delete via filter queries

```

More advanced update requests can be issued using `Request.update/3` with
a struct - [`Hui.U`](https://hexdocs.pm/hui/Hui.U.html), as well as through
any valid binary data encapsulating Solr documents and commands.

```elixir
  # Hui.U struct command for updating and committing the docs to Solr immediately
  x = %Hui.U{doc: [doc1, doc2], commit: true, waitSearcher: true}
  Hui.Request.update(url, x)

  # Commits docs within 5 seconds
  x = %Hui.U{doc: [doc1, doc2], commitWithin: 5000, overwrite: true}
  Hui.Request.update(url, x)

  # Commit and optimise index
  Hui.Request.update(url, %Hui.U{commit: true, waitSearcher: true, optimize: true, maxSegments: 10})

  # Binary mode, e.g. delete a document via XML binary
  headers = [{"Content-type", "application/xml"}]
  url = %Hui.URL{url: "http://localhost:8983/solr/collection", handler: "update", headers: headers}
  Hui.Request.update(url, "<delete><id>9780141981727</id></delete>")

```

See [Solr reference](http://lucene.apache.org/solr/guide/uploading-data-with-index-handlers.html)
for more details on update commands, data types and formats.

### HTTP headers and options
HTTP headers and options can be specified via the `t:Hui.URL.t/0` struct.

```elixir
  # setting up a header and a 10s receiving connection timeout
  url = %Hui.URL{url: "..", headers: [{"accept", "application/json"}], options: [recv_timeout: 10000]}
  Hui.search(url, q: "solr rocks")
```

Headers and options for a specific endpoint may also be configured - see "Configuration".

### Software library

Hui [modules and data structures](https://hexdocs.pm/hui/api-reference.html#content) can be used for building Solr
application in Elixir and Phoenix.

The following struct modules provide an **idiomatic** and **structured** way for
creating and encoding Solr parameters:

- Standard, DisMax, common query: `Hui.Query.Standard`, `Hui.Query.DisMax`, `Hui.Query.Common`
- Faceting: `Hui.Query.Facet`, `Hui.Query.FacetRange`, `Hui.Query.FacetInterval`
- Results Highlighting: `Hui.Query.Highlight`, `Hui.Query.HighlighterFastVector`, `Hui.Query.HighlighterOriginal`, `Hui.Query.HighlighterUnified`
- Others: `Hui.Query.SpellCheck`, `Hui.Query.Suggest` `Hui.Query.MoreLikeThis`
- Update (add/delete/commit/optimize data): `Hui.U`

For example, multiple filters and facet fields can be specified using
`fq: ["field1", "field2"]`, `field: ["field1", "field2"]`, `gap: 10` Elixir codes.

"Per-field" faceting for multiple ranges and intervals can be specified in a succinct and unified
way, e.g. `gap` instead of the long-winded `f.[fieldname].facet.range.gap` (per field) or `facet.range.gap`
(single field). Per-field use case for a facet can be set via the `per_field` key - see below.

Hui includes a [protocol](https://elixir-lang.org/getting-started/protocols.html) (with implementation):
- `Hui.Encoder` for encoding the query structs into binary (JSON format forthcoming)

A custom query struct may be developed by implementing the Encoder protocol.

```elixir
  alias Hui.Query
  x = %Query.DisMax{q: "loch"}
  y = %Query.Common{fq: ["type:image/jpeg", "year:2001"], fl: "id,title", rows: 20}
  [x,y] |> Hui.Encoder.encode
  # -> "q=loch&fl=id%2Ctitle&fq=type%3Aimage%2Fjpeg&fq=year%3A2001&rows=20"

  x = %Query.Facet{field: ["type", "year", "subject"], query: "edited:true"}
  x |> Hui.Encoder.encode
  # -> "facet=true&facet.field=type&facet.field=year&facet.field=subject&facet.query=edited%3Atrue"
  # there's no need to set "facet: true" as it is implied and a default setting in the struct

  # a unified way to specify per-field or singe-field range
  x = %Query.FacetRange{range: "age", gap: 10, start: 0, end: 100}
  x |> Hui.Encoder.encode
  # -> "facet.range.end=100&facet.range.gap=10&facet.range=age&facet.range.start=0"

  x = %{x | per_field: true} # toggle per field faceting
  x |> Hui.Encoder.encode
  # -> "f.age.facet.range.end=100&f.age.facet.range.gap=10&facet.range=age&f.age.facet.range.start=0"
```

The [`Hui.U`](https://hexdocs.pm/hui/Hui.U.html) struct module enables
various JSON-formatted update and grouped commands to be created.

```elixir
   # doc1, doc2 are Maps of Solr documents
   x = %Hui.U{doc: [doc1, doc2], commit: true, commitWithin: 1000}
   x |> Hui.U.encode
   # -> "{\"add\":{\"commitWithin\":1000,\"doc\":{...}},\"add\":{\"commitWithin\":1000,\"doc\":{...}},\"commit\":{}}"

   # Delete the documents by ID
   %Hui.U{delete_id: ["tt1316540", "tt1650453"]} |> Hui.U.encode
   # -> "{\"delete\":{\"id\":\"tt1316540\"},\"delete\":{\"id\":\"tt1650453\"}}"

```

The structs and their associated type spec also provide binding to and introspection of the available fields.

```elixir
  iex> %Hui.Query.Facet{field: ["type", "year"], query: "year:[2000 TO NOW]"}
  %Hui.Query.Facet{
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
  }
```

### Parsing Solr results

Hui returns Solr results as `HTTPoison.Response` struct containing the Solr response.

```elixir
  {:ok,
   %HTTPoison.Response{
    body: "...[Solr reponse]..",
    headers: [
      {"Content-Type", "application/json;charset=utf-8"},
      {"Content-Length", "4005"}
    ],
    request_url: "http://localhost:8983/solr/gettingstarted/select?q=%2A",
    status_code: 200
   }
  }
```

JSON response is automatically parsed and decoded as
[Map](https://elixir-lang.org/getting-started/keywords-and-maps.html#maps).
It is accessible via the `body` key.

```elixir
  {status, resp} = Hui.q(solr_params)

  # getting a list of Solr documents (Map)
  solr_docs = resp.body["response"]["docs"]
  total_hits = resp.body["response"]["numFound"]
```

**Note**: other response formats such as XML, are currently being returned in raw text.

## Installation

Hui is [available in Hex](https://hex.pm/packages/hui), the package can be installed
by adding `hui` to your list of dependencies in `mix.exs`:

```elixir
  def deps do
    [
      {:hui, "~> 0.9.0"}
    ]
  end
```

Then run `$ mix deps.get`.

Documentation can be found at [https://hexdocs.pm/hui](https://hexdocs.pm/hui).

## Configuration

A default Solr endpoint may be specified in the application configuration as below:

```elixir
  config :hui, :default,
    url: "http://localhost:8983/solr/gettingstarted",
    handler: "select", # optional
    headers: [{"accept", "application/json"}], # optional
    options: [recv_timeout: 10000] # optional
```

HTTP headers and options may also be configured.

See `Hui.URL.default_url!/0`.

Solr provides [various request
handlers](http://lucene.apache.org/solr/guide/7_4/overview-of-searching-in-solr.html#overview-of-searching-in-solr)
for many purposes (search, autosuggest, spellcheck, indexing etc.). The handlers are configured
in different custom or normative names in
[Solr configuration](http://lucene.apache.org/solr/guide/7_4/requesthandlers-and-searchcomponents-in-solrconfig.html#requesthandlers-and-searchcomponents-in-solrconfig),
e.g. "select" for search queries.

Additional endpoints and request handlers can be configured in Hui using arbitrary config keys (e.g. `:suggester`):

```elixir
  config :hui, :suggester,
    url: "http://localhost:8983/solr/collection",
    handler: "suggest"
```

Use the config key in functions such as `Hui.search/2`, `Hui.search/3` to send queries to the endpoint 
or retrieve URL settings from configuration e.g. `Hui.URL.configured_url/1`.

## License

Hui is released under Apache 2 License. Check the [LICENSE](https://github.com/boonious/hui/blob/master/LICENSE) file for more information.
