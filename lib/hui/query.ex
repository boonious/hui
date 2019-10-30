defmodule Hui.Query do
  @moduledoc """

  Hui.Query module provides underpinning HTTP-based request functions for Solr, including:

  - `get/2`
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

  @spec get(solr_url, solr_query) :: {:ok, HTTPoison.Response.t()} | {:error, Hui.Error.t()}
  def get(%URL{} = url, query \\ []) do
    endpoint = to_string(url)
    query = Encoder.encode(query)

    get([endpoint, "?", query] |> IO.iodata_to_binary(), url.headers, url.options)
  end
end
