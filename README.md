# Hui 辉 [![Build Status](https://api.travis-ci.com/boonious/hui.svg?branch=master)](https://travis-ci.com/github/boonious/hui) [![Hex pm](http://img.shields.io/hexpm/v/hui.svg?style=flat)](https://hex.pm/packages/hui) [![Coverage Status](https://coveralls.io/repos/github/boonious/hui/badge.svg?branch=master)](https://coveralls.io/github/boonious/hui?branch=master)

Hui 辉 ("shine" in Chinese) is a [Solr](http://lucene.apache.org/solr/) client and library for Elixir.

## Usage

Hui enables [Solr](http://lucene.apache.org/solr/) querying, updating and other forms of interaction
in [Elixir](https://elixir-lang.org) or [Phoenix](https://phoenixframework.org) applications.
Typical Solr data can be contained within a core (index) held on a single server or 
a data collection in distributed server architecture (cloud).

### Example - searching

```elixir
  import Hui
  
  # arbitrary keywords query against the default configured endpoint
  q("scott")
  q(q: "loch", rows: 5)
  
  # with query structs
  alias Hui.Query.{Standard,DisMax,Common,Facet,FacetRange,Suggest,MoreLikeThis,Highlight}

  url = "http://localhost:8983/solr/gettingstarted"
  search(url, [%Standard{q: "author:I*"}, %Facet{field: ["cat", "author_str"], mincount: 1}])

  # Suggester query, using `Hui.URL` struct
  suggester_url = %Hui.URL{url: "http://localhost:8983/solr/collection", handler: "suggest"}
  suggest_query = %Suggest{q: "ha", count: 10, dictionary: ["name_infix", "ln_prefix", "fn_prefix"]}
  suggest(suggester_url, suggest_query)

  # DisMax SolrCloud query
  x = %DisMax{q: "market", qf: "description^2.3 title", mm: "2<-25% 9<-3", pf: "title", ps: 1, qs: 3}
  y = %Common{collection: "library,commons", rows: 10, distrib: true, "shards.tolerant": true, "shards.info": true}
  z = %Facet{field: ["cat", "author_str"], mincount: 1}
  search(url, [x, y, z])

  # more elaborated faceting query
  range1 = %FacetRange{range: "price", start: 0, end: 100, gap: 10, per_field: true}
  range2 = %FacetRange{range: "popularity", start: 0, end: 5, gap: 1, per_field: true}
  z = %Facet{field: ["cat", "author_str"], mincount: 1, range: [range1, range2]}
  search(url, [x, y, z])

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
  search(url, "apache documentation", 1, 5, "stream_content_type_str:text/html", ["subject"])
  suggest(suggester_url, "ha", 5, ["name_infix", "ln_prefix", "fn_prefix"], "1939")
```

The `q` examples send requests to a `:default` configured endpoint (see `Configuration` below).
Query parameters could be a string, arbitrary keywords or
built-in query [structs](https://hexdocs.pm/hui/Hui.html#t:solr_struct/0) that
provide a structured way for invoking the comprehensive and powerful features of Solr.

See the [API reference](https://hexdocs.pm/hui/api-reference.html#content)
and [Solr reference guide](http://lucene.apache.org/solr/guide/searching.html)
for more details on available search parameters.

### Solr endpoints, HTTP headers and options
Solr endpoints and request handlers may be specified in multiple ways:

```elixir
  # URL binary string
  Hui.search("http://localhost:8983/solr/collection", q: "loch")

  # URL key referring to an endpoint in configuration - see "Configuration"
  Hui.search(:library, q: "edinburgh", rows: 10)

  # URL in a struct
  url = %Hui.URL{url: "http://localhost:8983/solr/collection", handler: "suggest"}
  Hui.search(url, %Hui.Query.Suggest{q: "el", dictionary: "mySuggester"})
```

HTTP headers and options can be specified via the `t:Hui.URL.t/0` struct.

```elixir
  # setting up a header and a 10s receiving connection timeout
  url = %Hui.URL{url: "..", headers: [{"accept", "application/json"}], options: [timeout: 10000]}
```

Headers and options for a specific endpoint may also be configured - see "Configuration".

### Example - updating

To add, update and delete Solr documents, as well as optimised search indexes:

```elixir
  # Specify an update handler endpoint for JSON-formatted update
  headers = [{"content-type", "application/json"}]
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

Advanced update requests may be issued using the
[`Hui.Query.Update`](https://hexdocs.pm/hui/Hui.Query.Update.html) struct, as well as through
any valid binary data encapsulating Solr documents and commands.

```elixir
  # url, doc1, doc2 from the above example
  ...

  # Hui.Query.Update struct commands for updating and committing the docs to Solr immediately

  alias Hui.Query.Update

  x = %Update{doc: [doc1, doc2], commit: true, waitSearcher: true}
  Hui.update(url, x)

  # Commits docs within 5 seconds
  x = %Update{doc: [doc1, doc2], commitWithin: 5000, overwrite: true}
  Hui.update(url, x)

  # Commit and optimise index
  Hui.update(url, %Update{commit: true, waitSearcher: true, optimize: true, maxSegments: 10})

  # Binary mode, e.g. delete a document via XML binary
  headers = [{"content-type", "application/xml"}]
  url = %Hui.URL{url: "http://localhost:8983/solr/collection", handler: "update", headers: headers}
  Hui.update(url, "<delete><id>9780141981727</id></delete>")
```

See [Solr reference](http://lucene.apache.org/solr/guide/uploading-data-with-index-handlers.html)
for more details on update commands, data types and formats.

### Software library

Hui [modules and data structures](https://hexdocs.pm/hui/api-reference.html#content) can be used for building Solr
application in Elixir and Phoenix. The query struct modules provide idiomatic and structured ways for
creating and encoding Solr parameters. For example, multiple filters and facet fields can be specified via list.
`fq: ["field1", "field2"]`, `field: ["field1", "field2"]`, `gap: 10` Elixir codes.

"Per-field" faceting can be specified in a succinct and unified
way, e.g. `gap` instead of the long-winded `f.[fieldname].facet.range.gap` (per field) or `facet.range.gap`
(single field). Per-field usage for a particular facet can be set or unset via the `per_field` key (example below).

`Hui.Encoder` protocol and `Hui.Encode` utility provide support for encoding query structs into binary and [IO data](#io-data-encoding) formats. A custom query struct may be developed by implementing the Encoder protocol.

```elixir
  alias Hui.Query.{Facet,FacetRange}

  %Facet{field: ["type", "year", "subject"], query: "edited:true"}
  |> Hui.Encoder.encode
  # -> "facet=true&facet.field=type&facet.field=year&facet.field=subject&facet.query=edited%3Atrue"
  # facet=true, facet prefixes are generated implicitly

  # a unified way to specify per-field or singe-field faceting
  x = %FacetRange{range: "age", gap: 10, start: 0, end: 100}
  x |> Hui.Encoder.encode
  # -> "facet.range.end=100&facet.range.gap=10&facet.range=age&facet.range.start=0"

 %{x | per_field: true} # toggle per field faceting
  |> Hui.Encoder.encode
  # -> "f.age.facet.range.end=100&f.age.facet.range.gap=10&facet.range=age&f.age.facet.range.start=0"
```

`Hui.Query.Update` struct enables
various JSON-formatted update and grouped commands to be generated.

```elixir
  alias Hui.Query.Update
  alias Hui.Encoder

  # doc1, doc2 are Maps of Solr documents
  x = %Update{doc: [doc1, doc2], commit: true, commitWithin: 1000}
  x |> Encoder.encode
  # -> "{\"add\":{\"commitWithin\":1000,\"doc\":{...}},\"add\":{\"commitWithin\":1000,\"doc\":{...}},\"commit\":{}}"

  # Delete the documents by ID
  %Update{delete_id: ["tt1316540", "tt1650453"]} |> Encoder.encode
  # -> "{\"delete\":{\"id\":\"tt1316540\"},\"delete\":{\"id\":\"tt1650453\"}}"
```

The structs and their associated type spec also provide binding to and introspection of available Solr parameters.

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

### IO data encoding
To leverage Erlang runtime and some HTTP client features for lower memory
usage and increased performance, `Hui.Encoder` provides functions to return either
string or [IO data](https://hexdocs.pm/elixir/IO.html#module-io-data)
which can be sent directly to IO functions or over the socket.

### Parsing Solr results

Solr results is returned encapsulated in `HTTP` response struct containing the Solr response.

```elixir
  {:ok,
   %Hui.Http{
    body: "...[Solr reponse]..",
    headers: [
      {"Content-Type", "application/json;charset=utf-8"},
      {"Content-Length", "4005"}
    ],
    method: :get,
    options: [], 
    status: 200,
    url: "http://localhost:8983/solr/gettingstarted/select?q=%2A"
   }
  }
```

JSON response is automatically parsed and decoded as map.
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
      {:hui, "~> 0.10.4"}
    ]
  end
```

Then run `$ mix deps.get`.

Documentation can be found at [https://hexdocs.pm/hui](https://hexdocs.pm/hui).

## Configuration

A default Solr endpoint may be specified in the application configuration. HTTP headers and options may also be configured.

```elixir
  config :hui, :default,
    url: "http://localhost:8983/solr/gettingstarted",
    handler: "select", # optional
    headers: [{"accept", "application/json"}]
    options: [timeout: 10000]
```

See `Hui.URL.default_url!/0` and `t:Hui.URL.t/0`.

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

### Using other HTTP clients

Hui relies on an existing client to facilitate HTTP requests - [Erlang httpc](https://erlang.org/doc/man/httpc.html).
Instead of using the built-in client, other HTTP clients can be implemented and configured.
See `Hui.Http` for further details.

## License

Hui is released under Apache 2 License. Check the [LICENSE](https://github.com/boonious/hui/blob/master/LICENSE) file for more information.
