defmodule Hui.Request do
  @moduledoc deprecated: """
  Please use Hui.Query instead.
  """

  use HTTPoison.Base 
  import Hui.Guards

  alias Hui.Query
  alias Hui.Encoder

  @type highlighter_struct :: Hui.H.t | Hui.H1.t | Hui.H2.t | Hui.H3.t
  @type misc_struct :: Hui.S.t | Hui.Sp.t | Hui.M.t
  @type query_struct_list :: list(Hui.Q.t | Hui.D.t | Hui.F.t | highlighter_struct | misc_struct)

  # Use the following equivalent typespecs when checking codes with
  # Dialyzer as the above typespec style doesn'seem to work with the tool.
  #
  #@type highlighter_struct :: %Hui.H{} | %Hui.H1{} | %Hui.H2{} | %Hui.H3{}
  #@type misc_struct :: %Hui.S{} | %Hui.Sp{} | %Hui.M{}
  #@type query_struct_list :: list(%Hui.Q{} | %Hui.D{} | %Hui.F{} | highlighter_struct | misc_struct)

  @type solr_params :: Keyword.t | query_struct_list
  @type solr_url :: atom | Hui.URL.t

  @error_einval %Hui.Error{reason: :einval} # invalid argument exception
  @error_nxdomain %Hui.Error{reason: :nxdomain} # invalid / non existing host or domain

  @doc false
  @spec search(solr_url, boolean, solr_params) :: {:ok, HTTPoison.Response.t} | {:error, Hui.Error.t} | HTTPoison.Response.t
  @deprecated "Please Hui.Query.get/2."
  # coveralls-ignore-start
  def search(url, bang \\ false, query)
  def search(%Hui.URL{} = url, bang, query), do: _search(url, bang, query)

  def search(url, true, _query) when is_nil_empty(url), do: raise @error_einval
  def search(url, _bang, _query) when is_nil_empty(url), do: {:error, @error_einval}

  def search(url, bang, query) when is_binary(url), do: _search(%Hui.URL{url: url}, bang, query)
  def search(url, bang, query) when is_atom(url) do
    {status, url_struct} = Hui.URL.configured_url(url)
    case {status, bang} do
      {:ok, _} -> _search(url_struct, bang, query)
      {:error, false} -> {:error, @error_nxdomain}
      {:error, true} -> raise @error_nxdomain
    end
  end
  def search(_,_,_), do: {:error, @error_einval}
  # coveralls-ignore-stop

  @doc false
  @spec update(solr_url, boolean, binary | Hui.U.t) :: {:ok, HTTPoison.Response.t} | {:error, Hui.Error.t} | HTTPoison.Response.t
  @deprecated  "Please Hui.Query.post/2."
  # coveralls-ignore-start
  def update(url, bang \\ false, data)
  def update(%Hui.URL{} = url, bang, data) when is_binary(data), do: _update(url, bang, data)
  def update(%Hui.URL{} = url, bang, %Query.Update{} = data), do: _update(url, bang, data |> Encoder.encode)

  def update(url, true, _data) when is_nil_empty(url), do: raise @error_einval
  def update(url, _bang, _data) when is_nil_empty(url), do: {:error, @error_einval}

  def update(url, bang, %Query.Update{} = data) when is_atom(url), do: update(url, bang, data |> Encoder.encode)
  def update(url, bang, data) when is_atom(url) and is_binary(data) do
    {status, url_struct} = Hui.URL.configured_url(url)
    case {status, bang} do
      {:ok, _} -> _update(url_struct, bang, data)
      {:error, false} -> {:error, @error_nxdomain}
      {:error, true} -> raise @error_nxdomain
    end
  end
  def update(_,_,_), do: {:error, @error_einval}
  # coveralls-ignore-stop

  # decode JSON data and return other response formats as
  # raw text
  def process_response_body(""), do: ""
  def process_response_body(body) do
    {status, solr_results} = Poison.decode body
    case status do
      :ok -> solr_results
      :error -> body
    end
  end

  # for keyword lists query 
  # coveralls-ignore-start
  defp _search(%Hui.URL{} = url_struct, bang, [head|tail]) when is_tuple(head) do
    url = Hui.URL.to_string(url_struct)
    _search( url <> "?" <> Hui.URL.encode_query([head] ++ tail), url_struct.headers, url_struct.options, bang )
  end

  # for struct-based query 
  defp _search(%Hui.URL{} = url_struct, bang, [head|tail]) when is_map(head) do
    url = Hui.URL.to_string(url_struct)
    _search( url <> "?" <> Enum.map_join([head] ++ tail, "&", &Hui.URL.encode_query/1), url_struct.headers, url_struct.options, bang )
  end
  defp _search(_,true,_), do: raise @error_einval
  defp _search(_,_,_), do: {:error, @error_einval}

  defp _search(url, headers, options, true), do: get!(url, headers, options)
  defp _search(url, headers, options, _bang) do
   {status, resp} = get(url, headers, options)
   case status do
     :ok -> {:ok, resp}
     :error -> {:error, %Hui.Error{reason: resp.reason}}
   end
  end

  defp  _update(%Hui.URL{} = url_struct, true, data), do: Hui.URL.to_string(url_struct) |> post!(data, url_struct.headers, url_struct.options)
  defp  _update(%Hui.URL{} = url_struct, _bang, data) do
    url = Hui.URL.to_string(url_struct)
    {status, resp} = post(url, data, url_struct.headers, url_struct.options)
    case status do
      :ok -> {:ok, resp}
      :error -> {:error, %Hui.Error{reason: resp.reason}}
    end
  end
  # coveralls-ignore-stop

end