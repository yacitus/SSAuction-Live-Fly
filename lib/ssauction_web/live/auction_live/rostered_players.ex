defmodule SSAuctionWeb.AuctionLive.RosteredPlayers do
  use SSAuctionWeb, :live_view

  alias SSAuction.Accounts
  alias SSAuction.Auctions
  alias SSAuction.Auctions.Auction
  alias SSAuction.Players
  alias SSAuction.Teams
  alias SSAuction.Repo

  @impl true
  def mount(_params, session, socket) do
    if connected?(socket) do
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

    {:ok, socket, temporary_assigns: [rostered_players: []]}
  end

  @impl true
  def handle_params(params, _, socket) do
    id = params["id"]
    auction = Auctions.get_auction!(id)

    current_team =
      if socket.assigns.current_user != nil do
        Teams.get_team_by_user_and_auction(socket.assigns.current_user, auction)
      else
        nil
      end

    sort_by = (params["sort_by"] || "rostered_at") |> String.to_atom()
    sort_order = (params["sort_order"] || "desc") |> String.to_atom()
    sort_options = %{sort_by: sort_by, sort_order: sort_order}

    {:noreply,
     socket
     |> assign(:auction, auction)
     |> assign(:current_team, current_team)
     |> assign(
       :rostered_players,
       Auctions.get_rostered_players_with_rostered_at_and_surplus(
         auction,
         current_team,
         sort_options
       )
     )
     |> assign(:options, sort_options)
     |> assign(:links, [%{label: "#{auction.name} auction", to: "/auction/#{auction.id}"}])}
  end

  @impl true
  def handle_event("rostered_player", %{"id" => id}, socket) do
    rostered_player = Players.get_rostered_player!(id) |> Repo.preload([:player])

    {:noreply,
     redirect(socket, to: Routes.player_show_path(socket, :show, rostered_player.player.id))}
  end

  @impl true
  def handle_info({:roster_change, auction = %Auction{}}, socket) do
    socket =
      if auction.id == socket.assigns.auction.id do
        assign(
          socket,
          :rostered_players,
          Auctions.get_rostered_players_with_rostered_at_and_surplus(
            auction,
            socket.assigns.current_team,
            socket.assigns.sort_options
          )
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
