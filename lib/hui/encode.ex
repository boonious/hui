defmodule Hui.Encode do
  @moduledoc """
  Utilities for encoding Solr query and update data structures.
  """

  alias Hui.Query

  @type faceting_struct :: Query.Facet.t | Query.FacetRange.t | Query.FacetInterval.t
  @type highlighting_struct :: Query.Highlight.t

  @type solr_query :: Keyword.t | faceting_struct | highlighting_struct
  @type options :: Options.t()

  defmodule Options do
    defstruct [:per_field, :prefix, format: :url, separator: "&"]

    @type t :: %__MODULE__{
            format: :url,
            per_field: binary,
            prefix: binary,
            separator: binary
          }
  end

  @doc """
  Encodes list of Solr query keywords to IO data.
  """
  @spec encode(solr_query) :: iodata
  def encode(query) when is_list(query) do
    query
    |> Enum.reject(fn {k,v} -> is_nil(v) or v == "" or v == [] or k == :__struct__ end)
    |> _encode
  end

  def encode(query, opts) when is_map(query) do
    query
    |> Map.to_list
    |> Enum.reject(fn {k,v} -> is_nil(v) or v == "" or v == [] or k == :__struct__ or k == :per_field end)
    |> _transform(opts)
    |> _encode(opts)
  end

  defp _encode(query,  opts \\ %Options{})
  defp _encode([head|[]], opts), do: [_encode(head, %{opts | separator: ""})]
  defp _encode([head|tail], opts), do: [_encode(head, opts) | _encode(tail, opts)]

  # do not render nil valued or empty keyword
  defp _encode({_,nil}, _), do: ""
  defp _encode([], _), do: ""

  # when value is a also struct, e.g. %Hui.Query.FacetRange/Interval{}
  defp _encode({_,v}, opts) when is_map(v) do
    sep = opts.separator
    if Map.has_key?(v, :__struct__), do: [Hui.Encoder.encode(v), sep], else: [encode(v), sep]
  end

  # encodes fq: [x, y] type keyword to "fq=x&fq=y"
  defp _encode({k,v}, opts) when is_list(v), do: [ v |> Enum.map_join("&", &_encode( {k,&1}, %{opts | separator: ""} ) ), opts.separator ]
  defp _encode({k,v}, opts), do: [to_string(k), "=", URI.encode_www_form(to_string(v)), opts.separator]

  # render keywords according to Solr prefix / per field syntax
  # e.g. transform `field: "year"` into `"facet.field": "year"`, `f.[field].facet.gap` etc.
  defp _transform([head|[]], opts), do: [_transform(head, opts)]
  defp _transform([head|tail], opts), do: [_transform(head, opts) | _transform(tail, opts)]
  defp _transform({k,v}, %Options{prefix: k_prefix, per_field: field}) do
    case {k, k_prefix, field} do
      {:facet, _, _} -> {:facet, v}
      {:hl, _, _} -> {:hl, v}
      {:mlt, _, _} -> {:mlt, v}
      {:suggest, _, _} -> {:suggest, v}
      {:spellcheck, _, _} -> {:spellcheck, v}
      {:range, "facet.range", _} -> {:"facet.range", v}
      {:interval, "facet.interval", _} -> {:"facet.interval", v}
      {_, _, nil} -> {:"#{k_prefix}.#{k}", v}
      {_, _, _} -> {:"f.#{field}.#{k_prefix}.#{k}", v}
    end
  end

end