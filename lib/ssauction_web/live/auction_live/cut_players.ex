defmodule SSAuctionWeb.AuctionLive.CutPlayers do
  use SSAuctionWeb, :live_view

  alias SSAuction.Auctions
  alias SSAuction.Auctions.Auction
  alias SSAuction.Players
  alias SSAuction.Repo

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Auctions.subscribe()
    end

    socket =
      socket
      |> assign_locale()
      |> assign_timezone()
      |> assign_timezone_offset()

    {:ok, socket, temporary_assigns: [cut_players: []]}
  end

  @impl true
  def handle_params(params, _, socket) do
    id = params["id"]
    auction = Auctions.get_auction!(id)

    sort_by = (params["sort_by"] || "cut_at") |> String.to_atom()
    sort_order = (params["sort_order"] || "desc") |> String.to_atom()
    sort_options = %{sort_by: sort_by, sort_order: sort_order}

    {:noreply,
     socket
     |> assign(:auction, auction)
     |> assign(:cut_players, Auctions.get_cut_players_with_cut_at_and_cost(auction, sort_options))
     |> assign(:options, sort_options)
     |> assign(:links, [%{label: "#{auction.name} auction", to: "/auction/#{auction.id}"}])}
  end

  @impl true
  def handle_event("cut_player", %{"id" => id}, socket) do
    cut_player = Players.get_cut_player!(id) |> Repo.preload([:player])
    {:noreply, redirect(socket, to: Routes.player_show_path(socket, :show, cut_player.player.id))}
  end

  @impl true
  def handle_info({:roster_change, auction = %Auction{}}, socket) do
    socket =
      if auction.id == socket.assigns.auction.id do
        assign(
          socket,
          :cut_players,
          Auctions.get_cut_players_with_cut_at_and_cost(auction, socket.assigns.sort_options)
        )
      else
        socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_info({_, _}, socket) do
    # ignore
    {:noreply, socket}
  end

  defp sort_link(socket, text, sort_by, auction_id, options) do
    {text, sort_order} =
      if sort_by == options.sort_by do
        {text <> emoji(options.sort_order), toggle_sort_order(options.sort_order)}
      else
        {text, options.sort_order}
      end

    live_patch(text,
      to:
        Routes.live_path(
          socket,
          __MODULE__,
          auction_id,
          sort_by: sort_by,
          sort_order: sort_order
        )
    )
  end
end
