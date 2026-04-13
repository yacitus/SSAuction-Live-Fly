defmodule SSAuction.Pushover do
  @moduledoc """
  Sends notifications via the Pushover API.
  """

  require Logger

  @pushover_url ~c"https://api.pushover.net/1/messages.json"

  def notify_player_cut(auction, team, player) do
    user_key = System.get_env("PUSHOVER_USER_KEY")
    api_token = System.get_env("PUSHOVER_API_TOKEN")

    if user_key && api_token do
      message =
        "Player cut: #{player.name} (ID: #{player.id}, ssnum: #{player.ssnum}) " <>
          "from team #{team.name} (ID: #{team.id}) " <>
          "in auction #{auction.name} (ID: #{auction.id})"

      body =
        URI.encode_query(%{
          "token" => api_token,
          "user" => user_key,
          "message" => message,
          "title" => "Player Cut: #{player.name}"
        })

      :httpc.request(
        :post,
        {@pushover_url, [], ~c"application/x-www-form-urlencoded", String.to_charlist(body)},
        [],
        []
      )
      |> case do
        {:ok, {{_, 200, _}, _headers, _body}} ->
          Logger.info("Pushover notification sent for cut player #{player.id}")
          :ok

        {:ok, {{_, status, _}, _headers, resp_body}} ->
          Logger.error("Pushover notification failed with status #{status}: #{resp_body}")
          {:error, status}

        {:error, reason} ->
          Logger.error("Pushover notification request failed: #{inspect(reason)}")
          {:error, reason}
      end
    else
      Logger.warning("Pushover credentials not configured, skipping notification")
      :ok
    end
  end
end
