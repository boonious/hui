defmodule Hui.Query.DisMax do
  @moduledoc """
  Struct related to DisMax query.

  Correspond to the query parsers known as the Maximum Disjunction - DisMax
  and eDismax (extended version).

  See below for more details:
   - [DisMax](http://lucene.apache.org/solr/guide/the-dismax-query-parser.html#dismax-query-parser-parameters)
   - [Extended DisMax](http://lucene.apache.org/solr/guide/the-extended-dismax-query-parser.html)
  """
  defstruct [
    :bf,
    :boost,
    :bq,
    :lowercaseOperators,
    :mm,
    :"mm.autoRelax",
    :pf,
    :pf2,
    :pf3,
    :ps,
    :ps2,
    :ps3,
    :q,
    :"q.alt",
    :qf,
    :qs,
    :sow,
    :stopwords,
    :tie,
    :uf,
    defType: "dismax"
  ]

  @typedoc """
  Struct for DisMax/eDismax query.
  """
  @type t :: %__MODULE__{
          bf: binary,
          boost: binary,
          bq: binary,
          lowercaseOperators: binary,
          mm: binary,
          "mm.autoRelax": boolean,
          pf: binary,
          pf2: binary,
          pf3: binary,
          ps: integer,
          ps2: integer,
          ps3: integer,
          q: binary,
          "q.alt": binary,
          qf: binary,
          qs: integer,
          sow: boolean,
          stopwords: boolean,
          tie: float,
          uf: binary
        }

  @spec new(binary, binary, binary) :: t
  def new(q, qf \\ nil, mm \\ nil), do: %__MODULE__{q: q, qf: qf, mm: mm}

  @spec new :: t
  def new(), do: %__MODULE__{}
end
