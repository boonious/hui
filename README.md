# Hui 辉

Hui 辉 ("shine" in Chinese) is an Elixir client and library for
[Solr enterprise search platform](http://lucene.apache.org/solr/).

## Usage

Hui provides capability for any [Elixir](https://elixir-lang.org) or
[Phoenix](https://phoenixframework.org) application to query and interact with Solr data.
The data can be contained within a core (or index) held on a single server or a collection
which typically distributed across many servers.

### Example

```
  Hui.search("scott") # keywords search
  Hui.search(q: "loch", rows: 5, fq: ["type:illustration", "format:image/jpeg"])
```

The above queries the default Solr endpoint - see `Configuration` below.
A query may involves search words (string) or a [keywords list](https://elixir-lang.org/getting-started/keywords-and-maps.html#keyword-lists)
of Solr parameters, invoking the comprehensive and powerful features of Solr.

Queries may also be issued to other endpoints and request handlers, defined in binary or struct format:

```
  Hui.search("http://localhost:8983/solr/collection", q: "loch")
  
  url = %Hui.URL{url: "http://localhost:8983/solr/collection", handler: "suggest"}
  Hui.search(url, suggest: true, "suggest.dictionary": "mySuggester", "suggest.q": "el")
```

See `Hui.search/1`, `Hui.search/2` and [Solr reference guide](http://lucene.apache.org/solr/guide/7_4/searching.html)
for more details on available search parameters.

### Software library

See `API reference` for available modules which can also be used for developing Solr
search application in Elixir and Phoenix.

### Parsing Solr results

Hui currently returns Solr results as `HTTPoison.Response` struct which contains the raw Solr response (body).
**Note**: upcoming releases of Hui will provide features for parsing and working with response 
data in various formats.

```
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

```
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

```
  config :hui, :default_url,
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

Multiple endpoints with different Solr request handlers can be configured in Hui with an arbitrary config key (e.g. `:suggester`):

```
  config :hui, :suggester,
    url: "http://localhost:8983/solr/collection",
    handler: "suggest"
```

Use the config key in `Hui.search/2` to send queries to the endpoint or retrieve from configuration e.g. `Hui.URL.config_url(:suggester)`.
