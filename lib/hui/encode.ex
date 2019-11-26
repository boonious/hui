defmodule Hui.Encode do
  @moduledoc """
  Utilities for encoding Solr query and update data structures.
  """

  @type query :: Hui.Query.solr_query()
  @type options :: Hui.Encode.Options.t()

  @url_delimiters {"=", "&"}
  @json_delimters {":", ""}


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

  def encode(query, opts) when is_list(query) do
    delimiters = if opts.format == :json, do: @json_delimters, else: @url_delimiters

    query
    |> remove_fields()
    |> _encode(opts, delimiters)
  end

  defp _encode([h | []], %{format: :url} = opts, _), do: [_encode(h, opts, {"=", ""})]
  defp _encode([h | []], %{format: :json} = opts, _), do: [_encode(h, opts, {":", ""})]

  defp _encode([h | t], opts, del), do: [_encode(h, opts, del) | _encode(t, opts, del)]

  # do not render nil valued or empty keyword
  defp _encode({_, nil}, _, _), do: ""
  defp _encode([], _, _), do: ""

  # when value is a also struct, e.g. %Hui.Query.FacetRange/Interval{}
  defp _encode({_, %{__struct__: _} = v}, _, _) when is_map(v), do: [Hui.Encoder.encode(v)]

  # encodes fq: [x, y] type keyword to "fq=x&fq=y"
  defp _encode({k, v}, opts, {eql, sep}) when is_list(v) do
    [
      v
      |> Enum.reject(&(&1 == nil or &1 == ""))
      |> Enum.map_join("&", &_encode({k, &1}, opts, {eql, ""})),
      sep
    ]
  end

  defp _encode({k, v}, %{format: :url} = _opts, {eql, sep}),
    do: [to_string(k), eql, URI.encode_www_form(to_string(v)), sep]

  defp _encode({k, v}, %{format: :json} = _opts, {eql, _sep}),
    do: ["\"", to_string(k), "\"", eql, Poison.encode!(v)]

  @doc """
  Transforms built-in query structs to keyword list.

  This function maps data struct according to Solr syntax,
  addressing prefix, per-field requirement, as well as
  adding implicit query fields such as `facet=true`, `hl=true`
  """
  @spec transform(query, options) :: iodata
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
