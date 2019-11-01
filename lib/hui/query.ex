defmodule Hui.Query do
  @moduledoc """

  Hui.Query module provides underpinning HTTP-based request functions for Solr, including:

  - `get/2`, `get!/2`
  """

  use HTTPoison.Base
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
  @type solr_url :: Hui.URL.t()

  @spec get(solr_url, solr_query) :: {:ok, HTTPoison.Response.t()} | {:error, HTTPoison.Error.t()}
  def get(%URL{} = solr_url, solr_query) do
    endpoint = to_string(solr_url)
    query = Encoder.encode(solr_query)

    get([endpoint, "?", query] |> IO.iodata_to_binary(), solr_url.headers, solr_url.options)
  end

  @spec get!(solr_url, solr_query) :: {:ok, HTTPoison.Response.t()} | {:error, HTTPoison.Error.t()}
  def get!(%URL{} = solr_url, solr_query) do
    endpoint = to_string(solr_url)
    query = Encoder.encode(solr_query)

    get!([endpoint, "?", query] |> IO.iodata_to_binary(), solr_url.headers, solr_url.options)
  end

  # implement HTTPoison.Base callback:
  # decode JSON data, return other response formats as raw text
  def process_response_body(""), do: ""

  def process_response_body(body) do
    {status, solr_results} = Poison.decode(body)

    case status do
      :ok -> solr_results
      :error -> body
    end
  end
end
