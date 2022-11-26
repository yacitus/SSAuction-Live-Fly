defmodule SSAuctionWeb.AdminLive.RemovePlayerFromAuction do
  use SSAuctionWeb, :live_view

  alias SSAuction.Auctions
  alias SSAuction.Players
  alias SSAuction.Repo

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign_locale()
      |> assign_timezone()
      |> assign_timezone_offset()
      |> assign(:player, nil)
      |> assign(:changeset, Ecto.Changeset.cast({%{}, %{}}, %{}, []))

    {:ok, socket}
  end

  def handle_params(%{"id" => id}, _, socket) do
    auction = Auctions.get_auction!(id)

    socket =
      socket
      |> assign(:auction, auction)
      |> assign(:num_players_in_auction, Players.num_players_in_auction(auction))

    {:noreply, socket}
  end

  def handle_event("validate-find", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("find", params, socket) do
    player = Players.get_player_from_ssnum(socket.assigns.auction, params["changeset"]["ssnum"])
             |> Repo.preload([:bid, :rostered_player])
    {:noreply, assign(socket, :player, player)}
  end

  def handle_event("validate-delete", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("delete", _params, socket) do
    Players.delete_player(socket.assigns.player)
    {:noreply,
     socket
     |> assign(:player, nil)
     |> assign(:num_players_in_auction, Players.num_players_in_auction(socket.assigns.auction))}
  end
end
