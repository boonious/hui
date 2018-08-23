# Hui

Hui (辉 "shine" in Chinese) is an Elixir client and library for interfacing with Solr enterprise search platform

## Usage

### Other low-level HTTP client features

Under the hood, `Hui` uses `HTTPoison` - an HTTP client to interact with Solr.
The default low-level functions such as 
[get/3](https://hexdocs.pm/httpoison/HTTPoison.html#get/3)
of HTTPoison remains available via the Hui Module. 
For example, if needs be you could create a direct `get/3` request to a Solr endpoint
using the `params` option for query parameters: 

```
    iex> Hui.get("http://localhost:8983/solr/gettingstarted/select", [], params: [{"q", "*"}])
``` 

The request returns a `HTTPoison.Response` containing raw Solr response (body) that needs 
to be decoded accordingly using relevant parsers, e.g. `Poison` for JSON response.

```
    {:ok,
     %HTTPoison.Response{ 
      body: "...",
      headers: [
        {"Content-Type", "application/json;charset=utf-8"},
        {"Content-Length", "4005"}
      ],
      request_url: "http://localhost:8983/solr/gettingstarted/select?q=%2A",
      status_code: 200
     }
    }
```

See [HTTPoison](https://hexdocs.pm/httpoison/HTTPoison.html#content) module
and [HTTPoison.request/5](https://hexdocs.pm/httpoison/HTTPoison.html#request/5)
for more details on how to issue HTTP requests and other availlable options in addition 
to `params`.

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

