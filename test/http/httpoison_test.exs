defmodule Hui.Http.HttpoisonTest do
  use ExUnit.Case, async: true

  alias Hui.Http.Httpoison
  alias Hui.Http

  setup do
    bypass = Bypass.open()
    bypass_url = "http://localhost:#{bypass.port}"

    %{bypass: bypass, bypass_url: bypass_url}
  end

  test "get/1", %{bypass: bypass, bypass_url: bypass_url} do
    Bypass.expect(bypass, fn conn ->
      Plug.Conn.resp(conn, 200, "getting a response")
    end)

    {_, resp} = %Http{url: bypass_url} |> Httpoison.get()

    assert 200 = resp.status
    assert "getting a response" = resp.body
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
