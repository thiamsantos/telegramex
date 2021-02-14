defmodule Telegramex.Client do
  @moduledoc """
  Provides credentials and connection details for making requests to Telegram Bot API.

  ## Options

  - `token` - (required) Telegram Bot token.
  - `base_url` - (optional) Telegram Bot API base url. Default: `https://api.telegram.org`.
  - `http_client` - (optional) Custom HTTP Client. Accepts a tuple with a module and a list of options.
    The module must implement the callback `c:Telegramex.HTTPClient.request/5`.

  ## Usage

      client = %Telegramex.Client{token: "123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11"}

  """

  @enforce_keys [:token]
  defstruct token: nil,
            base_url: "https://api.telegram.org",
            http_client: {Telegramex.HTTPClient, [name: Telegramex.HTTPClient]}

  @type t :: %__MODULE__{
          token: String.t(),
          base_url: String.t(),
          http_client: {module(), Keyword.t()}
        }
end
