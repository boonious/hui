if Code.ensure_compiled(Finch) == {:module, Finch} and Code.ensure_loaded?(:hackney) do
  defmodule Hui.Http.Finch do
    @moduledoc false

    @behaviour Hui.Http

    alias Hui.Http

    @config Application.compile_env(:hui, :finch)

    @impl Http
    def dispatch(request) do
      name = get_name(@config)

      Finch.build(request.method, request.url, request.headers, request.body)
      |> Finch.request(name, request.options)
      |> handle_response(request.url)
    end

    defp get_name(nil), do: raise("Finch client module name configuration is missing")
    defp get_name(config) when is_list(config), do: Keyword.get(config, :name) |> get_name()
    defp get_name(name) when is_atom(name), do: name

    defp handle_response({:ok, %{body: body, headers: headers, status: status}}, url) do
      case json?(headers) do
        true -> {:ok, %Http{body: decode_json(body), headers: headers, status: status, url: url}}
        false -> {:ok, %Http{body: body, headers: headers, status: status, url: url}}
      end
    end

    defp handle_response({:error, %Mint.TransportError{reason: reason}}, _url) do
      {:error, %Hui.Error{reason: reason}}
    end

    defp json?(headers) do
      {"content-type", "application/json;charset=utf-8"} in headers
    end

    defp decode_json(body) do
      case Jason.decode(body) do
        {:ok, map} -> map
        {:error, %Jason.DecodeError{}} -> body
      end
    end
  end
end
