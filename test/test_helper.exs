ExUnit.start()
Application.ensure_all_started(:bypass)

defmodule TestHelpers do
  import ExUnit.Assertions

  def test_get_req_url(url, query) do
    {_status, resp} = Hui.get(url, query)

    regex =
      Hui.Encoder.encode(query)
      |> String.replace("+", "\\+")
      |> Regex.compile!()

    assert String.match?(resp.url, regex)
  end

  def test_search_req_url(url, query, regex) do
    {_status, resp} = Hui.search(url, query)
    assert String.match?(resp.url, regex)
  end

  def test_search_req_url(url, query) do
    {_status, resp} = Hui.search(url, query)

    regex =
      Hui.Encoder.encode(query)
      |> String.replace("+", "\\+")
      |> Regex.compile!()

    assert String.match?(resp.url, regex)
  end

  def setup_bypass_for_post_req(bypass, expected_data, content_type \\ "application/json", resp \\ "") do
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
