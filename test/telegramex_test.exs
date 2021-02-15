defmodule TelegramexTest do
  use ExUnit.Case, async: true

  alias Telegramex.Client

  setup do
    bypass = Bypass.open()
    {:ok, bypass: bypass}
  end

  describe "get_updates/2" do
    test "get updates", %{bypass: bypass} do
      token = "token"

      client = %Client{token: token, base_url: "http://localhost:#{bypass.port}"}

      Bypass.expect_once(bypass, "POST", "/bot#{token}/getUpdates", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        assert body == "{}"

        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(200, ~s({"ok": true, "result": []}))
      end)

      assert Telegramex.get_updates(client) == {:ok, %{"ok" => true, "result" => []}}
    end

    test "accept arguments", %{bypass: bypass} do
      token = "token"

      client = %Client{token: token, base_url: "http://localhost:#{bypass.port}"}

      Bypass.expect_once(bypass, "POST", "/bot#{token}/getUpdates", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)

        assert Jason.decode!(body) == %{
                 "allowed_updates" => ["inline_query"],
                 "limit" => 10,
                 "offset" => 1,
                 "timeout" => 27
               }

        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(200, ~s({"ok": true, "result": []}))
      end)

      assert Telegramex.get_updates(client,
               offset: 1,
               limit: 10,
               timeout: 27,
               allowed_updates: ["inline_query"]
             ) == {:ok, %{"ok" => true, "result" => []}}
    end

    test "handles errors", %{bypass: bypass} do
      token = "token"

      client = %Client{token: token, base_url: "http://localhost:#{bypass.port}"}

      Bypass.expect_once(bypass, "POST", "/bot#{token}/getUpdates", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        assert body == "{}"

        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(
          401,
          ~s({"description": "Unauthorized", "error_code": 401, "ok": false})
        )
      end)

      assert {:error,
              %{
                body: %{"description" => "Unauthorized", "error_code" => 401, "ok" => false},
                status: 401
              }} = Telegramex.get_updates(client)
    end
  end

  describe "answer_inline_query/4" do
    test "success", %{bypass: bypass} do
      result = %{
        type: "article",
        id: "ID",
        title: "Title",
        description: "Description",
        input_message_content: %{
          message_text: "<strong>Message</strong>: Cool message",
          parse_mode: "HTML"
        },
        reply_markup: %{
          inline_keyboard: [
            [
              %{text: "hex", url: "https://hex.pm/"}
            ]
          ]
        }
      }

      inline_query_id = "2648678931602542092"

      token = "token"

      client = %Client{token: token, base_url: "http://localhost:#{bypass.port}"}

      Bypass.expect_once(bypass, "POST", "/bot#{token}/answerInlineQuery", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)

        assert Jason.decode!(body) == %{
                 "inline_query_id" => inline_query_id,
                 "results" => [Jason.decode!(Jason.encode!(result))]
               }

        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(200, ~s({"ok": true, "result": true}))
      end)

      assert Telegramex.answer_inline_query(client, inline_query_id, [result]) ==
               {:ok, %{"ok" => true, "result" => true}}
    end

    test "supports options", %{bypass: bypass} do
      result = %{
        type: "article",
        id: "ID",
        title: "Title",
        description: "Description",
        input_message_content: %{
          message_text: "<strong>Message</strong>: Cool message",
          parse_mode: "HTML"
        },
        reply_markup: %{
          inline_keyboard: [
            [
              %{text: "hex", url: "https://hex.pm/"}
            ]
          ]
        }
      }

      inline_query_id = "2648678931602542092"

      token = "token"

      client = %Client{token: token, base_url: "http://localhost:#{bypass.port}"}

      Bypass.expect_once(bypass, "POST", "/bot#{token}/answerInlineQuery", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)

        assert Jason.decode!(body) == %{
                 "inline_query_id" => inline_query_id,
                 "results" => [Jason.decode!(Jason.encode!(result))],
                 "cache_time" => 300,
                 "is_personal" => false,
                 "next_offset" => "offset",
                 "switch_pm_text" => "text",
                 "switch_pm_parameter" => "deep-link"
               }

        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(200, ~s({"ok": true, "result": true}))
      end)

      assert Telegramex.answer_inline_query(client, inline_query_id, [result],
               cache_time: 300,
               is_personal: false,
               next_offset: "offset",
               switch_pm_text: "text",
               switch_pm_parameter: "deep-link"
             ) ==
               {:ok, %{"ok" => true, "result" => true}}
    end

    test "handle errors", %{bypass: bypass} do
      token = "token"

      client = %Client{token: token, base_url: "http://localhost:#{bypass.port}"}

      Bypass.expect_once(bypass, "POST", "/bot#{token}/answerInlineQuery", fn conn ->
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(
          401,
          ~s({"description": "Unauthorized", "error_code": 401, "ok": false})
        )
      end)

      assert {:error,
              %{
                body: %{"description" => "Unauthorized", "error_code" => 401, "ok" => false},
                status: 401
              }} = Telegramex.answer_inline_query(client, "2648678931602542092", [])
    end
  end
end
