defmodule SSAuctionWeb.AdminLive.UncutPlayer do
  use SSAuctionWeb, :live_view

  alias SSAuction.Auctions
  alias SSAuction.Players
  alias SSAuction.Bids
  alias SSAuction.Repo

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign_locale()
      |> assign_timezone()
      |> assign_timezone_offset()
      |> assign(show_modal: false)

    {:ok, socket}
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
     |> assign(show_modal: false)
     |> assign(:links, [%{label: "#{auction.name} auction", to: "/auction/#{auction.id}"}])}
  end

  @impl true
  def handle_event("uncut-player", %{"id" => id}, socket) do
    player_to_uncut = Players.get_cut_player!(id) |> Repo.preload([:player, :team])

    {:noreply,
     socket
     |> assign(:player_to_uncut, player_to_uncut)
     |> assign(:show_modal, true)}
  end

  @impl true
  def handle_event("validate-uncut-player", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("submit-uncut-player", _params, socket) do
    Bids.reroster_cut_player(socket.assigns.player_to_uncut)
    {:noreply, push_patch_to_live_path(socket)}
  end

  @impl true
  def handle_event("close", _params, socket) do
    {:noreply, socket |> assign(:show_modal, false)}
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

  defp push_patch_to_live_path(socket) do
    push_patch(socket,
      to:
        Routes.live_path(
          socket,
          __MODULE__,
          socket.assigns.auction.id,
          sort_by: socket.assigns.options.sort_by,
          sort_order: socket.assigns.options.sort_order
        )
    )
  end
end
