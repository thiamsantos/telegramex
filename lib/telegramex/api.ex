defmodule Telegramex.API do
  @moduledoc false

  def call(client, operation, body) do
    {http_mod, http_opts} = client.http_client

    url =
      client.base_url
      |> URI.parse()
      |> Map.update!(:path, fn path ->
        Path.join([path || "/", "bot#{client.token}", operation])
      end)
      |> URI.to_string()

    headers = [{"content-type", "application/json"}]

    with {:ok, encoded_body} <- Jason.encode(body),
         {:ok, response} <-
           apply(http_mod, :request, [:post, url, headers, encoded_body, http_opts]),
         {:ok, response} <- json_decode(response) do
      if response.status == 200 do
        {:ok, response.body}
      else
        {:error, response}
      end
    end
  end

  defp json_decode(response) do
    if json?(response) do
      with {:ok, body} <- Jason.decode(response.body) do
        {:ok, %{response | body: body}}
      end
    else
      {:ok, response}
    end
  end

  defp json?(%{headers: headers}) do
    case List.keyfind(headers, "content-type", 0) do
      {_, "application/json"} -> true
      _ -> false
    end
  end
end
