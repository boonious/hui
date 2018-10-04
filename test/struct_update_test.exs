defmodule HuiStructUpdateTest do
  use ExUnit.Case, async: true

  # testing with Bypass
  setup do
    update_doc = File.read!("./test/data/update_doc2.json") 
    bypass = Bypass.open
    error_einval = %Hui.Error{reason: :einval}
    error_nxdomain = %Hui.Error{reason: :nxdomain}
    {:ok, bypass: bypass, update_doc: update_doc, error_einval: error_einval, error_nxdomain: error_nxdomain}
  end

  describe "Hui.U struct" do

    test "should encode doc from a map", context do
      update_doc =  context.update_doc |> Poison.decode!
      doc_map = update_doc["add"]["doc"]
      expected_data = update_doc |> Poison.encode!

      x = %Hui.U{doc: doc_map}
      assert Hui.U.encode(x) == expected_data
    end

    test "doc should be posted to a URL (struct)", context do
      url = %Hui.URL{url: "http://localhost:#{context.bypass.port}", handler: "update", headers: [{"Content-type", "application/json"}]}
      update_doc =  context.update_doc |> Poison.decode!
      expected_data = update_doc |> Poison.encode!

      Bypass.expect context.bypass, fn conn ->
        assert "/update" == conn.request_path
        assert "POST" == conn.method
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        assert body == expected_data
        Plug.Conn.resp(conn, 200, "")
      end

      doc_map = update_doc["add"]["doc"]
      x = %Hui.U{doc: doc_map}
      Hui.Request.update(url, x)
    end

  end

end