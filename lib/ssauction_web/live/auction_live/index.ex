defmodule SSAuctionWeb.AuctionLive.Index do
  use SSAuctionWeb, :live_view

  alias SSAuction.Accounts
  alias SSAuction.Auctions
  alias SSAuctionWeb.Router.Helpers, as: Routes

  @impl true
  def mount(_params, session, socket) do
    if connected?(socket), do: Auctions.subscribe()

    current_user =
      if Map.has_key?(session, "user_token") do
        Accounts.get_user_by_session_token(session["user_token"])
      else
        nil
      end

    socket =
      socket
      |> assign(:current_user, current_user)
      |> assign(:auctions, Auctions.list_auctions())

    {:ok, socket}
  end

  @impl true
  def handle_event("auction", %{"id" => id}, socket) do
    {:noreply, redirect(socket, to: Routes.live_path(socket, SSAuctionWeb.AuctionLive.Show, id))}
  end

  @impl true
  def handle_info({:auction_started_or_paused, _}, socket) do
    {:noreply, assign(socket, :auctions, Auctions.list_auctions())}
  end

  @impl true
  def handle_info({_, _}, socket) do
    # ignore
    {:noreply, socket}
  end
end
