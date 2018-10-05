ExUnit.start(exclude: [live: false])
Application.ensure_all_started(:bypass)

defmodule TestHelpers do
  import ExUnit.Assertions

  def check_search_req_url(url, %Hui.Q{} = solr_params, expected_url_regex) do
    {_status, resp} = Hui.Request.search(url, [solr_params])
    match1? = String.match?(resp.request_url, expected_url_regex)

    {_status, resp} = Hui.search(url, solr_params)
    match2? = String.match?(resp.request_url, expected_url_regex)
    match1? and match2?
  end

  def check_search_req_url(url, solr_params, expected_url_regex) when is_list(solr_params) do
    {_status, resp} = Hui.Request.search(url, solr_params)
    match1? = String.match?(resp.request_url, expected_url_regex)

    {_status, resp} = Hui.search(url, solr_params)
    match2? = String.match?(resp.request_url, expected_url_regex)
    match1? and match2?
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
  def check_post_data_bypass_setup(bypass, expected_data) do
    Bypass.expect bypass, fn conn ->
      assert "/update" == conn.request_path
      assert "POST" == conn.method
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      assert body == expected_data
      Plug.Conn.resp(conn, 200, "")
    end
  end

end