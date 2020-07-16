defmodule Hui.Query do
  @moduledoc deprecated: """
               Please use the `get/2` and `post/2` functions in `Hui` instead.
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

  @doc false
  @spec get(solr_url, solr_query) :: {:ok, HTTPoison.Response.t()} | {:error, HTTPoison.Error.t()}
  @deprecated "Please use `Hui.get/2`."
  # coveralls-ignore-start
  def get(%URL{} = solr_url, solr_query) do
    %Http{
      url: [to_string(solr_url), "?", Encoder.encode(solr_query)],
      headers: solr_url.headers,
      options: solr_url.options
    }
    |> dispatch()
  end

  @doc false
  @spec post(solr_url, solr_update_query) :: {:ok, HTTPoison.Response.t()} | {:error, HTTPoison.Error.t()}
  @deprecated "Please use `Hui.post/2`."
  def post(%URL{} = solr_url, solr_query) do
    body = if is_binary(solr_query), do: solr_query, else: Encoder.encode(solr_query)

    %Http{
      url: to_string(solr_url),
      headers: solr_url.headers,
      method: :post,
      options: solr_url.options,
      body: body
    }
    |> dispatch()
  end
  # coveralls-ignore-stop
end
