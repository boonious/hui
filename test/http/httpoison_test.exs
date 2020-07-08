defmodule Hui.Http.HttpoisonTest do
  use ExUnit.Case, async: true

  alias Hui.Http.Httpoison
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

      {_, resp} = %Http{url: url} |> Httpoison.get()

      assert resp.status == 200
      assert resp.body == "getting a response"
    end

    test "returns a map body for json response", %{bypass: bypass, bypass_url: url} do
      json = %{"responseHeader" => "123", "response" => %{"numFound" => 47}} |> Poison.encode!()

      Bypass.expect(bypass, fn conn ->
        Plug.Conn.put_resp_header(conn, "content-type", "application/json;charset=utf-8")
        |> Plug.Conn.resp(200, json)
      end)

      {_, resp} = %Http{url: url} |> Httpoison.get()

      assert resp.body == json |> Poison.decode!()
    end

    test "returns the unparsed binary body if json response is invalid", %{bypass: bypass, bypass_url: url} do
      Bypass.expect(bypass, fn conn ->
        Plug.Conn.put_resp_header(conn, "content-type", "application/json;charset=utf-8")
        |> Plug.Conn.resp(200, "non json response")
      end)

      {_, resp} = %Http{url: url} |> Httpoison.get()
      assert resp.body == "non json response"
    end
  end

  test "post/1", %{bypass: bypass, bypass_url: bypass_url} do
    Bypass.expect(bypass, fn conn ->
      assert {:ok, "request body", conn} = Plug.Conn.read_body(conn)
      Plug.Conn.resp(conn, 200, "")
    end)

    {_, resp} = %Http{url: bypass_url, body: "request body"} |> Httpoison.post()
    assert 200 = resp.status
  end

  test "handle 404", %{bypass: bypass, bypass_url: bypass_url} do
    Bypass.expect(bypass, fn conn ->
      Plug.Conn.resp(conn, 404, "")
    end)

    {_, resp} = %Http{url: bypass_url} |> Httpoison.get()
    assert 404 = resp.status
  end

  test "handle unreachable host", %{bypass: bypass, bypass_url: bypass_url} do
    Bypass.down(bypass)

    expected_error = %HTTPoison.Error{id: nil, reason: :econnrefused}
    assert {:error, expected_error} == %Http{url: bypass_url} |> Httpoison.get()
  end
end
