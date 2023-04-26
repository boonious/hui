Code.require_file("fixtures/admin.exs", __DIR__)
Code.require_file("fixtures/update.exs", __DIR__)

ExUnit.start(exclude: [integration: true])

Application.ensure_all_started(:bypass)
Application.ensure_all_started(:mox)

Finch.start_link(name: Application.get_env(:hui, :finch)[:name])

defmodule TestHelpers do
  import ExUnit.Assertions
  alias Hui.Http

  def test_get_req_url(url, query) do
    {_status, resp} = get(url, query, Hui.Http.Clients.Httpc)

    regex =
      Hui.Encoder.encode(query)
      |> String.replace("+", "\\+")
      |> Regex.compile!()

    assert String.match?(resp.url |> to_string(), regex)
  end

  defp get(endpoint, query, client) do
    case Http.new(:get, endpoint, query, client) do
      req = %Http{} ->
        req
        |> Hui.Http.Client.dispatch()
        |> Hui.Http.Client.handle_response(req)

      error ->
        error
    end
  end

  def setup_bypass_for_update_query(bypass, expected_data, content_type \\ "application/json", resp \\ "") do
    Bypass.expect(bypass, fn conn ->
      assert String.match?(conn.request_path, ~r/\/update/)
      assert "POST" == conn.method
      assert conn.req_headers |> Enum.member?({"content-type", content_type})

      {:ok, body, conn} = Plug.Conn.read_body(conn)
      assert body == expected_data

      Plug.Conn.resp(conn, 200, resp)
    end)
  end

  def status_code(%HTTPoison.Response{status_code: status}), do: status
  def status_code(%Finch.Response{status: status}), do: status
  def status_code({{_http_ver, status, _}, _headers, _body}), do: status

  def body(%HTTPoison.Response{body: body}), do: body
  def body(%Finch.Response{body: body}), do: body
  def body({_status, _headers, body}), do: IO.iodata_to_binary(body)

  def is_http_client_error(%Mint.TransportError{}), do: true
  def is_http_client_error(%HTTPoison.Error{}), do: true
  def is_http_client_error({:failed_connect, _error}), do: true
end
