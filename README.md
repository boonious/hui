# Hui 辉

Hui 辉 ("shine" in Chinese) is a [Solr](http://lucene.apache.org/solr/) client and library for Elixir.

## Usage

Hui enables [Solr](http://lucene.apache.org/solr/) data querying and other forms of interaction (forthcoming)
in [Elixir](https://elixir-lang.org) or [Phoenix](https://phoenixframework.org) applications.
The data can be contained within a core (index) held on a single server or a data collection in distributed server architecture (cloud).

### Example

```elixir
  Hui.q("scott") # keywords search
  Hui.q(q: "loch", rows: 5, fq: ["type:illustration", "format:image/jpeg"])
```

The above queries a default Solr endpoint - see `Configuration` below.
A query may involve search words (string) or a [Keyword list](https://elixir-lang.org/getting-started/keywords-and-maps.html#keyword-lists)
of Solr parameters, invoking the comprehensive and powerful features of Solr.

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

### Software library

See `API reference` for available modules which can also be used for developing Solr
search application in Elixir and Phoenix.

### Parsing Solr results

Hui currently returns Solr results as `HTTPoison.Response` struct which contains the raw Solr response (body).
**Note**: upcoming releases of Hui will provide features for parsing and working with response 
data in various formats.

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
The response needs to be decoded accordingly using relevant parsers such as `Poison` for JSON response.

```elixir
  {status, resp} = Hui.search(solr_params)
  solr_response = resp.body |> Poison.decode!
```

### Other low-level HTTP client features

Under the hood, Hui uses `HTTPoison` - an HTTP client to interact with Solr.
The existing low-level functions of HTTPoison e.g. `get/1`, `get/3`
remain available in the `Hui.Search` module.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `hui` to your list of dependencies in `mix.exs`:

```elixir
  def deps do
    [
      {:hui, "~> 0.1.0"}
    ]
  end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/hui](https://hexdocs.pm/hui).

## Configuration

A default Solr endpoint may be specified in the application configuration as below:

```elixir
  config :hui, :default,
    url: "http://localhost:8983/solr/gettingstarted",
    handler: "select" # optional
```

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
