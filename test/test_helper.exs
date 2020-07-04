ExUnit.start(exclude: [live: false])
Application.ensure_all_started(:bypass)

defmodule TestHelpers do
  import ExUnit.Assertions

  def test_get_req_url(url, query) do
    {_status, resp} = Hui.Query.get(url, query)

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

  def test_all_search_live(query, expected_params, expected_url) do
    {_, resp} = Hui.q(query)
    requested_params = resp.body["responseHeader"]["params"]
    assert expected_params == requested_params
    assert String.match?(resp.url, expected_url)

    {_, resp} = Hui.search(:default, query)
    requested_params = resp.body["responseHeader"]["params"]
    assert expected_params == requested_params
    assert String.match?(resp.url, expected_url)
  end

  # for update tests
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

  def test_post_req(url, query) do
    # invoke post requests
    # assertions - see Bypass setup in 'setup_bypass_for_post_req'
    Hui.Query.post(url, query)
    Hui.Query.post!(url, query)
  end

  def test_update_req(url, query, commit \\ true) do
    # invoke update requests
    # assertions - see Bypass setup in 'setup_bypass_for_post_req'
    Hui.update(url, query, commit)
    Hui.update!(url, query, commit)
  end

  # for live update tests
  def delete_verify_doc_deletion(%Hui.URL{} = url, delete_msg, id) when is_binary(delete_msg) do
    Hui.update(url, delete_msg)
    Hui.update(url, %Hui.Query.Update{commit: true})
    ids = if is_list(id), do: Enum.join(id, " OR "), else: id
    {_, resp} = Hui.search(:default, q: "*", fq: ["id:(#{ids})"])
    assert resp.body["response"]["numFound"] == 0
  end

  def delete_verify_doc_deletion(%Hui.URL{} = url, %Hui.Query.Update{} = delete_msg, id) do
    Hui.update(url, delete_msg)
    ids = if is_list(id), do: Enum.join(id, " OR "), else: id
    {_, resp} = Hui.search(:default, q: "*", fq: ["id:(#{ids})"])
    assert resp.body["response"]["numFound"] == 0
  end

  def verify_docs_exist(url, id) do
    ids = if is_list(id), do: Enum.join(id, " OR "), else: id
    {_, resp} = Hui.search(url, q: "*", fq: ["id:(#{ids})"])
    assert resp.body["response"]["numFound"] == length(id)
    docs = resp.body["response"]["docs"] |> Enum.map(&Map.get(&1, "id"))
    for x <- id, do: assert(Enum.member?(docs, x))
  end

  def verify_docs_missing(url, id) do
    ids = if is_list(id), do: Enum.join(id, " OR "), else: id
    {_, resp} = Hui.search(url, q: "*", fq: ["id:(#{ids})"])
    assert resp.body["response"]["numFound"] == 0
    docs = resp.body["response"]["docs"] |> Enum.map(&Map.get(&1, "id"))
    for x <- id, do: refute(Enum.member?(docs, x))
  end
end
