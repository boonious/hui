ExUnit.start(exclude: [live: false])
Application.ensure_all_started(:bypass)

defmodule TestHelpers do

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

end