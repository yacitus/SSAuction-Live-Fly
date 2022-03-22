defmodule SSAuctionWeb.PlayerLive.Show do
  use SSAuctionWeb, :live_view

  alias SSAuction.Players
  alias SSAuction.Auctions
  alias SSAuction.Bids
  alias SSAuction.Repo

  @impl true
  def mount(_params, _session, socket) do
     socket =
      socket
      |> assign_locale()
      |> assign_timezone()
      |> assign_timezone_offset()

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
        player.rostered_player_id != nil and back_to == "team" ->
          [%{label: "#{auction.name} auction", to: "/auction/#{auction.id}"},
           %{label: "#{rostered_player.team.name}", to: "/team/#{rostered_player.team.id}"},
           %{label: "rostered players", to: "/team/#{rostered_player.team.id}/rostered_players"}]
        player.rostered_player_id != nil and back_to == "auction" ->
          [%{label: "#{auction.name} auction", to: "/auction/#{auction.id}"},
           %{label: "rostered players", to: "/auction/#{auction.id}/rostered_players"}]
        back_to == "team" ->
          team = ((Players.get_player!(id) |> Repo.preload(:bid)).bid |> Repo.preload(:team)).team
          [%{label: "#{auction.name} auction", to: "/auction/#{auction.id}"},
           %{label: "#{team.name}", to: "/team/#{team.id}"},
           %{label: "bids", to: "/team/#{team.id}/bids"}]
        true ->
          [%{label: "#{auction.name} auction", to: "/auction/#{auction.id}"},
           %{label: "bids", to: "/auction/#{auction.id}/bids"}]
      end

    {:noreply,
     socket
       |> assign(:player, player)
       |> assign(:rostered_player, rostered_player)
       |> assign(:bid_logs, Bids.list_bid_logs(player))
       |> assign(:links, links)
    }
  end
end
