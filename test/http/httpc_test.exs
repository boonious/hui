defmodule Hui.Http.HttpcTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog

  alias Hui.Http.Httpc
  alias Hui.Http

  setup do
    bypass = Bypass.open()
    bypass_url = "http://localhost:#{bypass.port}"

    %{bypass: bypass, bypass_url: bypass_url}
  end

  describe "get/1" do
    test "response status and body", %{bypass: bypass, bypass_url: url} do
      Bypass.expect(bypass, fn conn ->
        Plug.Conn.resp(conn, 200, "getting a response")
      end)

      {_, resp} = %Http{url: url} |> Httpc.dispatch()

      assert resp.status == 200
      assert resp.body == "getting a response"
    end

    test "returns a map body for json response", %{bypass: bypass, bypass_url: url} do
      json_resp = %{"responseHeader" => "123", "response" => %{"numFound" => 47}}

      Bypass.expect(bypass, fn conn ->
        Plug.Conn.put_resp_header(conn, "content-type", "application/json;charset=utf-8")
        |> Plug.Conn.resp(200, Jason.encode!(json_resp))
      end)

      {_, resp} = %Http{url: url} |> Httpc.dispatch()

      assert resp.body == json_resp
    end

    test "returns the unparsed binary body if json response is invalid", %{bypass: bypass, bypass_url: url} do
      Bypass.expect(bypass, fn conn ->
        Plug.Conn.put_resp_header(conn, "content-type", "application/json;charset=utf-8")
        |> Plug.Conn.resp(200, "non json response")
      end)

      {_, resp} = %Http{url: url} |> Httpc.dispatch()
      assert resp.body == "non json response"
    end

    test "facilitates various httpc options", %{bypass: bypass, bypass_url: url} do
      # See: http://erlang.org/doc/man/httpc.html#request-5
      options = [{:autoredirect, true}, {:timeout, 1000}, {:body_format, :binary}]

      Bypass.expect(bypass, fn conn ->
        Plug.Conn.resp(conn, 200, "getting a response")
      end)

      {_, resp} = %Http{url: url, options: options} |> Httpc.dispatch()
      assert resp.body == "getting a response"
    end

    test "ignores invalid httpc options", %{bypass: bypass, bypass_url: url} do
      # See: http://erlang.org/doc/man/httpc.html#request-5
      options = [{:non_existing_option, :binary}]

      Bypass.expect(bypass, fn conn ->
        Plug.Conn.resp(conn, 200, "getting a response")
      end)

      # httpc outputs charlist equivalent of "Invalid option {non_existing_http_option,binary} ignored \n"
      assert capture_log(fn -> %Http{url: url, options: options} |> Httpc.dispatch() end) =~
               "[73, 110, 118, 97, 108, 105, 100, 32, 111, 112, 116, 105, 111, 110, 32, [123, ['non_existing_option', 44, 'binary'], 125], 32, 105, 103, 110, 111, 114, 101, 100, 32, 10]"
    end
  end

  describe "post/1" do
    test "response status and body", %{bypass: bypass, bypass_url: url} do
      Bypass.expect(bypass, fn conn ->
        assert {:ok, "{\"doc\":\"request body\"}", conn} = Plug.Conn.read_body(conn)
        assert conn.method == "POST"

        Plug.Conn.resp(conn, 200, "")
      end)

      {_, resp} =
        %Http{
          method: :post,
          url: url,
          body: "{\"doc\":\"request body\"}",
          headers: [{"content-type", "application/json"}]
        }
        |> Httpc.dispatch()

      assert 200 = resp.status
    end

    test "returns a map body for json response", %{bypass: bypass, bypass_url: url} do
      json_resp = %{"responseHeader" => "123", "response" => %{"numFound" => 47}}

      Bypass.expect(bypass, fn conn ->
        Plug.Conn.put_resp_header(conn, "content-type", "application/json;charset=utf-8")
        |> Plug.Conn.resp(200, Jason.encode!(json_resp))
      end)

      {_, resp} =
        %Http{
          method: :post,
          url: url,
          body: "{\"doc\":\"request body\"}",
          headers: [{"content-type", "application/json"}]
        }
        |> Httpc.dispatch()

      assert resp.body == json_resp
    end

    test "facilitates various httpc options", %{bypass: bypass, bypass_url: url} do
      # See: http://erlang.org/doc/man/httpc.html#request-5
      options = [{:autoredirect, true}, {:timeout, 1000}, {:body_format, :binary}]

      Bypass.expect(bypass, fn conn ->
        Plug.Conn.resp(conn, 200, "getting a response")
      end)

      {_, resp} =
        %Http{
          method: :post,
          url: url,
          body: "{\"doc\":\"request body\"}",
          headers: [{"content-type", "application/json"}],
          options: options
        }
        |> Httpc.dispatch()

      assert resp.body == "getting a response"
    end
  end
end
