defmodule Hui.Http do
  @moduledoc """
  A struct for Solr HTTP request and response.
  """

  alias Hui.Encoder
  alias Hui.Http
  alias Hui.Query
  alias Hui.Utils.ParserType
  alias Hui.Utils.Url, as: UrlUtils

  @default_client Hui.Http.Clients.Httpc
  @json_parser Application.compile_env(:hui, :json_parser)
  @parser_not_configured ParserType.not_configured()

  defstruct body: nil,
            client: @default_client,
            headers: [],
            method: :get,
            options: [],
            response_parser: nil,
            status: nil,
            url: ""

  @type querying_struct :: Query.Standard.t() | Query.Common.t() | Query.DisMax.t()
  @type faceting_struct :: Query.Facet.t() | Query.FacetRange.t() | Query.FacetInterval.t()
  @type highlighting_struct ::
          Query.Highlight.t()
          | Query.HighlighterUnified.t()
          | Query.HighlighterOriginal.t()
          | Query.HighlighterFastVector.t()

  @type misc_struct :: Query.MoreLikeThis.t() | Query.Suggest.t() | Query.SpellCheck.t() | Query.Metrics.t()
  @type solr_struct :: querying_struct | faceting_struct | highlighting_struct | misc_struct

  @type query :: keyword | map | solr_struct | [solr_struct]
  @type update_query :: binary | map | list(map) | Query.Update.t()

  @type client :: module
  @type method :: :get | :post

  @type url :: binary() | atom()
  @type headers :: list()
  @type options :: list()

  @type endpoint :: url | {url, headers} | {url, headers, options}

  @type body :: nil | iodata() | map()
  @type request_url :: iodata()
  @type response :: {:ok, t} | {:error, Hui.Error.t()}

  @typedoc """
  The main request and response data struct.
  """
  @type t :: %__MODULE__{
          body: body,
          client: module(),
          headers: list(),
          method: :get | :post,
          options: keyword(),
          response_parser: module(),
          status: nil | integer(),
          url: request_url
        }

  def new(:get, endpoint, query, client) do
    with {:ok, {url, headers, options, opted_parser}} <- UrlUtils.parse_endpoint(endpoint),
         parser <- maybe_infer_parser(query, opted_parser) do
      %Http{
        client: client,
        url: [url, "?", Encoder.encode(query)],
        headers: headers,
        method: :get,
        options: options,
        response_parser: parser
      }
    end
  end

  def new(:post, endpoint, docs, client) do
    with {:ok, {url, headers, options, parser}} <- UrlUtils.parse_endpoint(endpoint),
         docs <- maybe_encode_docs(docs) do
      parser = if parser == :not_configured, do: @json_parser, else: parser

      %Http{
        body: docs,
        client: client,
        url: url,
        headers: headers,
        method: :post,
        options: options,
        response_parser: parser
      }
    end
  end

  defp maybe_infer_parser(query, opted_parser) do
    case opted_parser do
      parser when parser == @parser_not_configured -> ParserType.infer(query)
      opted_parser -> opted_parser
    end
  end

  defp maybe_encode_docs(docs) when is_binary(docs), do: docs
  defp maybe_encode_docs(docs), do: Encoder.encode(docs)
end
