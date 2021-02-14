defmodule Telegramex do
  @moduledoc """
  Documentation for `Telegramex`.
  """

  alias Telegramex.Client

  @doc """
  Use this method to receive incoming updates using long polling.

  ## Options

  - `offset` - (optional)
  - `limit` - (optional)
  - `timeout` - (optional)
  - `allowed_updates` - (optional)

  Checkout the [Telegram Bot API Documentation](https://core.telegram.org/bots/api#getupdates)
  for a complete description of each option.

  ## Usage

      client = %Telegramex.Client{token: "123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11"}
      Telegramex.get_updates(client)

  """
  # https://core.telegram.org/bots/api#getupdates
  def get_updates(%Client{} = client, opts \\ []) when is_list(opts) do
    request(
      client,
      "getUpdates",
      Keyword.take(opts, [:offset, :limit, :timeout, :allowed_updates])
    )
  end

  @doc """
  Use this method to send answers to an inline query.

  ## Options

  - `cache_time` - (optional)
  - `is_personal` - (optional)
  - `next_offset` - (optional)
  - `switch_pm_text` - (optional)
  - `switch_pm_parameter` - (optional)

  Checkout the [Telegram Bot API Documentation](https://core.telegram.org/bots/api#answerinlinequery)
  for a complete description of each option.

  ## Usage

      client = %Telegramex.Client{token: "123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11"}
      Telegramex.answer_inline_query(client, "2648678931644704387", results)

  """
  def answer_inline_query(%Client{} = client, inline_query_id, results, opts \\ [])
      when is_binary(inline_query_id) and is_list(results) and is_list(opts) do
    request(
      client,
      "answerInlineQuery",
      opts
      # TODO improve handling of arguments
      |> Keyword.take([
        :cache_time,
        :is_personal,
        :cache_time,
        :is_personal,
        :next_offset,
        :switch_pm_text,
        :switch_pm_parameter
      ])
      |> Keyword.merge(inline_query_id: inline_query_id, results: results)
    )
  end

  defp request(client, operation, opts) do
    {http_mod, http_opts} = client.http_client

    # TODO test when url has path
    # TODO test when url doesn't have path
    url =
      client.base_url
      |> URI.parse()
      |> Map.update!(:path, fn path ->
        Path.join([path || "/", "bot#{client.token}", operation])
      end)
      |> URI.to_string()

    body = Map.new(opts)

    headers = [{"content-type", "application/json"}]

    with {:ok, encoded_body} <- Jason.encode(body),
         {:ok, response} <-
           apply(http_mod, :request, [:post, url, headers, encoded_body, http_opts]),
         {:ok, decoded_response_body} <- json_decode(response),
         response = %{response | body: decoded_response_body} do
      case response do
        %{status: 200, body: %{"ok" => true} = body} ->
          # TODO encoder https://github.com/zhyu/nadia/blob/master/lib/nadia/parser.ex
          {:ok, body}

        response ->
          {:error, response}
      end
    end
  end

  # TODO test when is not json response
  defp json_decode(%{headers: headers, body: body}) do
    case List.keyfind(headers, "content-type", 0) do
      {_, "application/json"} -> Jason.decode(body)
      _ -> body
    end
  end
end
