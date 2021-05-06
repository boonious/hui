defmodule Hui.Utils do
  @moduledoc false

  import Hui.Guards
  alias Hui.Error

  @configured_url Application.get_all_env(:hui)
                  |> Enum.filter(fn {_k, v} -> is_list(v) and :url in Keyword.keys(v) end)
                  |> Enum.into(%{}, fn {k, v} -> {k, Enum.into(v, %{})} end)

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
    case @configured_url[config_key][:url] do
      url when is_url(url) ->
        {
          :ok,
          {
            build_url(@configured_url[config_key]),
            Map.get(@configured_url[config_key], :headers, []),
            Map.get(@configured_url[config_key], :options, [])
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
  def config_url(key) when is_atom(key), do: @configured_url[key][:url]
end
