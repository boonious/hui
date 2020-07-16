defmodule Hui.URL do
  @moduledoc """
  Struct and utilities for working with Solr URLs and parameters.

  Use the module `t:Hui.URL.t/0` struct to specify
  Solr core or collection URLs with request handlers.

  ### Hui URL endpoints

  ```
    # binary
    url = "http://localhost:8983/solr/collection"
    Hui.search(url, q: "loch")

    # key referring to config setting
    url = :library
    Hui.search(url, q: "edinburgh", rows: 10)

    # Hui.URL struct
    url = %Hui.URL{url: "http://localhost:8983/solr/collection", handler: "suggest"}
    Hui.search(url, suggest: true, "suggest.dictionary": "mySuggester", "suggest.q": "el")

  ```

  `t:Hui.URL.t/0` struct also enables HTTP headers and options, e.g. [HTTPoison options](https://hexdocs.pm/httpoison/HTTPoison.html#request/5)
  to be specified in keyword lists. HTTPoison options provide further controls for a request, e.g. `timeout`, `recv_timeout`,
  `max_redirect`, `params` etc.

  ```
    # setting up a header and a 10s receiving connection timeout
    url = %Hui.URL{url: "..", headers: [{"accept", "application/json"}], options: [recv_timeout: 10000]}
    Hui.search(url, q: "solr rocks")
  ```
  """

  defstruct [:url, handler: "select", headers: [], options: []]
  @type headers :: [{binary(), binary()}]
  @type options :: Keyword.t

  @typedoc """
  Struct for a Solr endpoint with a request handler and any associated HTTP headers and options.

  ## Example

  ```
    %Hui.URL{handler: "suggest", url: "http://localhost:8983/solr/collection"}
  ```

  - `url`: typical endpoint including the core or collection name. This may also be a load balancer
  endpoint fronting several Solr upstreams.
  - `handler`: name of a Solr request handler that processes requests.
  - `headers`: HTTP headers.
  - `options`: e.g. [HTTPoison options](https://hexdocs.pm/httpoison/HTTPoison.html#request/5).

  """
  @type t :: %__MODULE__{url: nil | binary, handler: nil | binary, headers: nil | headers, options: nil | options}

  @typedoc """
  Solr parameters as keyword list or structs.
  """
  @type url_params :: Keyword.t | Hui.Q.t | Hui.D.t | Hui.F.t | Hui.F.Range.t | Hui.F.Interval.t

  @doc """
  Returns a configured default Solr endpoint as `t:Hui.URL.t/0` struct.

  ```
      Hui.URL.default_url!
      %Hui.URL{handler: "select", url: "http://localhost:8983/solr/gettingstarted", headers: [{"accept", "application/json"}], options: [recv_timeout: 10000]}
  ```
  The default endpoint can be specified in application configuration as below:

  ```
    config :hui, :default,
      url: "http://localhost:8983/solr/gettingstarted",
      handler: "select", # optional
      headers: [{"accept", "application/json"}],
      options: [recv_timeout: 10000]
  ```

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
      {nil, _} -> {:error, %Hui.Error{reason: :nxdomain}}
      {_, nil} -> {:ok, %Hui.URL{url: url, headers: headers, options: options}}
      {_, _} -> {:ok, %Hui.URL{url: url, handler: handler, headers: headers, options: options}}
    end
  end

  @doc "Returns the string representation (URL path) of the given `t:Hui.URL.t/0` struct."
  @spec to_string(t) :: binary
  defdelegate to_string(uri), to: String.Chars.Hui.URL
end

# implement `to_string` for %Hui.URL{} in Elixir generally via the String.Chars protocol
defimpl String.Chars, for: Hui.URL do
  def to_string(%Hui.URL{url: url, handler: handler}), do: [url, "/", handler] |> IO.iodata_to_binary
end
