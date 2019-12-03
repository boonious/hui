defmodule Hui.Query.Standard do
  @moduledoc """
  Struct for the default standard query parser also known as the `lucene` parser.

  See: [Standard Query parser](http://lucene.apache.org/solr/guide/the-standard-query-parser.html).
  """

  @enforce_keys [:q]
  defstruct [:q, :"q.op", :df, :sow]

  @typedoc """
  Struct for the standard query.
  """
  @type t :: %__MODULE__{q: binary, "q.op": binary, df: binary, sow: boolean}

  @spec new :: t
  def new(), do: %__MODULE__{q: ""}
end
