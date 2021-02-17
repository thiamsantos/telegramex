# Telegramex

<!-- MDOC !-->

Telegram's Bot API wrapper.

[![Hex.pm Version](http://img.shields.io/hexpm/v/telegramex.svg?style=flat)](https://hex.pm/packages/telegramex)
[![CI](https://github.com/thiamsantos/telegramex/workflows/CI/badge.svg?branch=main)](https://github.com/thiamsantos/telegramex/actions?query=branch%3Amain)
[![Coverage Status](https://coveralls.io/repos/github/thiamsantos/telegramex/badge.svg?branch=main)](https://coveralls.io/github/thiamsantos/telegramex?branch=main)

## Features

- Support for multiple bots
- Configurable HTTP client
- No application configuration

## Usage

1. Add the dependencies

```elixir
def deps do
  [
    {:finch, "~> 0.5"},
    {:telegramex, "~> 0.1.1"}
  ]
end
```
2. Add the [finch](https://github.com/keathley/finch) client to your supervision tree

```elixir
children = [
  {Finch, name: Telegramex.HTTPClient}
]
```

**Note**: Checkout the `Telegramex.Client` on how to use other HTTP client.

3. Make a request

```elixir
client = %Telegramex.Client{token: "123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11"}
Telegramex.get_updates(client)
```

Full documentation can be found at [https://hexdocs.pm/telegramex](https://hexdocs.pm/telegramex).

## Telemetry

Telegramex executes the following events:

  * `[:telegramex, :call, :start]` - Executed before calling the Telegram Bot API.

    #### Measurements
    * `:system_time` - The system time

    #### Metadata:
    * `:method` - The Telegram Bot API method call
    * `:body` - The body of the API call

  * `[:telegramex, :call, :stop]` - Executed after a API call.

    #### Measurements
    * `:duration` - Duration of the API call.

    #### Metadata
    * `:method` - The Telegram Bot API method call
    * `:body` - The body of the API call
    * `:response` - (optional) In case of success (status 200), the response of the api as returned by the HTTP client.
    * `:error` - (optional) In case of a error, returns the error.

  * `[:telegramex, :call, :exception]` - Executed if the API call raises an exception.

    #### Measurements
    * `:duration` - The time it took before raising an exception

    #### Metadata
    * `:method` - The Telegram Bot API method call
    * `:body` - The body of the API call
    * `:kind` - The type of exception.
    * `:error` - Error description or error data.
    * `:stacktrace` - The stacktrace

## Changelog

See the [changelog](CHANGELOG.md).

<!-- MDOC !-->

## Contributing

See the [contributing file](CONTRIBUTING.md).

## License

[Apache License, Version 2.0](LICENSE) © [Thiago Santos](https://github.com/thiamsantos)
