defmodule Hui.Query.Metrics do
  @moduledoc """
  Struct for querying metrics.

  See: [Metrics API](https://solr.apache.org/guide/metrics-reporting.html#metrics-api).

  ### Example
      iex> x = %Hui.Query.Metrics{group: "core", type: "timer", property: ["mean_ms", "max_ms", "p99_ms"], wt: "xml"}
      %Hui.Query.Metrics{
        compact: nil,
        group: "core",
        key: nil,
        prefix: nil,
        property: ["mean_ms", "max_ms", "p99_ms"],
        regex: nil,
        type: "timer",
        wt: "xml"
      }
      iex>  x |> Hui.Encoder.encode
      "group=core&property=mean_ms&property=max_ms&property=p99_ms&type=timer&wt=xml"
  """

  defstruct [:group, :type, :prefix, :regex, :property, :key, :compact, :wt]

  @typedoc """
  Struct for metrics query.
  """
  @type t :: %__MODULE__{
          group: binary,
          type: binary,
          prefix: binary,
          regex: binary,
          property: binary | list(binary),
          key: binary | list(binary),
          compact: boolean,
          wt: binary
        }

  @spec new :: t
  def new(), do: %__MODULE__{}
end
