defmodule SSAuctionWeb.AuctionLive.AutoNominationQueue do
  use SSAuctionWeb, :live_view

  alias SSAuction.Auctions

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    auction = Auctions.get_auction!(id)
    {:noreply,
     socket
       |> assign(:auction, auction)
       |> assign(:ordered_players, Auctions.players_in_autonomination_queue(auction))
       |> assign(:links, [%{label: "#{auction.name} auction", to: "/auction/#{auction.id}"}])
    }
  end
end
