# Hui 辉 [![Build Status](https://travis-ci.org/boonious/hui.svg?branch=master)](https://travis-ci.org/boonious/hui) [![Hex pm](http://img.shields.io/hexpm/v/hui.svg?style=flat)](https://hex.pm/packages/hui)
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

Headers and options for a specific endpoint may also be configured - see "Configuration".

### Software library

See `API reference` for available modules which can also be used for developing Solr
search application in Elixir and Phoenix.

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
      {:hui, "~> 0.4.2"}
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
