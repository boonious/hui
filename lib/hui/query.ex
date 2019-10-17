defmodule Hui.Query do
  @moduledoc """

  Hui.Query module provides underpinning HTTP-based request functions for Solr, including:

  - `get/2`
  """

  use HTTPoison.Base 
  alias Hui.URL
  alias Hui.Encoder

  @type solr_struct :: Query.Standard.t | Query.Common.t
  @type solr_structs :: list(Query.Standard.t | Query.Common.t)

  @type solr_params :: Keyword.t | map | solr_struct | solr_structs
  @type solr_url :: Hui.URL.t

  @error_einval %Hui.Error{reason: :einval} # invalid argument exception
  @error_nxdomain %Hui.Error{reason: :nxdomain} # invalid / non existing host or domain

  @spec get(solr_url, solr_params) :: {:ok, HTTPoison.Response.t} | {:error, Hui.Error.t}  
  def get(%URL{} = solr_url,  solr_params \\ []) do
    url = to_string(solr_url)
    query = Encoder.encode(solr_params) 

    get([url, "?", query] |> IO.iodata_to_binary, solr_url.headers, solr_url.options)
  end

end
