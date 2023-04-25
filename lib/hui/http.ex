defmodule Hui.Http do
  @moduledoc """
  A struct and functions for making Solr HTTP request and response.
  """

  alias Hui.Encoder
  alias Hui.Http
  alias Hui.Query
  alias Hui.Query.Update
  alias Hui.Utils.ParserType
  alias Hui.Utils.Url, as: UrlUtils

  import Hui.Http.Client

  @json_parser Application.compile_env(:hui, :json_parser)
  @parser_not_configured ParserType.not_configured()

  defstruct body: nil,
            client: impl(),
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
  @type update_query :: binary | map | list(map) | Update.t()

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

  def new(:post, endpoint, updates, client) do
    with {:ok, {url, headers, options, parser}} <- UrlUtils.parse_endpoint(endpoint),
         updates <- maybe_encode_updates(updates) do
      parser = if parser == :not_configured, do: @json_parser, else: parser

      %Http{
        body: updates,
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

  defp maybe_encode_updates(updates) when is_binary(updates), do: updates
  defp maybe_encode_updates(updates), do: Encoder.encode(updates)

  @doc false
  @spec get(endpoint, query, module) :: response
  def get(endpoint, query, client \\ impl()) do
    new(:get, endpoint, query, client) |> request()
  end

  @doc false
  @spec post(endpoint, update_query, boolean, module) :: response
  def post(endpoint, updates, commit \\ true, client \\ impl())

  def post(endpoint, updates, _commit, client) when is_binary(updates), do: do_post(endpoint, updates, client)
  def post(endpoint, %Update{} = updates, _commit, client), do: do_post(endpoint, updates, client)

  def post(endpoint, %{} = doc, commit, client), do: post(endpoint, %Update{doc: doc, commit: commit}, client)

  def post(endpoint, [%{} = _doc | _] = docs, commit, client) do
    post(endpoint, %Update{doc: docs, commit: commit}, client)
  end

  defp do_post(endpoint, updates, client), do: new(:post, endpoint, updates, client) |> request()

  defp request(%Http{} = req) do
    req
    |> dispatch()
    |> handle_response(req)
  end
end
