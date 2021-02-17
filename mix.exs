defmodule Telegramex.MixProject do
  use Mix.Project

  @version "0.1.0"
  @description "Telegram's Bot API wrapper"
  @source_url "https://github.com/thiamsantos/telegramex"

  def project do
    [
      app: :telegramex,
      version: @version,
      name: "Telegramex",
      description: @description,
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      package: package(),
      test_coverage: [tool: ExCoveralls]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:jason, "~> 1.2"},
      {:telemetry, "~> 0.4.2"},
      {:finch, "~> 0.5", optional: true},
      {:bypass, "~> 2.1", only: :test},
      {:plug, "~> 1.11", only: :test},
      {:ex_doc, ">= 0.19.0", only: :dev, runtime: false},
      {:excoveralls, "~> 0.13.3", only: :test}
    ]
  end

  defp docs do
    [
      main: "Telegramex",
      source_ref: "v#{@version}",
      source_url: @source_url,
      extras: ["CHANGELOG.md"]
    ]
  end

  defp package do
    %{
      licenses: ["Apache-2.0"],
      maintainers: ["Thiago Santos"],
      links: %{"GitHub" => @source_url}
    }
  end
end
