# Hui 辉 [![Build Status](https://travis-ci.org/boonious/hui.svg?branch=master)](https://travis-ci.org/boonious/hui) [![Hex pm](http://img.shields.io/hexpm/v/hui.svg?style=flat)](https://hex.pm/packages/hui)
Hui 辉 ("shine" in Chinese) is a [Solr](http://lucene.apache.org/solr/) client and library for Elixir.

## Usage

Hui enables [Solr](http://lucene.apache.org/solr/) data querying and other forms of interaction (forthcoming)
in [Elixir](https://elixir-lang.org) or [Phoenix](https://phoenixframework.org) applications.
The data can be contained within a core (index) held on a single server or a data collection in distributed server architecture (cloud).

### Example

```elixir
  Hui.q("scott") # keywords search
  Hui.q(%Hui.Q{q: "loch", fq: ["type:illustration", "format:image/jpeg"]}) # structured query
  Hui.q(q: "loch", rows: 5, fq: ["type:illustration", "format:image/jpeg"])
```

The above queries a default Solr endpoint - see `Configuration` below.
A query may involve search words (string), a [Keyword list](https://elixir-lang.org/getting-started/keywords-and-maps.html#keyword-lists) or
built-in query [Structs](https://elixir-lang.org/getting-started/structs.html)
providing a structured way for invoking the comprehensive and powerful features of Solr.

Queries may also be issued to other specific endpoints and request handlers defined in various formats:

```elixir
  # URL binary string
  Hui.search("http://localhost:8983/solr/collection", q: "loch")

  # URL key referring to an endpoint in configuration - see "Configuration"
  url = :library
  Hui.search(url, q: "edinburgh", rows: 10)

  # URL in a struct
  url = %Hui.URL{url: "http://localhost:8983/solr/collection", handler: "suggest"}
  Hui.search(url, suggest: true, "suggest.dictionary": "mySuggester", "suggest.q": "el")
  # this -> http://http://localhost:8983/solr/collection/suggest?suggest=true&suggest.dictionary=mySuggester&suggest.q=el

```

See `Hui.search/2` in API reference and [Solr reference guide](http://lucene.apache.org/solr/guide/7_4/searching.html)
for more details on available search parameters.

### HTTP headers and options
HTTP headers and options can be specified via the `t:Hui.URL.t/0` struct.

```elixir
  # setting up a header and a 10s receiving connection timeout
  url = %Hui.URL{url: "..", headers: [{"accept", "application/json"}], options: [recv_timeout: 10000]}
  Hui.search(url, q: "solr rocks")
```

See `Hui.search/2` for more details. 

Headers and options for a specific endpoint may also be configured - see "Configuration".

### Software library

See [API reference](https://hexdocs.pm/hui/api-reference.html#content) for 
available modules and data structures which can also be used for developing Solr
search application in Elixir and Phoenix.

The following [structs](https://elixir-lang.org/getting-started/structs.html) modules
can be used to generate and encode Solr parameters in more **idiomatic** and **structured** ways.

- Standard and common query struct: `Hui.Q`
- Faceting struct: `Hui.F`, `Hui.F.Range`, `Hui.F.Interval`
- *structs for other request handlers are forthcoming*

For example, instead of prefixing and repeating `fq=filter`, `facet.field=fieldname`, `facet.range.gap=10`,
multiple filter and facet fields can be specified using
`fq: ["field1", "field2"]`, `field: ["field1", "field2"]`, `gap: 10` Elixir codes.

"Per-field" faceting for multiple ranges and intervals can be specified in a succinct and unified
way e.g. `gap` instead of the long-winded `f.[fieldname].facet.range.gap` (per field) or `facet.range.gap`
(single field range). Per-field use case for a facet can easily be set (or unset) through the `per_field`
field - see below.

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

The structs also provide a binding and introspection of available fields.

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

Hui returns Solr results as `HTTPoison.Response` struct which contains the Solr response (body).

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

JSON response is parsed and decoded as
[Map](https://elixir-lang.org/getting-started/keywords-and-maps.html#maps).
It is accessible via the `body` key.

```elixir
  {status, resp} = Hui.q(solr_params)

  # getting a list of Solr documents (in Map)
  solr_docs = resp.body["response"]["docs"]
  total_hits = resp.body["response"]["numFound"]
```

**Note**: for other response formats such as XML, raw response (text) is currently being returned.

### Other low-level HTTP client features

Under the hood, Hui uses `HTTPoison` - an HTTP client to interact with Solr.
The existing low-level functions of HTTPoison e.g. `get/1`, `get/3`
remain available in the `Hui.Search` module.

## Installation

Hui is [available in Hex](https://hex.pm/packages/hui), the package can be installed
by adding `hui` to your list of dependencies in `mix.exs`:

```elixir
  def deps do
    [
      {:hui, "~> 0.5.1"}
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

Use the config key in `Hui.search/2` to send queries to the endpoint or retrieve URL settings from configuration e.g. `Hui.URL.configured_url/1`.

## License

Hui is released under Apache 2 License. Check the [LICENSE](https://github.com/boonious/hui/blob/master/LICENSE) file for more information.
