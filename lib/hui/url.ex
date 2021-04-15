# coveralls-ignore-start
defmodule Hui.URL do
  @moduledoc deprecated: "Use {url, headers, options} tuple instead - see README."

  @deprecated "Use {url, headers, options} tuple instead - see README"
  defstruct [:url, handler: "select", headers: [], options: []]
  @type headers :: [{binary(), binary()}]
  @type options :: Keyword.t()
  @type t :: %__MODULE__{url: nil | binary, handler: nil | binary, headers: nil | headers, options: nil | options}

  @deprecated "Use see README to find out more about setting up default SOLR endpoints"
  @spec default_url! :: t | nil
  def default_url! do
    {status, default_url} = configured_url(:default)

    case status do
      :ok -> default_url
      :error -> nil
    end
  end

  @deprecated "Use see README to find out more about configuring SOLR endpoints"
  @spec configured_url(atom) :: {:ok, t} | {:error, binary} | nil
  def configured_url(config_key) do
    url = Application.get_env(:hui, config_key)[:url]
    handler = Application.get_env(:hui, config_key)[:handler]

    headers =
      if Application.get_env(:hui, config_key)[:headers], do: Application.get_env(:hui, config_key)[:headers], else: []

    options =
      if Application.get_env(:hui, config_key)[:options], do: Application.get_env(:hui, config_key)[:options], else: []

    case {url, handler} do
      {nil, _} -> {:error, %Hui.Error{reason: :nxdomain}}
      {_, nil} -> {:ok, %Hui.URL{url: url, headers: headers, options: options}}
      {_, _} -> {:ok, %Hui.URL{url: url, handler: handler, headers: headers, options: options}}
    end
  end

  @deprecated "Use see README to find out more about configuring SOLR endpoints"
  @spec to_string(t) :: binary
  defdelegate to_string(uri), to: String.Chars.Hui.URL
end

# implement `to_string` for %Hui.URL{} in Elixir generally via the String.Chars protocol
defimpl String.Chars, for: Hui.URL do
  def to_string(%Hui.URL{url: url, handler: handler}), do: [url, "/", handler] |> IO.iodata_to_binary()
end

# coveralls-ignore-stop
