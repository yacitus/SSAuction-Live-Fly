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
    player = Repo.preload(player, :rostered_player)
    rostered_player = player.rostered_player
    rostered_player = Repo.preload(rostered_player, :team)
    auction = Auctions.get_auction!(rostered_player.auction_id)
    back_to = params["back_to"] || "auction"
    links = if back_to == "team" do
      [%{label: "#{auction.name} auction", to: "/auction/#{auction.id}"},
       %{label: "#{rostered_player.team.name}", to: "/team/#{rostered_player.team.id}"},
       %{label: "rostered players", to: "/team/#{rostered_player.team.id}/rosteredplayers"}]
    else
      [%{label: "#{auction.name} auction", to: "/auction/#{auction.id}"},
       %{label: "rostered players", to: "/auction/#{auction.id}/rosteredplayers"}]
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
