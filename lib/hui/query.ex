defmodule Hui.Query do
  @moduledoc """

  Hui.Query module provides underpinning HTTP-based request functions for Solr, including:

  - `get/2`, `get!/2`
  - `post/2`, `post!/2`
  """

  import Hui.Http

  alias Hui.Http
  alias Hui.URL
  alias Hui.Encoder
  alias Hui.Query

  @type querying_struct :: Query.Standard.t() | Query.Common.t() | Query.DisMax.t()
  @type faceting_struct :: Query.Facet.t() | Query.FacetRange.t() | Query.FacetInterval.t()
  @type highlighting_struct ::
          Query.Highlight.t()
          | Query.HighlighterUnified.t()
          | Query.HighlighterOriginal.t()
          | Query.HighlighterFastVector.t()

  @type misc_struct :: Query.MoreLikeThis.t() | Query.Suggest.t() | Query.SpellCheck.t()
  @type solr_struct :: querying_struct | faceting_struct | highlighting_struct | misc_struct

  @type solr_query :: Keyword.t() | map | solr_struct | [solr_struct]
  @type solr_update_query :: binary | Query.Update.t()
  @type solr_url :: Hui.URL.t()

  @doc """
  Issues a get request of Solr query to a specific endpoint.

  The query can be a keyword list or a list of Hui query structs (`t:solr_query/0`).

  ## Example - parameters

  ```
    url = %Hul.URL{url: "http://..."}

    # query via a list of keywords, which are unbound and sent to Solr directly
    Hui.Query.get(url, q: "glen cova", facet: "true", "facet.field": ["type", "year"])

    # query via Hui structs
    alias Hui.Query
    Hui.Query.get(url, %Query.DisMax{q: "glen cova"})
    Hui.Query.get(url, [%Query.DisMax{q: "glen"}, %Query.Facet{field: ["type", "year"]}])
  ```

  The use of structs is more idiomatic and succinct. It is bound to qualified Solr fields.

  See `t:Hui.URL.t/0` struct about specifying HTTP headers and HTTPoison options
  of a request, e.g. `timeout`, `recv_timeout`, `max_redirect` etc.
  """
  @spec get(solr_url, solr_query) :: {:ok, HTTPoison.Response.t()} | {:error, HTTPoison.Error.t()}
  def get(%URL{} = solr_url, solr_query) do
    %Http{
      url: [to_string(solr_url), "?", Encoder.encode(solr_query)] |> IO.iodata_to_binary(),
      headers: solr_url.headers,
      options: solr_url.options
    }
    |> get()
  end

  @doc """
  Issues a get request of Solr query to a specific endpoint, raising an exception in case of failure.

  If the request does not fail, the response is returned.

  See `get/2` for more detailed information.
  """
  @spec get!(solr_url, solr_query) :: HTTPoison.Response.t()
  def get!(%URL{} = solr_url, solr_query) do
    case %Http{
           url: [to_string(solr_url), "?", Encoder.encode(solr_query)] |> IO.iodata_to_binary(),
           headers: solr_url.headers,
           options: solr_url.options
         }
         |> get() do
      {:ok, resp} -> resp
      {:error, error} -> raise error
    end
  end

  @doc """
  Issues a POST update request to a specific Solr endpoint, for data indexing and deletion.
  """
  @spec post(solr_url, solr_update_query) ::
          {:ok, HTTPoison.Response.t()} | {:error, HTTPoison.Error.t()}
  def post(%URL{} = solr_url, solr_query) do
    body = if is_binary(solr_query), do: solr_query, else: Encoder.encode(solr_query)

    post(%Http{
      url: to_string(solr_url),
      headers: solr_url.headers,
      options: solr_url.options,
      body: body
    })
  end

  @doc """
  Issues a POST update request to a specific Solr endpoint, raising an exception in case of failure.
  """
  @spec post!(solr_url, solr_update_query) :: HTTPoison.Response.t()
  def post!(%URL{} = solr_url, solr_query) do
    body = if is_binary(solr_query), do: solr_query, else: Encoder.encode(solr_query)

    case post(%Http{url: to_string(solr_url), headers: solr_url.headers, options: solr_url.options, body: body}) do
      {:ok, resp} -> resp
      {:error, error} -> raise error
    end
  end
end
