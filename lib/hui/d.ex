defmodule Hui.D do
  @moduledoc """
  Struct and functions related to DisMax query.

  Correspond to the query parsers known as the Maximum Disjunction - DisMax
  and eDismax (extended version).

  See below for more details: 
   - [DisMax](http://lucene.apache.org/solr/guide/7_4/the-dismax-query-parser.html#dismax-query-parser-parameters)
   - [Extended DisMax](http://lucene.apache.org/solr/guide/7_4/the-extended-dismax-query-parser.html)

  """
  defstruct [:q, :"q.alt", :qf, :mm, :pf, :ps, :qs, :tie, :bq, :bf, # dismax
             :sow, :"mm.autoRelax", :boost, :lowercaseOperators, :pf2, :ps2, :pf3, :ps3, :stopwords, :uf]  # extended dismax

  @typedoc """
  Struct for DisMax/eDismax query.

  `Hui.URL.encode_query/1` renders this struct into URL query string.
  """
  @type t :: %__MODULE__{q: binary, "q.alt": binary, qf: binary, mm: binary, pf: binary, ps: integer,
                         qs: integer, tie: float, bq: binary, bf: binary, sow: boolean,
                         "mm.autoRelax": boolean, boost: binary, lowercaseOperators: binary,
                         pf2: binary, ps2: integer, pf3: binary, ps3: integer, stopwords: boolean, uf: binary}

end