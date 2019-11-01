ExUnit.start(exclude: [live: false])
Application.ensure_all_started(:bypass)

defmodule TestHelpers do
  import ExUnit.Assertions

  def test_get_req_url(url, query) do
    {_status, resp} = Hui.Query.get(url, query)

    regex = Hui.Encoder.encode(query) 
            |> String.replace("+", "\\+")
            |> Regex.compile!

    assert String.match?(resp.request_url, regex)
  end

  # deprecated - %Hui.Q{}
  def check_search_req_url(url, %Hui.Q{} = solr_params, expected_url_regex) do
    {_status, resp} = Hui.Request.search(url, [solr_params])
    match1? = String.match?(resp.request_url, expected_url_regex)

    {_status, resp} = Hui.search(url, solr_params)
    match2? = String.match?(resp.request_url, expected_url_regex)
    match1? and match2?
  end

  def check_search_req_url(url, query, regex) do
    {_status, resp} = Hui.search(url, query)
    assert String.match?(resp.request_url, regex)
  end

  def check_search_req_url(url, query) do
    {_status, resp} = Hui.search(url, query)

    regex = Hui.Encoder.encode(query) 
            |> String.replace("+", "\\+")
            |> Regex.compile!

    assert String.match?(resp.request_url, regex)
  end

  # for search bang tests
  def check_search_req_url!(url, %Hui.Q{} = solr_params, expected_url_regex) do
    bang = true
    resp = Hui.Request.search(url, bang, [solr_params])
    match1? = String.match?(resp.request_url, expected_url_regex)

    resp = Hui.search!(url, solr_params)
    match2? = String.match?(resp.request_url, expected_url_regex)
    match1? and match2?
  end

  def check_search_req_url!(url, solr_params, expected_url_regex) when is_list(solr_params) do
    bang = true
    resp = Hui.Request.search(url, bang, solr_params)
    match1? = String.match?(resp.request_url, expected_url_regex)

    resp = Hui.search!(url, solr_params)
    match2? = String.match?(resp.request_url, expected_url_regex)
    match1? and match2?
  end

  # for update tests
  def check_post_data_bypass_setup(bypass, expected_data, content_type \\ "application/json", resp \\ "") do
    Bypass.expect bypass, fn conn ->
      assert String.match?(conn.request_path, ~r/\/update/)
      assert "POST" == conn.method
      assert conn.req_headers |> Enum.member?({"content-type", content_type})
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      assert body == expected_data
      Plug.Conn.resp(conn, 200, resp)
    end
  end

  # for live update tests
  def delete_verify_doc_deletion(%Hui.URL{} = url, delete_msg, id) when is_binary(delete_msg) do
    Hui.Request.update(url, delete_msg)
    Hui.Request.update(url, %Hui.U{commit: true})
    ids = if is_list(id), do: Enum.join(id, " OR "), else: id
    resp = Hui.search!(:default, q: "*", fq: ["id:(#{ids})"])
    assert resp.body["response"]["numFound"] == 0
  end

  def delete_verify_doc_deletion(%Hui.URL{} = url, %Hui.U{} = delete_msg, id) do
    Hui.Request.update(url, delete_msg)
    ids = if is_list(id), do: Enum.join(id, " OR "), else: id
    resp = Hui.search!(:default, q: "*", fq: ["id:(#{ids})"])
    assert resp.body["response"]["numFound"] == 0
  end

  def verify_docs_exist(url, id) do
    ids = if is_list(id), do: Enum.join(id, " OR "), else: id
    resp = Hui.search!(url, q: "*", fq: ["id:(#{ids})"])
    assert resp.body["response"]["numFound"] == length(id)
    docs = resp.body["response"]["docs"] |> Enum.map(&(Map.get(&1, "id")))
    for x <- id, do: assert Enum.member? docs, x
  end

  def verify_docs_missing(url, id) do
    ids = if is_list(id), do: Enum.join(id, " OR "), else: id
    resp = Hui.search!(url, q: "*", fq: ["id:(#{ids})"])
    assert resp.body["response"]["numFound"] == 0
    docs = resp.body["response"]["docs"] |> Enum.map(&(Map.get(&1, "id")))
    for x <- id, do: refute Enum.member? docs, x
  end

end