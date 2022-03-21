defmodule SSAuctionWeb.AuctionLive.Bids do
  use SSAuctionWeb, :live_view

  alias SSAuction.Accounts
  alias SSAuction.Auctions
  alias SSAuction.Auctions.Auction
  alias SSAuction.Bids
  alias SSAuction.Bids.Bid
  alias SSAuction.Teams

  @impl true
  def mount(_params, session, socket) do
    if connected?(socket) do
      Bids.subscribe()
      Auctions.subscribe()
    end

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
  
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    auction = Auctions.get_auction!(id)
    {:noreply,
     socket
       |> assign(:auction, auction)
       |> assign(:bids, Bids.list_bids_with_expires_in(auction))
       |> assign(:links, [%{label: "#{auction.name} auction", to: "/auction/#{auction.id}"}])
    }
  end

  @impl true
  def handle_info({:new_nomination, bid = %Bid{}}, socket) do
    socket =
      if bid.auction_id == socket.assigns.auction.id do
        assign(socket, :bids, Bids.list_bids_with_expires_in(socket.assigns.auction))
      else
        socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_info({:bid_expiration_update, auction = %Auction{}}, socket) do
    socket =
      if auction.id == socket.assigns.auction.id do
        assign(socket, :bids, Bids.list_bids_with_expires_in(socket.assigns.auction))
      else
        socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_info({:bid_change, auction = %Auction{}}, socket) do
    socket =
      if auction.id == socket.assigns.auction.id do
        assign(socket, :bids, Bids.list_bids_with_expires_in(socket.assigns.auction))
      else
        socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_info({_, _}, socket) do
    {:noreply, socket} # ignore
  end

  defp current_user_in_team(team, current_user) do
    current_user != nil and Teams.user_in_team(team, current_user)
  end
end
