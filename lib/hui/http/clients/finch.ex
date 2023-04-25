if Code.ensure_compiled(Finch) == {:module, Finch} do
  defmodule Hui.Http.Clients.Finch do
    @moduledoc false

    @behaviour Hui.Http.Client

    alias Hui.Http

    @config Application.compile_env(:hui, :finch)

    # FIX-ME: update implementation give Http.new, new client `handle_response/1` behaviour

    @impl true
    def dispatch(request) do
      name = get_name(@config)

      Finch.build(request.method, request.url, request.headers, request.body)
      |> Finch.request(name, request.options)
      |> handle_response(request.url)
    end

    defp get_name(nil), do: raise("Finch client module name configuration is missing")
    defp get_name(config) when is_list(config), do: Keyword.get(config, :name) |> get_name()
    defp get_name(name) when is_atom(name), do: name

    @impl true
    def handle_response({:ok, %{body: body, headers: headers, status: status}}, url) do
      {:ok, %Http{body: body, headers: headers, status: status, url: url}}
    end

    def handle_response({:error, %Mint.TransportError{reason: reason}}, _url) do
      {:error, %Hui.Error{reason: reason}}
    end
  end
end