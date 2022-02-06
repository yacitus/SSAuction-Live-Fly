defmodule SSAuctionWeb.AuctionLive.Bids do
  use SSAuctionWeb, :live_view

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
    auction = Auctions.get_auction!(id)
    {:noreply,
     socket
       |> assign(:auction, auction)
       |> assign(:bids, Bids.list_bids(auction))
       |> assign(:links, [%{label: "#{auction.name} auction", to: "/auction/#{auction.id}"}])
    }
  end
end
