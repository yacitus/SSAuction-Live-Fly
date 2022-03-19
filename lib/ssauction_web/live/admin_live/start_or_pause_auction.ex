defmodule SSAuctionWeb.AdminLive.StartOrPauseAuction do
  use SSAuctionWeb, :live_view

  alias SSAuction.Auctions
  alias SSAuction.Bids

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign_locale()
      |> assign_timezone()
      |> assign_timezone_offset()

    {:ok, socket}
  end

  def handle_params(%{"id" => id}, _, socket) do
    auction = Auctions.get_auction!(id)
    {:noreply, assign(socket, :auction, auction)}
  end

  def handle_event("validate-start-or-pause", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("start-or-pause", _params, socket) do
    {:ok, auction} =
      if socket.assigns.auction.active do
        Auctions.pause_auction(socket.assigns.auction)
      else
        Auctions.start_auction(socket.assigns.auction)
      end

    {:noreply, assign(socket, :auction, auction)}
  end
end
