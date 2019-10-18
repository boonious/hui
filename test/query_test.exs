defmodule HuiQueryTest do
  use ExUnit.Case, async: true
  import TestHelpers
  
  alias Hui.Query
  alias Hui.URL

  setup do
    resp = File.read!("./test/data/simple_search_response.json")
    resp_xml = File.read!("./test/data/simple_search_response.xml")
    bypass = Bypass.open
    {:ok, bypass: bypass, simple_search_response_sample: resp, simple_search_response_sample_xml: resp_xml}
  end

  test "Query.get query with list of structs", context do
    Bypass.expect context.bypass, fn conn ->
      Plug.Conn.resp(conn, 200, context.simple_search_response_sample)
    end

    url = %URL{url: "http://localhost:#{context.bypass.port}"}
    x = %Query.Common{rows: 5, fq: ["cat:book", "inStock:true", "price:[1.99 TO 9.99]"]}
    y = %Query.Standard{q: "{!q.op=OR df=series_t}black amber"}

    check_query_req_url(url, [x,y], ~r/fq=cat%3Abook&fq=inStock%3Atrue&fq=price%3A%5B1.99\+TO\+9.99%5D&rows=5&q=%7B%21q.op%3DOR\+df%3Dseries_t%7Dblack\+amber/)
  end
  
  test "Query.get query with DisMax struct", context do
    Bypass.expect context.bypass, fn conn ->
      Plug.Conn.resp(conn, 200, context.simple_search_response_sample)
    end

    url = %URL{url: "http://localhost:#{context.bypass.port}"}
    x = %Query.DisMax{q: "edinburgh", qf: "description^2.3 title", mm: "2<-25% 9<-3", pf: "title", ps: 1, qs: 3, bq: "edited:true"}
    y = %Query.Common{rows: 5, start: 0}

    check_query_req_url(url, x, ~r/bq=edited%3Atrue&mm=2%3C-25%25\+9%3C-3&pf=title&ps=1&q=edinburgh&qf=description%5E2.3\+title&qs=3/)
    check_query_req_url(url, [x,y], ~r/bq=edited%3Atrue&mm=2%3C-25%25\+9%3C-3&pf=title&ps=1&q=edinburgh&qf=description%5E2.3\+title&qs=3&rows=5&start=0/)
  end

end

