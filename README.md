# Hui 辉

Hui 辉 ("shine" in Chinese) is an [Elixir](https://elixir-lang.org) client and library for 
[Solr enterprise search platform](http://lucene.apache.org/solr/).

## Usage

A typical Hui use case is to provide search queries of a default Solr core or collection (distributed search data)
which may be configured as part of any [Elixir](https://elixir-lang.org) or
[Phoenix](https://phoenixframework.org) application - see `Configuration` below.

The query may involve a search string or a [keywords list](https://elixir-lang.org/getting-started/keywords-and-maps.html#keyword-lists) 
of Solr parameters, invoking the comprehensive and powerful search related
features of Solr such as faceting, highlighting and "more-like-this".

```
  Hui.search("scott")
  Hui.search(q: "loch", rows: 5, fq: ["type:illustration", "format:image/jpeg"])
```

See `Hui.search/1` and [Solr reference guide](http://lucene.apache.org/solr/guide/7_4/searching.html)
for more details on available search parameters. 

### Software library

See `API reference` for available modules which can be used for developing Solr 
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

If your application only provides services to a single Solr core or collection. 
A default URL may be specified in the application configuration as below:

  ```
    config hui, default_url,
      url: "http://localhost:8983/solr/gettingstarted",
      handler: "select" # optional
  ```

- `url`: Typical Solr endpoint including the core or collection name. This could also be a load balancer
endpoint fronting several upstream servers
- `handler`: name of a handler that processes requests (per endpoint).

Solr provides [a variety of request
handlers](http://lucene.apache.org/solr/guide/7_4/overview-of-searching-in-solr.html#overview-of-searching-in-solr)
for many purposes (search, autosuggest, spellcheck, indexing etc.). The handlers are configured
in different custom or normative names in
[Solr configuration](http://lucene.apache.org/solr/guide/7_4/requesthandlers-and-searchcomponents-in-solrconfig.html#requesthandlers-and-searchcomponents-in-solrconfig),
e.g. "select" for search queries.

Hui sends queries to the default URL if it exists (when none is supplied programmtically).

