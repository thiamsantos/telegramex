defmodule Telegramex.API do
  @moduledoc false

  def call(client, method, body) do
    initial_metadata = %{method: method, body: body}

    :telemetry.span([:telegramex, :call], initial_metadata, fn ->
      case do_call(client, method, body) do
        {:ok, response} ->
          {{:ok, response.body}, Map.put(initial_metadata, :response, response)}

        {:error, error} ->
          {{:error, error}, Map.put(initial_metadata, :error, error)}
      end
    end)
  end

  defp do_call(client, method, body) do
    {http_mod, http_opts} = client.http_client

    url =
      client.base_url
      |> URI.parse()
      |> Map.update!(:path, fn path ->
        Path.join([path || "/", "bot#{client.token}", method])
      end)
      |> URI.to_string()

    headers = [{"content-type", "application/json"}]

    with {:ok, encoded_body} <- Jason.encode(body),
         {:ok, response} <-
           apply(http_mod, :request, [:post, url, headers, encoded_body, http_opts]),
         {:ok, response} <- json_decode(response) do
      if response.status == 200 do
        {:ok, response}
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
