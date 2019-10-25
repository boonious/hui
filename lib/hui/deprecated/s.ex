defmodule Hui.S do
  @moduledoc deprecated: """
  Please use Hui.Query.Suggester instead
  """
  defstruct [suggest: true] ++
            [:dictionary, :q, :count, :cfq, :build, :reload, :buildAll, :reloadAll]

  @typedoc """
  Struct for [suggester](http://lucene.apache.org/solr/guide/suggester.html)
  """
  @type t :: %__MODULE__{suggest: boolean, 
                         dictionary: binary | list(binary), q: binary, count: number, cfq: binary,
                         build: boolean, reload: boolean, buildAll: boolean, reloadAll: boolean}
end