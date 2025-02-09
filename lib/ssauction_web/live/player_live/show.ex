defmodule SSAuctionWeb.PlayerLive.Show do
  use SSAuctionWeb, :live_view

  alias SSAuction.Accounts
  alias SSAuction.Players
  alias SSAuction.Auctions
  alias SSAuction.Teams
  alias SSAuction.Bids
  alias SSAuction.Repo

  @impl true
  def mount(_params, session, socket) do
    current_user =
      if Map.has_key?(session, "user_token") do
        Accounts.get_user_by_session_token(session["user_token"])
      else
        nil
      end

    socket =
      socket
      |> assign_locale()
      |> assign_timezone()
      |> assign_timezone_offset()
      |> assign(:current_user, current_user)
      |> assign(:changeset, Ecto.Changeset.cast({%{}, %{}}, %{}, []))

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _, socket) do
    id = params["id"]
    player = Players.get_player!(id)

    rostered_player =
      if player.rostered_player_id == nil do
        nil
      else
        Repo.preload(player, :rostered_player).rostered_player |> Repo.preload(:team)
      end

    auction = Auctions.get_auction!(player.auction_id)
    back_to = params["back_to"] || "auction"

    links =
      cond do
        String.starts_with?(back_to, "nomination_queue-") ->
          "nomination_queue-" <> team_id = back_to
          team = Teams.get_team!(String.to_integer(team_id))

          [
            %{label: "#{auction.name} auction", to: "/auction/#{auction.id}"},
            %{label: "#{team.name}", to: "/team/#{team.id}"},
            %{label: "nomination queue", to: "/team/#{team.id}/nomination_queue"}
          ]

        player.rostered_player_id != nil and back_to == "team" ->
          [
            %{label: "#{auction.name} auction", to: "/auction/#{auction.id}"},
            %{label: "#{rostered_player.team.name}", to: "/team/#{rostered_player.team.id}"},
            %{label: "rostered players", to: "/team/#{rostered_player.team.id}/rostered_players"}
          ]

        player.rostered_player_id != nil and back_to == "auction" ->
          [
            %{label: "#{auction.name} auction", to: "/auction/#{auction.id}"},
            %{label: "rostered players", to: "/auction/#{auction.id}/rostered_players"}
          ]

        back_to == "team" ->
          team = ((Players.get_player!(id) |> Repo.preload(:bid)).bid |> Repo.preload(:team)).team

          [
            %{label: "#{auction.name} auction", to: "/auction/#{auction.id}"},
            %{label: "#{team.name}", to: "/team/#{team.id}"},
            %{label: "bids", to: "/team/#{team.id}/bids"}
          ]

        true ->
          [
            %{label: "#{auction.name} auction", to: "/auction/#{auction.id}"},
            %{label: "bids", to: "/auction/#{auction.id}/bids"}
          ]
      end

    current_team =
      if socket.assigns.current_user != nil do
        Teams.get_team_by_user_and_auction(socket.assigns.current_user, auction)
      else
        nil
      end

    current_value =
      if socket.assigns.current_user != nil do
        Players.get_value(player, current_team)
      else
        nil
      end

    {:noreply,
     socket
     |> assign(:player, player)
     |> assign(:rostered_player, rostered_player)
     |> assign(:bid_logs, Bids.list_bid_logs(player))
     |> assign(:links, links)
     |> assign(:current_team, current_team)
     |> assign(:current_value, current_value)}
  end

  @impl true
  def handle_event("validate-change", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("change", params, socket) do
    new_value = String.to_integer(params["changeset"]["value"])

    {:ok, current_value} =
      if socket.assigns.current_value != nil do
        Players.update_value(socket.assigns.current_value, %{value: new_value})
      else
        Players.create_value(socket.assigns.player, socket.assigns.current_team, new_value)
      end

    {:noreply, assign(socket, :current_value, current_value)}
  end

  defp get_current_value(value_struct) do
    if value_struct != nil, do: value_struct.value, else: 0
  end
end
