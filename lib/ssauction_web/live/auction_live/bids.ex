defmodule SSAuctionWeb.AuctionLive.Bids do
  use SSAuctionWeb, :live_view

  alias SSAuction.Auctions
  alias SSAuction.Bids
  alias SSAuction.Bids.Bid

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Bids.subscribe()

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

  @impl true
  def handle_info({:new_nomination, bid = %Bid{}}, socket) do
    socket =
      if bid.auction_id == socket.assigns.auction.id do
        assign(socket, :bids, Bids.list_bids(socket.assigns.auction))
      else
        socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_info({_, _}, socket) do
    {:noreply, socket} # ignore
  end
end
