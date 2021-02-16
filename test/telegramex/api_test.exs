defmodule Telegramex.APITest do
  use ExUnit.Case, async: true

  alias Telegramex.{API, Client}

  setup do
    bypass = Bypass.open()
    {:ok, bypass: bypass}
  end

  describe "call/3" do
    test "base url with path", %{bypass: bypass} do
      token = "token"

      client = %Client{token: token, base_url: "http://localhost:#{bypass.port}/somepath"}

      Bypass.expect_once(bypass, "POST", "/somepath/bot#{token}/coolOperation", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        assert Jason.decode!(body) == %{"some" => "body"}

        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(200, ~s({"ok": true, "result": []}))
      end)

      assert API.call(client, "coolOperation", %{some: "body"}) ==
               {:ok, %{"ok" => true, "result" => []}}
    end

    test "skip decoding when hasn't content type json", %{bypass: bypass} do
      token = "token"

      client = %Client{token: token, base_url: "http://localhost:#{bypass.port}"}

      Bypass.expect_once(bypass, "POST", "/bot#{token}/coolOperation", fn conn ->
        Plug.Conn.resp(conn, 200, ~s({"ok": true, "result": []}))
      end)

      assert API.call(client, "coolOperation", %{some: "body"}) ==
               {:ok, ~s({"ok": true, "result": []})}
    end

    test "fails to decode json", %{bypass: bypass} do
      token = "token"

      client = %Client{token: token, base_url: "http://localhost:#{bypass.port}"}

      Bypass.expect_once(bypass, "POST", "/bot#{token}/coolOperation", fn conn ->
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(200, ~s({malformed'json))
      end)

      assert {:error, %Jason.DecodeError{}} = API.call(client, "coolOperation", %{some: "body"})
    end

    test "http client missing options" do
      token = "token"

      client = %Client{token: token, http_client: {Telegramex.HTTPClient, []}}

      assert_raise KeyError, ~r"key :name not found", fn ->
        API.call(client, "coolOperation", %{some: "body"})
      end
    end

    test "custom http client", %{bypass: bypass} do
      defmodule CustomHTTPClient do
        def request(method, url, headers, body, opts) do
          send(self(), {:request, method, url, headers, body, opts})

          {:ok, %{status: 200, headers: [], body: "body"}}
        end
      end

      token = "token"
      client = %Client{token: token, http_client: {CustomHTTPClient, [custom: "options"]}}

      assert API.call(client, "coolOperation", %{some: "body"}) == {:ok, "body"}

      assert_received {:request, method, url, headers, body, opts}

      assert method == :post
      assert url == "https://api.telegram.org/bot#{token}/coolOperation"
      assert body == Jason.encode!(%{some: "body"})
      assert headers == [{"content-type", "application/json"}]
      assert opts == [custom: "options"]
    end
  end
end
