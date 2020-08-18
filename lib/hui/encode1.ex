defmodule Hui.EncodeNew do
  @moduledoc """
  Utilities for encoding Solr query and update data structures.
  """

  @type query :: Hui.Query.solr_query()
  @type options :: Hui.Encode.Options.t()

  @url_delimiters {?=, ?&}

  defmodule Options do
    defstruct [:per_field, :prefix, format: :url]

    @type t :: %__MODULE__{
            format: :url | :json,
            per_field: binary,
            prefix: binary
          }
  end

  @doc """
  Encodes keywords list to IO data.
  """
  @spec encode(list(keyword), options) :: iodata
  def encode(query, opts \\ %Options{})

  def encode(query, opts) when is_list(query), do: transform(query, opts, @url_delimiters)

  def transform([{k, v} | []], opts, {eql, _}) do
    [to_string(k), eql, URI.encode_www_form(to_string(v))]
  end

  def transform([{k, v} | t], opts, {eql, delimiter}) do
    [to_string(k), eql, URI.encode_www_form(to_string(v)), delimiter | [transform(t, opts, {eql, delimiter})]]
  end
end
