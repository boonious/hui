defmodule Hui.URL do
  @moduledoc """
  Struct and utilities for working with Solr URLs and parameters.

  Use the module `t:Hui.URL.t/0` struct to specify
  Solr core or collection URLs with request handlers.

  """

  defstruct [:url, handler: "select"]
  @type t :: %__MODULE__{url: nil | binary, handler: nil | binary}

  @doc """
  Returns any configured Solr url as `t:Hui.URL.t/0` struct.

  ```
      iex> Hui.URL.default_url!
      %Hui.URL{handler: "select", url: "http://localhost:8983/solr/gettingstarted"}
  ```

  A default URL may be specified in the application configuration as below:

  ```
    config hui, default_url,
      url: "http://localhost:8983/solr/gettingstarted",
      handler: "select" # optional
  ```

  - `url`: Typical Solr endpoint including the core or collection name. This could also be a load balancer
  endpoint fronting several upstream servers
  - `handler`: name of a handler that processes requests (per endpoint).


  """
  @spec default_url! :: t | nil
  def default_url! do
    {x, y} = {Application.get_env(:hui, :default_url)[:url], Application.get_env(:hui, :default_url)[:handler]}
    case {x,y} do
      {nil, nil} -> nil
      {nil, _} -> nil
      {_, nil} -> %Hui.URL{url: x}
      {_, _} -> %Hui.URL{url: x, handler: y}
    end
  end

  @doc """
  Encodes list (keywords) of Solr parameters into a query string.

  Some Solr parameters such as the filter query `fq`, `facet.field` can be set multiple times.
  These can be specified in a list (e.g. `fq: [filter1, filter]`). Dot-notated
  parameters (facet.field, hl.fl) can be specified with string keys, 
  e.g. `"facet.field": "type"`, `"hl.fl": "words"`.

  ## Example

      iex> Hui.URL.encode_query(q: "loch", start: 10, rows: 10)
      "q=loch&start=10&rows=10"

      iex> Hui.URL.encode_query(q: "loch", fq: ["type:image", "year:[2001 TO 2007]"])
      "q=loch&fq=type%3Aimage&fq=year%3A%5B2001+TO+2007%5D"

      iex> Hui.URL.encode_query(q: "loch", facet: true, "facet.field": ["type", "year"])
      "q=loch&facet=true&facet.field=type&facet.field=year"

      iex> Hui.URL.encode_query("not a valid parameter")
      ""

  """
  @spec encode_query(term) :: binary
  def encode_query(enumerable) when is_list(enumerable), do: Enum.map_join(enumerable, "&", &encode/1)
  def encode_query(_), do: ""

  @doc "Returns the string representation of the given `t:Hui.URL.t/0` struct."
  @spec to_string(t) :: binary
  def to_string(%__MODULE__{url: url, handler: handler}), do: "#{url}/#{handler}"

  defp encode({k,v}) when is_list(v), do: Enum.map_join(v, "&", &encode({k,&1}))
  defp encode({k,v}) when is_binary(v), do: "#{k}=#{URI.encode_www_form(v)}"
  defp encode({k,v}), do: "#{k}=#{v}"
  defp encode([]), do: ""
  defp encode(v), do: v

end
