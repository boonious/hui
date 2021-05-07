defmodule Hui.Utils do
  @moduledoc false

  import Hui.Guards
  alias Hui.Error

  @type url :: Hui.url()
  @type http_headers :: list
  @type http_options :: list

  @doc """
  Parses Solr endpoint in various formats into {url, headers, options} tuple
  for HTTP requests
  """
  @spec parse_endpoint(url) :: {:ok, {binary, http_headers, http_options}} | {:error, Error.t()}
  def parse_endpoint("http://" <> _rest = url), do: {:ok, {url, [], []}}
  def parse_endpoint("https://" <> _rest = url), do: {:ok, {url, [], []}}

  def parse_endpoint({url, headers}), do: parse_endpoint({url, headers, []})
  def parse_endpoint({url, headers, options}) when is_url(url, headers, options), do: {:ok, {url, headers, options}}

  def parse_endpoint(config_key) when is_atom(config_key) do
    config = Application.get_env(:hui, config_key) || []

    case config[:url] do
      url when is_url(url) ->
        config_map = Enum.into(config, %{})

        {
          :ok,
          {
            build_url(config_map),
            Map.get(config_map, :headers, []),
            Map.get(config_map, :options, [])
          }
        }

      _ ->
        {:error, %Error{reason: :nxdomain}}
    end
  end

  def parse_endpoint(_url), do: {:error, %Error{reason: :nxdomain}}

  defp build_url(%{url: url, collection: collection, handler: handler}), do: [url, "/", collection, "/", handler]
  defp build_url(%{url: url, collection: collection}), do: [url, "/", collection]
  defp build_url(%{url: url, handler: handler}), do: [url, "/", handler]
  defp build_url(%{url: url}), do: url

  @spec config_url(atom) :: binary
  def config_url(key) when is_atom(key) do
    config = Application.get_env(:hui, key)
    if config, do: config[:url], else: ""
  end
end
