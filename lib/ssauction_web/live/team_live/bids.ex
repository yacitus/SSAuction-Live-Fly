defmodule SSAuctionWeb.TeamLive.Bids do
  use SSAuctionWeb, :live_view

  alias SSAuction.Teams
  alias SSAuction.Auctions
  alias SSAuction.Bids

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
  def handle_params(%{"id" => id}, _, socket) do
    team = Teams.get_team!(id)
    auction = Auctions.get_auction!(team.auction_id)
    {:noreply,
     socket
       |> assign(:auction, Auctions.get_auction!(team.auction_id))
       |> assign(:bids, Bids.list_bids(team))
       |> assign(:links, [%{label: "#{auction.name} auction", to: "/auction/#{auction.id}"},
                          %{label: "#{team.name}", to: "/team/#{id}"}])
    }
  end
end
