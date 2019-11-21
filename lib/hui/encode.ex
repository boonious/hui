defmodule Hui.Encode do
  @moduledoc """
  Utilities for encoding Solr query and update data structures.
  """

  @type query :: Hui.Query.solr_query()
  @type options :: Hui.Encode.Options.t()

  defmodule Options do
    defstruct [:per_field, :prefix, equal: "=", format: :url, separator: "&"]

    @type t :: %__MODULE__{
            equal: binary,
            format: :url,
            per_field: binary,
            prefix: binary,
            separator: binary
          }
  end

  @doc """
  Utility function that encodes various Solr query types  - `t:Hui.Query.solr_query/0` to IO data.
  """
  @spec encode(query, options) :: iodata
  def encode(query, opts \\ %Options{})

  def encode(query, _opts) when is_list(query) do
    query
    |> Enum.reject(fn {k, v} -> is_nil(v) or v == "" or v == [] or k == :__struct__ end)
    |> _encode
  end

  def encode(query, opts) when is_map(query) do
    query
    |> Map.to_list()
    |> Enum.reject(fn {k, v} ->
      is_nil(v) or v == "" or v == [] or k == :__struct__ or k == :per_field
    end)
    |> _transform(opts)
    |> _encode(opts)
  end

  defp _encode(query, opts \\ %Options{})
  defp _encode([head | []], opts), do: [_encode(head, %{opts | separator: ""})]
  defp _encode([head | tail], opts), do: [_encode(head, opts) | _encode(tail, opts)]

  # do not render nil valued or empty keyword
  defp _encode({_, nil}, _), do: ""
  defp _encode([], _), do: ""

  # when value is a also struct, e.g. %Hui.Query.FacetRange/Interval{}
  defp _encode({_, v}, opts) when is_map(v) do
    sep = opts.separator
    if Map.has_key?(v, :__struct__), do: [Hui.Encoder.encode(v), sep], else: [encode(v), sep]
  end

  # encodes fq: [x, y] type keyword to "fq=x&fq=y"
  defp _encode({k, v}, opts) when is_list(v) do
    [
      v
      |> Enum.reject(&(&1 == nil or &1 == ""))
      |> Enum.map_join("&", &_encode({k, &1}, %{opts | separator: ""})),
      opts.separator
    ]
  end

  defp _encode({k, v}, opts),
    do: [to_string(k), opts.equal, URI.encode_www_form(to_string(v)), opts.separator]

  # render keywords according to Solr prefix / per field syntax
  # e.g. transform `field: "year"` into `"facet.field": "year"`, `f.[field].facet.gap` etc.
  defp _transform([head | []], opts), do: [_transform(head, opts)]
  defp _transform([head | tail], opts), do: [_transform(head, opts) | _transform(tail, opts)]

  defp _transform({k, v}, %Options{prefix: k_prefix, per_field: per_field_field}) do
    cond do
      k_prefix && String.ends_with?(k_prefix, to_string(k)) -> {k_prefix, v}
      k_prefix && per_field_field == nil -> {:"#{k_prefix}.#{k}", v}
      k_prefix && per_field_field != nil -> {:"f.#{per_field_field}.#{k_prefix}.#{k}", v}
      true -> {k, v}
    end
  end
end
