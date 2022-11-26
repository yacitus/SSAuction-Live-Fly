defmodule SSAuctionWeb.AuctionLive.Show do
  use SSAuctionWeb, :live_view

  alias SSAuction.Accounts
  alias SSAuction.Auctions
  alias SSAuction.Auctions.Auction
  alias SSAuction.Bids
  alias SSAuction.Teams
  alias SSAuction.Teams.Team

  @impl true
  def mount(_params, session, socket) do
    if connected?(socket) do
      Auctions.subscribe()
      Teams.subscribe()
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
  def handle_params(params, _, socket) do
    id = params["id"]
    auction = Auctions.get_auction!(id)

    sort_by = (params["sort_by"] || "dollars_spent") |> String.to_atom()
    sort_order = (params["sort_order"] || "asc") |> String.to_atom()
    sort_options = %{sort_by: sort_by, sort_order: sort_order}

    {:noreply,
     socket
       |> assign(:auction, auction)
       |> assign(:number_of_bids, Bids.number_of_bids(auction))
       |> assign(:number_of_rostered_players, Auctions.number_of_rostered_players(auction))
       |> assign(:number_of_cut_players, Auctions.number_of_cut_players(auction))
       |> assign(:options, sort_options)
       |> assign(:teams, Auctions.get_teams(auction, sort_options))
    }
  end

  @impl true
  def handle_event("team", %{"id" => id}, socket) do
    {:noreply, redirect(socket, to: Routes.team_show_path(socket, :show, id))}
  end

  @impl true
  def handle_info({:team_added, auction = %Auction{}}, socket) do
    socket =
      if auction.id == socket.assigns.auction.id do
        assign(socket, :teams, Auctions.get_teams(auction, socket.assigns.options))
      else
        socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_info({:info_change, team = %Team{}}, socket) do
    socket =
      if team.auction_id == socket.assigns.auction.id do
        assign(socket, :teams, Auctions.get_teams(socket.assigns.auction, socket.assigns.options))
      else
        socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_info({:teams_info_change, auction = %Auction{}}, socket) do
    socket =
      if auction.id == socket.assigns.auction.id do
        assign(socket, :teams, Auctions.get_teams(auction, socket.assigns.options))
      else
        socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_info({:info_change, auction = %Auction{}}, socket) do
    socket =
      if auction.id == socket.assigns.auction.id do
        socket
          |> assign(:auction, auction)
          |> assign(:number_of_bids, Bids.number_of_bids(auction))
          |> assign(:number_of_rostered_players, Auctions.number_of_rostered_players(auction))
          |> assign(:number_of_cut_players, Auctions.number_of_cut_players(auction))
      else
        socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_info({:bid_change, auction = %Auction{}}, socket) do
    socket =
      if auction.id == socket.assigns.auction.id do
        socket
          |> assign(:auction, auction)
          |> assign(:number_of_bids, Bids.number_of_bids(auction))
          |> assign(:number_of_rostered_players, Auctions.number_of_rostered_players(auction))
      else
        socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_info({_, _}, socket) do
    {:noreply, socket} # ignore
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
