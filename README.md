# Hui 辉 [![Build Status](https://travis-ci.org/boonious/hui.svg?branch=master)](https://travis-ci.org/boonious/hui) [![Hex pm](http://img.shields.io/hexpm/v/hui.svg?style=flat)](https://hex.pm/packages/hui) [![Coverage Status](https://coveralls.io/repos/github/boonious/hui/badge.svg?branch=master)](https://coveralls.io/github/boonious/hui?branch=master)

Hui 辉 ("shine" in Chinese) is a [Solr](http://lucene.apache.org/solr/) client and library for Elixir.

## Usage

Hui enables [Solr](http://lucene.apache.org/solr/) querying, updating and other forms of interaction (forthcoming)
in [Elixir](https://elixir-lang.org) or [Phoenix](https://phoenixframework.org) applications.
Typical Solr data can be contained within a core (index) held on a single server or 
a data collection in distributed server architecture (cloud).

### Example - searching

```elixir
  Hui.q("scott") # keywords search
  Hui.q(q: "loch", rows: 5) # arbitrary keyword list
  Hui.q(%Hui.Q{q: "loch", rows: 5, start: 20}) # structured query
  Hui.q([%Hui.Q{q: "author:I*", rows: 5}, %Hui.F{field: ["cat", "author_str"], mincount: 1}]) # with faceting
 
  # `:library` is a URL reference key - see below
  Hui.search(:library, %Hui.Q{q: "loch", fq: ["type:illustration", "format:image/jpeg"]})

  # SolrCloud query
  x = %Hui.Q{q: "john", collection: "library,commons", rows: 10, distrib: true, "shards.tolerant": true, "shards.info": true}
  Hui.search(:library, x)

  # Suggester query
  suggest_query = %Hui.S{q: "ha", count: 10, dictionary: ["name_infix", "ln_prefix", "fn_prefix"]}
  Hui.suggest(:library, suggest_query)

  # MoreLikeThis query
  query = %Hui.Q{q: "apache", rows: 10, wt: "xml"}
  mlt = %Hui.M{fl: "manu,cat", mindf: 10, mintf: 200, "match.include": true, count: 10}
  Hui.mlt(:library, query, mlt)

  # DisMax structured query via a list of existing Hui structs
  x = %Hui.D{q: "market", qf: "description^2.3 title", mm: "2<-25% 9<-3", pf: "title", ps: 1, qs: 3}
  y = %Hui.Q{rows: 10, start: 10, fq: ["edited:true"]}
  z = %Hui.F{field: ["cat", "author_str"], mincount: 1}
  Hui.search(:library, [x, y, z])

  # Add results highlighting (snippets) with `Hui.H`
  x = %Hui.Q{q: "features:photo", rows: 5}
  y = %Hui.H{fl: "features", usePhraseHighlighter: true, fragsize: 250, snippets: 3 } 
  Hui.search(:library, [x, y])

  # more elaborated faceting query
  x = %Hui.Q{q: "*", rows: 5}
  range1 = %Hui.F.Range{range: "price", start: 0, end: 100, gap: 10, per_field: true}
  range2 = %Hui.F.Range{range: "popularity", start: 0, end: 5, gap: 1, per_field: true}
  y = %Hui.F{field: ["cat", "author_str"], mincount: 1, range: [range1, range2]}
  Hui.search(:library, [x, y])
  # =>this spawns a request with the following query string
  #
  # q=%2A&rows=5&facet=true&facet.field=cat&
  # facet.field=author_str&facet.mincount=1&
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

The `q` examples queries a `:default` endpoint - see `Configuration` below.
Query parameters could be a string,
a [Keyword list](https://elixir-lang.org/getting-started/keywords-and-maps.html#keyword-lists) or
built-in query [Structs](https://elixir-lang.org/getting-started/structs.html)
providing a structured way for invoking the comprehensive and powerful features of Solr.

Queries may also be issued to other endpoints and request handlers:

```elixir
  # URL binary string
  Hui.search("http://localhost:8983/solr/collection", %Hui.Q{q: "loch"})

  # URL key referring to an endpoint in configuration - see "Configuration"
  url = :library
  Hui.search(url, q: "edinburgh", rows: 10)

  # URL in a struct
  url = %Hui.URL{url: "http://localhost:8983/solr/collection", handler: "suggest"}
  Hui.search(url, %Hui.S{q: "el", dictionary: "mySuggester"})
  # spawns => http://http://localhost:8983/solr/collection/suggest?suggest=true&suggest.dictionary=mySuggester&suggest.q=el

```

See the [API reference](https://hexdocs.pm/hui/api-reference.html#content)
and [Solr reference guide](http://lucene.apache.org/solr/guide/7_4/searching.html)
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

 # Delete docs by query
 Hui.Request.update(url, %Hui.U{delete_query: "name:Persona"})

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

- Standard and common query: `Hui.Q`
- DisMax query: `Hui.D`
- Faceting: `Hui.F`, `Hui.F.Range`, `Hui.F.Interval`
- Results highlighting: `Hui.H`, `Hui.H1`, `Hui.H2`, `Hui.H3`
- Misc: spell-checking `Hui.Sp`, suggester `Hui.S`, MoreLikeThis `Hui.M`
- Update (add/delete/commit/optimize data): `Hui.U`

For example, instead of prefixing and repeating `fq=filter`, `facet.field=fieldname`, `facet.range.gap=10`,
multiple filter and facet fields can be specified using
`fq: ["field1", "field2"]`, `field: ["field1", "field2"]`, `gap: 10` Elixir codes.

"Per-field" faceting for multiple ranges and intervals can be specified in a succinct and unified
way, e.g. `gap` instead of the long-winded `f.[fieldname].facet.range.gap` (per field) or `facet.range.gap`
(single field range). Per-field use case for a facet can easily be set (or unset) with the `per_field`
key - see below.

```elixir
  x = %Hui.Q{q: "loch", fq: ["type:image/jpeg", "year:2001"], fl: "id,title", rows: 20}
  x |> Hui.URL.encode_query
  # -> "fl=id%2Ctitle&fq=type%3Aimage%2Fjpeg&fq=year%3A2001&q=loch&rows=20"

  x = %Hui.F{field: ["type", "year", "subject"], query: "edited:true"}
  x |> Hui.URL.encode_query
  # -> "facet=true&facet.field=type&facet.field=year&facet.field=subject&facet.query=edited%3Atrue"
  # there's no need to set "facet: true" as it is implied and a default setting in the struct

  # a unified way to specify per-field or singe-field range
  x = %Hui.F.Range{range: "age", gap: 10, start: 0, end: 100}
  x |> Hui.URL.encode_query
  # -> "facet.range.end=100&facet.range.gap=10&facet.range=age&facet.range.start=0"

  x = %{x | per_field: true} # toggle per field faceting
  x |> Hui.URL.encode_query
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

The structs also provide binding to and introspection of the available fields.

```elixir
  iex> %Hui.F{field: ["type", "year"], query: "year:[2000 TO NOW]"}
  %Hui.F{
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

### Other low-level HTTP client features

Under the hood, Hui uses `HTTPoison` - an HTTP client to interact with Solr.
The existing low-level functions of HTTPoison e.g. `get/1`, `get/3`
remain available in the `Hui.Request` module.

## Installation

Hui is [available in Hex](https://hex.pm/packages/hui), the package can be installed
by adding `hui` to your list of dependencies in `mix.exs`:

```elixir
  def deps do
    [
      {:hui, "~> 0.8.1"}
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
