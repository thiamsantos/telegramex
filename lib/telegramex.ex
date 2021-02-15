defmodule Telegramex do
  @moduledoc """
  Documentation for `Telegramex`.
  """

  alias Telegramex.{API, Client}

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
  @spec get_updates(Client.t(), Keyword.t()) :: {:ok, map()} | {:error, term()}
  def get_updates(%Client{} = client, opts \\ []) when is_list(opts) do
    API.call(
      client,
      "getUpdates",
      opts |> Keyword.take([:offset, :limit, :timeout, :allowed_updates]) |> Map.new()
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
  @spec answer_inline_query(Client.t(), String.t(), [map()], Keyword.t()) ::
          {:ok, map()} | {:error, term()}
  def answer_inline_query(%Client{} = client, inline_query_id, results, opts \\ [])
      when is_binary(inline_query_id) and is_list(results) and is_list(opts) do
    API.call(
      client,
      "answerInlineQuery",
      opts
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
      |> Map.new()
    )
  end
end
