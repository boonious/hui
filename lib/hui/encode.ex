defmodule Hui.Encode do
  @moduledoc """
  Utilities for encoding Solr query and update data structures.
  """

  @type query :: Hui.Query.solr_query()
  @type options :: Hui.Encode.Options.t()

  @url_delimiters {"=", "&"}

  defmodule Options do
    defstruct [:per_field, :prefix, format: :url]

    @type t :: %__MODULE__{
            format: :url,
            per_field: binary,
            prefix: binary
          }
  end

  @doc """
  Utility function that encodes various Solr query types  - `t:Hui.Query.solr_query/0` to IO data.
  """
  @spec encode(query, options) :: iodata
  def encode(query, opts \\ %Options{})

  # encode built-in query structs
  def encode(%{__struct__: _} = query, opts), do: transform(query, opts) |> _encode(opts)

  def encode(query, opts) when is_map(query) do
    query
    |> Map.to_list()
    |> encode(opts)
  end

  def encode(query, opts) when is_list(query) do
    query
    |> remove_fields()
    |> _encode(opts)
  end

  defp _encode(query, opts, delimiters \\ @url_delimiters)
  defp _encode([h | []], opts, _), do: [_encode(h, opts, {"=", ""})]
  defp _encode([h | t], opts, _), do: [_encode(h, opts) | _encode(t, opts)]

  # do not render nil valued or empty keyword
  defp _encode({_, nil}, _, _), do: ""
  defp _encode([], _, _), do: ""

  # when value is a also struct, e.g. %Hui.Query.FacetRange/Interval{}
  defp _encode({_, v}, _opts, sep) when is_map(v) do
    if Map.has_key?(v, :__struct__), do: [Hui.Encoder.encode(v)], else: [encode(v), sep]
  end

  # encodes fq: [x, y] type keyword to "fq=x&fq=y"
  defp _encode({k, v}, opts, {eql, sep}) when is_list(v) do
    [
      v
      |> Enum.reject(&(&1 == nil or &1 == ""))
      |> Enum.map_join("&", &_encode({k, &1}, opts, {eql, ""})),
      sep
    ]
  end

  defp _encode({k, v}, _opts, {eql, sep}),
    do: [to_string(k), eql, URI.encode_www_form(to_string(v)), sep]

  @doc false
  def transform(query, opts \\ %Options{})

  def transform(%{__struct__: _} = query, opts) do
    query
    |> Map.to_list()
    |> remove_fields()
    |> _transform(opts)
  end

  # render keywords according to Solr prefix / per field syntax
  # e.g. transform `field: "year"` into `"facet.field": "year"`, `f.[field].facet.gap` etc.
  defp _transform([h | []], opts), do: [_transform(h, opts)]
  defp _transform([h | t], opts), do: [_transform(h, opts) | _transform(t, opts)]

  defp _transform({k, v}, %{prefix: k_prefix, per_field: per_field_field}) do
    cond do
      k_prefix && String.ends_with?(k_prefix, to_string(k)) -> {:"#{k_prefix}", v}
      k_prefix && per_field_field == nil -> {:"#{k_prefix}.#{k}", v}
      k_prefix && per_field_field != nil -> {:"f.#{per_field_field}.#{k_prefix}.#{k}", v}
      true -> {k, v}
    end
  end

  defp remove_fields(query) do
    query
    |> Enum.reject(fn {k, v} ->
      is_nil(v) or v == "" or v == [] or k == :__struct__ or k == :per_field
    end)
  end
end
