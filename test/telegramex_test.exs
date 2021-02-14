defmodule TelegramexTest do
  use ExUnit.Case
  doctest Telegramex

  test "greets the world" do
    assert Telegramex.hello() == :world
  end
end
