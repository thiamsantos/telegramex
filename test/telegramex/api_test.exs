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

      Bypass.expect_once(bypass, "POST", "/somepath/bot#{token}/coolMethod", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        assert Jason.decode!(body) == %{"some" => "body"}

        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(200, ~s({"ok": true, "result": []}))
      end)

      assert API.call(client, "coolMethod", %{some: "body"}) ==
               {:ok, %{"ok" => true, "result" => []}}
    end

    test "skip decoding when hasn't content type json", %{bypass: bypass} do
      token = "token"

      client = %Client{token: token, base_url: "http://localhost:#{bypass.port}"}

      Bypass.expect_once(bypass, "POST", "/bot#{token}/coolMethod", fn conn ->
        Plug.Conn.resp(conn, 200, ~s({"ok": true, "result": []}))
      end)

      assert API.call(client, "coolMethod", %{some: "body"}) ==
               {:ok, ~s({"ok": true, "result": []})}
    end

    test "fails to decode json", %{bypass: bypass} do
      token = "token"

      client = %Client{token: token, base_url: "http://localhost:#{bypass.port}"}

      Bypass.expect_once(bypass, "POST", "/bot#{token}/coolMethod", fn conn ->
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(200, ~s({malformed'json))
      end)

      assert {:error, %Jason.DecodeError{}} = API.call(client, "coolMethod", %{some: "body"})
    end

    test "http client missing options" do
      token = "token"

      client = %Client{token: token, http_client: {Telegramex.HTTPClient, []}}

      assert_raise KeyError, ~r"key :name not found", fn ->
        API.call(client, "coolMethod", %{some: "body"})
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

      assert API.call(client, "coolMethod", %{some: "body"}) == {:ok, "body"}

      assert_received {:request, method, url, headers, body, opts}

      assert method == :post
      assert url == "https://api.telegram.org/bot#{token}/coolMethod"
      assert body == Jason.encode!(%{some: "body"})
      assert headers == [{"content-type", "application/json"}]
      assert opts == [custom: "options"]
    end

    test "telemetry start", %{bypass: bypass, test: test_name} do
      token = "token"

      client = %Client{token: token, base_url: "http://localhost:#{bypass.port}"}

      Bypass.expect_once(bypass, "POST", "/bot#{token}/coolMethod", fn conn ->
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(200, ~s({"ok": true, "result": []}))
      end)

      :telemetry.attach(
        to_string(test_name),
        [:telegramex, :call, :start],
        fn name, measurements, metadata, config ->
          send(self(), {:telemetry, name, measurements, metadata, config})
        end,
        nil
      )

      assert {:ok, _} = API.call(client, "coolMethod", %{some: "body"})

      assert_received {:telemetry, [:telegramex, :call, :start], measurements, metadata, config}

      assert is_integer(measurements.system_time)
      assert metadata == %{body: %{some: "body"}, method: "coolMethod"}
      assert config == nil

      :telemetry.detach(to_string(test_name))
    end

    test "telemetry stop", %{bypass: bypass, test: test_name} do
      token = "token"

      client = %Client{token: token, base_url: "http://localhost:#{bypass.port}"}

      Bypass.expect_once(bypass, "POST", "/bot#{token}/coolMethod", fn conn ->
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(200, ~s({"ok": true, "result": []}))
      end)

      :telemetry.attach(
        to_string(test_name),
        [:telegramex, :call, :stop],
        fn name, measurements, metadata, config ->
          send(self(), {:telemetry, name, measurements, metadata, config})
        end,
        nil
      )

      assert {:ok, _} = API.call(client, "coolMethod", %{some: "body"})

      assert_received {:telemetry, [:telegramex, :call, :stop], measurements, metadata, config}

      assert is_integer(measurements.duration)
      assert %{body: %{some: "body"}, method: "coolMethod", response: response} = metadata
      assert %{body: %{"ok" => true, "result" => []}, headers: headers, status: 200} = response
      assert {"content-type", "application/json"} in headers
      assert config == nil

      :telemetry.detach(to_string(test_name))
    end

    test "telemetry stop with error", %{bypass: bypass, test: test_name} do
      token = "token"

      client = %Client{token: token, base_url: "http://localhost:#{bypass.port}"}

      Bypass.expect_once(bypass, "POST", "/bot#{token}/coolMethod", fn conn ->
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(
          401,
          ~s({"description": "Unauthorized", "error_code": 401, "ok": false})
        )
      end)

      :telemetry.attach(
        to_string(test_name),
        [:telegramex, :call, :stop],
        fn name, measurements, metadata, config ->
          send(self(), {:telemetry, name, measurements, metadata, config})
        end,
        nil
      )

      assert {:error, _} = API.call(client, "coolMethod", %{some: "body"})

      assert_received {:telemetry, [:telegramex, :call, :stop], measurements, metadata, config}

      assert is_integer(measurements.duration)
      assert %{body: %{some: "body"}, method: "coolMethod", error: error} = metadata

      assert %{
               body: %{"ok" => false, "description" => "Unauthorized", "error_code" => 401},
               headers: headers,
               status: 401
             } = error

      assert {"content-type", "application/json"} in headers
      assert config == nil

      :telemetry.detach(to_string(test_name))
    end

    test "telemetry exception", %{test: test_name} do
      token = "token"

      client = %Client{token: token, http_client: {Telegramex.HTTPClient, []}}

      :telemetry.attach(
        to_string(test_name),
        [:telegramex, :call, :exception],
        fn name, measurements, metadata, config ->
          send(self(), {:telemetry, name, measurements, metadata, config})
        end,
        nil
      )

      assert_raise KeyError, ~r"key :name not found", fn ->
        API.call(client, "coolMethod", %{some: "body"})
      end

      assert_received {:telemetry, [:telegramex, :call, :exception], measurements, metadata,
                       config}

      assert is_integer(measurements.duration)
      assert %{method: "coolMethod", kind: :error, reason: %KeyError{}, stacktrace: _} = metadata
      assert config == nil

      :telemetry.detach(to_string(test_name))
    end
  end
end
