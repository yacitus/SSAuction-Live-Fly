defmodule SSAuctionWeb.AdminLive.AddNewPlayersToAuction do
  use SSAuctionWeb, :live_view

  alias SSAuction.Auctions
  alias SSAuction.Players

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

    socket =
      socket
      |> assign(:auction, auction)
      |> assign(:num_players_in_auction, Players.num_players_in_auction(auction))
      |> assign(:players_not_in_auction, Players.players_not_in_auction(auction))

    {:noreply, socket}
  end

  def handle_event("validate-add", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("add", _params, socket) do
    Auctions.add_players_not_in_auction(socket.assigns.auction)

    socket =
      socket
      |> assign(:num_players_in_auction, Players.num_players_in_auction(socket.assigns.auction))
      |> assign(:players_not_in_auction, Players.players_not_in_auction(socket.assigns.auction))

    {:noreply, socket}
  end
end
