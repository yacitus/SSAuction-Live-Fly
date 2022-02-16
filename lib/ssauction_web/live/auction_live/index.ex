defmodule SSAuctionWeb.AuctionLive.Index do
  use SSAuctionWeb, :live_view

  alias SSAuction.Auctions
  alias SSAuctionWeb.Router.Helpers, as: Routes

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Auctions.subscribe()

    {:ok, assign(socket, :auctions, Auctions.list_auctions())}
  end

  @impl true
  def handle_event("auction", %{"id" => id}, socket) do
    {:noreply, redirect(socket, to: Routes.auction_show_path(socket, :show, id))}
  end

  @impl true
  def handle_info({_event, _auction}, socket) do
    {:noreply, assign(socket, :auctions, Auctions.list_auctions())}
  end
end
