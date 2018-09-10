defmodule Hui.URL do
  @moduledoc """
  Struct and utilities for working with Solr URLs and parameters.

  Use the module `t:Hui.URL.t/0` struct to specify
  Solr core or collection URLs with request handlers.

  """

  defstruct [:url, handler: "select", headers: [], options: []]
  @type headers :: HTTPoison.Base.headers
  @type options :: Keyword.t
  @type t :: %__MODULE__{url: nil | binary, handler: nil | binary, headers: nil | headers, options: nil | options}

  @doc """
  Returns a configured default Solr endpoint as `t:Hui.URL.t/0` struct.

      iex> Hui.URL.default_url!
      %Hui.URL{handler: "select", url: "http://localhost:8983/solr/gettingstarted", headers: [{"accept", "application/json"}], options: [recv_timeout: 10000]}

  The default endpoint can be specified in application configuration as below:

  ```
    config :hui, :default,
      url: "http://localhost:8983/solr/gettingstarted",
      handler: "select", # optional
      headers: [{"accept", "application/json"}],
      options: [recv_timeout: 10000]
  ```

  - `url`: typical endpoint including the core or collection name. This may also be a load balancer
  endpoint fronting several Solr upstreams.
  - `handler`: name of a request handler that processes requests.
  - `headers`: HTTP headers.
  - `options`: HTTPoison options.

  """
  @spec default_url! :: t | nil
  def default_url! do
    {status, default_url} = configured_url(:default)
    case status do
      :ok -> default_url
      :error -> nil
    end
  end

  @doc """
  Retrieve url configuration as `t:Hui.URL.t/0` struct.

  ## Example

      iex> Hui.URL.configured_url(:suggester)
      {:ok, %Hui.URL{handler: "suggest", url: "http://localhost:8983/solr/collection"}}

  The above retrieves the following endpoint configuration e.g. from `config.exs`:

  ```
    config :hui, :suggester,
      url: "http://localhost:8983/solr/collection",
      handler: "suggest"
  ```

  """
  @spec configured_url(atom) :: {:ok, t} | {:error, binary} | nil
  def configured_url(config_key) do
    url = Application.get_env(:hui, config_key)[:url]
    handler = Application.get_env(:hui, config_key)[:handler]
    headers = if Application.get_env(:hui, config_key)[:headers], do: Application.get_env(:hui, config_key)[:headers], else: []
    options = if Application.get_env(:hui, config_key)[:options], do: Application.get_env(:hui, config_key)[:options], else: []
    case {url,handler} do
      {nil, _} -> {:error, "URL not found in configuration"}
      {_, nil} -> {:ok, %Hui.URL{url: url, headers: headers, options: options}}
      {_, _} -> {:ok, %Hui.URL{url: url, handler: handler, headers: headers, options: options}}
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
  def encode_query(enumerable) when is_list(enumerable), do: Enum.reject(enumerable, &invalid_param?/1) |> Enum.map_join("&", &encode/1)
  def encode_query(_), do: ""

  @doc "Returns the string representation (URL path) of the given `t:Hui.URL.t/0` struct."
  @spec to_string(t) :: binary
  def to_string(%__MODULE__{url: url, handler: handler}), do: "#{url}/#{handler}"

  defp encode({k,v}) when is_list(v), do: Enum.reject(v, &invalid_param?/1) |> Enum.map_join("&", &encode({k,&1}))
  defp encode({k,v}) when is_binary(v), do: "#{k}=#{URI.encode_www_form(v)}"
  defp encode({k,v}), do: "#{k}=#{v}"
  defp encode([]), do: ""
  defp encode(v), do: v

  # kv pairs with empty, nil or [] values
  defp invalid_param?(""), do: true
  defp invalid_param?(nil), do: true
  defp invalid_param?([]), do: true
  defp invalid_param?(x) when is_tuple(x), do: is_nil(elem(x,1)) or elem(x,1) == "" or elem(x, 1) == [] or elem(x,0) == :__struct__
  defp invalid_param?(_x), do: false

end
