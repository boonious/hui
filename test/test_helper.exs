Code.require_file("fixtures/admin.exs", __DIR__)
Code.require_file("fixtures/update.exs", __DIR__)

ExUnit.start(exclude: [integration: true])

Application.ensure_all_started(:bypass)
Application.ensure_all_started(:mox)

defmodule TestHelpers do
  import ExUnit.Assertions

  def test_get_req_url(url, query) do
    {_status, resp} = Hui.get(url, query)

    regex =
      Hui.Encoder.encode(query)
      |> String.replace("+", "\\+")
      |> Regex.compile!()

    assert String.match?(resp.url |> to_string(), regex)
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
end
