defmodule Hui.Encode do
  @moduledoc """
  Utilities for encoding Solr query and update data structures.
  """

  alias Hui.Query.Update

  @type query :: Hui.Query.solr_query()
  @type options :: Hui.Encode.Options.t()

  @url_delimiters {"=", "&"}
  @json_delimters {":", ","}
  @update_encoding_sequence [:doc, :delete_id, :delete_query, :commit, :optimize, :rollback]

  @update_field_sequence %{
    :commit => [:commit, :expungeDeletes, :waitSearcher],
    :doc => [:commitWithin, :overwrite, :doc],
    :delete_id => [:delete_id],
    :delete_query => [:delete_query],
    :optimize => [:optimize, :maxSegments, :waitSearcher],
    :rollback => [:rollback]
  }

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

  def encode([commitWithin: c, overwrite: o, doc: d], %{format: :json} = opts) do
    docs = if is_list(d), do: d, else: [d]

    # TODO: find a better way than Enum.reverse/tl to remove the `.` in the last add doc
    for doc <- docs do
      [
        "\"add\"",
        ":",
        "{",
        _encode({:commitWithin, c}, opts, {":", ","}),
        _encode({:overwrite, o}, opts, {":", ","}),
        _encode({:doc, doc}, opts, {":", ""}),
        "}",
        ","
      ]
    end
    |> List.flatten()
    |> Enum.reverse()
    |> tl()
    |> Enum.reverse()
  end

  def encode([commit: true, expungeDeletes: e, waitSearcher: w], %{format: :json} = opts) do
    sep = unless is_nil(w), do: elem(@json_delimters, 1), else: ""

    [
      "\"commit\"",
      ":",
      "{",
      _encode({:expungeDeletes, e}, opts, {":", sep}),
      _encode({:waitSearcher, w}, opts, {":", ""}),
      "}"
    ]
  end

  def encode([optimize: true, maxSegments: m, waitSearcher: w], %{format: :json} = opts) do
    sep = unless is_nil(w), do: elem(@json_delimters, 1), else: ""

    [
      "\"optimize\"",
      ":",
      "{",
      _encode({:maxSegments, m}, opts, {":", sep}),
      _encode({:waitSearcher, w}, opts, {":", ""}),
      "}"
    ]
  end

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
    sep0 = if opts.format == :json, do: elem(@json_delimters, 1), else: elem(@url_delimiters, 1)

    cond do
      k == :delete and is_binary_list?(v) ->
        ["\"", to_string(k), "\"", eql, Poison.encode!(v), sep]

      true ->
        [
          v
          |> Enum.reject(&(&1 == nil or &1 == ""))
          |> Enum.map_join(sep0, &_encode({k, &1}, opts, {eql, ""})),
          sep
        ]
    end
  end

  defp _encode({k, v}, %{format: :url}, {eql, sep}),
    do: [to_string(k), eql, URI.encode_www_form(to_string(v)), sep]

  defp _encode({:rollback, true}, %{format: :json}, {eql, sep}),
    do: ["\"", "rollback", "\"", eql, "{", "}", sep]

  defp _encode({k, v}, %{format: :json}, {eql, sep}) when k == :delete and is_tuple(v) do
    value = _encode(v, %{format: :json}, {eql, sep})
    ["\"", to_string(k), "\"", eql, "{", value, "}", sep]
  end

  defp _encode({k, v}, %{format: :json}, {eql, sep}),
    do: ["\"", to_string(k), "\"", eql, Poison.encode!(v), sep]

  @doc """
  Transforms built-in query structs to keyword list.

  This function maps data struct according to Solr syntax,
  addressing prefix, per-field requirement, as well as
  adding implicit query fields such as `facet=true`, `hl=true`
  """
  @spec transform(query, options) :: list(keyword)
  def transform(query, opts \\ %Options{})

  def transform(%{__struct__: Update} = query, %{format: :json} = opts) do
    for set <- @update_encoding_sequence do
      query
      |> extract_update_fields(set)
      |> _transform(opts)
    end
    |> Enum.reject(&(&1 == []))
  end

  def transform(%{__struct__: Update} = _, %{format: f}) when f != :json do
    raise "#{f} format is not supported. Hui currently only encodes update message in JSON."
  end

  def transform(%{__struct__: _} = query, opts) do
    query
    |> Map.to_list()
    |> remove_fields()
    |> _transform(opts)
  end

  # render keywords according to Solr prefix / per field syntax
  # e.g. transform `field: "year"` into `"facet.field": "year"`, `f.[field].facet.gap` etc.
  defp _transform([], _), do: []
  defp _transform([h | []], opts), do: [_transform(h, opts)]
  defp _transform([h | t], opts), do: [_transform(h, opts) | _transform(t, opts)]

  defp _transform({k, v}, %{prefix: k_prefix, per_field: per_field_field}) do
    cond do
      k_prefix && String.ends_with?(k_prefix, to_string(k)) -> {:"#{k_prefix}", v}
      k_prefix && per_field_field == nil -> {:"#{k_prefix}.#{k}", v}
      k_prefix && per_field_field != nil -> {:"f.#{per_field_field}.#{k_prefix}.#{k}", v}
      k == :delete_id and is_list(v) -> {:delete, v |> Enum.map(&{:id, &1})}
      k == :delete_id and is_binary(v) -> {:delete, {:id, v}}
      k == :delete_query and is_list(v) -> {:delete, v |> Enum.map(&{:query, &1})}
      k == :delete_query and is_binary(v) -> {:delete, {:query, v}}
      true -> {k, v}
    end
  end

  defp remove_fields(query) do
    query
    |> Enum.reject(fn {k, v} ->
      is_nil(v) or v == "" or v == [] or k == :__struct__ or k == :per_field
    end)
  end

  defp extract_update_fields(%{__struct__: _} = q, group) do
    sequence = @update_field_sequence[group]
    main_fl = Map.get(q, group)

    if main_fl != false and main_fl != nil do
      for fl <- sequence do
        {fl, q |> Map.get(fl)}
      end
    else
      []
    end
  end

  defp is_binary_list?(v) do
    is_list(v) && is_binary(List.first(v))
  end
end
