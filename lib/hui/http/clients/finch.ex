if Code.ensure_compiled(Finch) == {:module, Finch} do
  defmodule Hui.Http.Clients.Finch do
    @moduledoc false

    @behaviour Hui.Http.Client

    @config Application.compile_env(:hui, :finch)

    @impl true
    def dispatch(request) do
      name = get_name(@config)

      Finch.build(request.method, request.url |> IO.iodata_to_binary(), request.headers, request.body)
      |> Finch.request(name, request.options)
    end

    defp get_name(config) when is_list(config), do: Keyword.get(config, :name) |> get_name()
    defp get_name(name) when is_atom(name), do: name

    @impl true
    def handle_response({:ok, %{body: body, headers: headers, status: status}}, req) do
      {:ok, %{req | body: body, headers: headers, status: status}}
      |> parse(req.response_parser)
    end

    def handle_response({:error, %Mint.TransportError{reason: reason}}, _req) do
      {:error, %Hui.Error{reason: reason}}
    end

    defp parse(response, nil), do: response
    defp parse(response, parser), do: apply(parser, :parse, [response])
  end
end
