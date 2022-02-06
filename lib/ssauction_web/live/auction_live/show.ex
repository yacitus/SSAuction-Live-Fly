defmodule SSAuctionWeb.AuctionLive.Show do
  use SSAuctionWeb, :live_view

  alias SSAuction.Auctions
  alias SSAuction.Teams
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
       |> assign(:teams, Auctions.get_teams(auction))
    }
  end

  @impl true
  def handle_event("team", %{"id" => id}, socket) do
    {:noreply, redirect(socket, to: Routes.team_show_path(socket, :show, id))}
  end
end
