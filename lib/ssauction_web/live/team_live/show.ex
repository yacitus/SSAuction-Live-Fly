defmodule SSAuctionWeb.TeamLive.Show do
  use SSAuctionWeb, :live_view

  alias SSAuction.Accounts
  alias SSAuction.Teams
  alias SSAuction.Teams.Team
  alias SSAuction.Bids
  alias SSAuction.Auctions

  @impl true
  def mount(_params, session, socket) do
    if connected?(socket), do: Teams.subscribe()

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
    team = Teams.get_team!(id)
    auction = Auctions.get_auction!(team.auction_id)
    users = Teams.get_users(team)
    {:noreply,
     socket
       |> assign(:team, team)
       |> assign(:dollars_available, Teams.total_dollars(team))
       |> assign(:dollars_spent, Teams.dollars_spent(team))
       |> assign(:dollars_bid_including_hidden, Teams.dollars_bid_including_hidden(team))
       |> assign(:dollars_bid, Teams.dollars_bid(team))
       |> assign(:number_of_bids, Bids.number_of_bids(team))
       |> assign(:number_of_rostered_players, Teams.number_of_rostered_players(team))
       |> assign(:dollars_remaining_for_bids_including_hidden, Teams.dollars_remaining_for_bids_including_hidden(team))
       |> assign(:dollars_remaining_for_bids, Teams.dollars_remaining_for_bids(team))
       |> assign(:links, [%{label: "#{auction.name} auction", to: "/auction/#{auction.id}"}])
       |> assign(:users, users)
    }
  end

  @impl true
  def handle_info({:user_added, team = %Team{}}, socket) do
    socket =
      if team.id == socket.assigns.team.id do
        assign(socket, :users, Teams.get_users(team))
      else
        socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_info({:info_change, team = %Team{}}, socket) do
    socket =
      if team.id == socket.assigns.team.id do
        socket
          |> assign(:team, Teams.get_team!(team.id))
          |> assign(:dollars_available, Teams.total_dollars(team))
          |> assign(:dollars_spent, Teams.dollars_spent(team))
          |> assign(:dollars_bid_including_hidden, Teams.dollars_bid_including_hidden(team))
          |> assign(:dollars_bid, Teams.dollars_bid(team))
          |> assign(:number_of_bids, Bids.number_of_bids(team))
          |> assign(:number_of_rostered_players, Teams.number_of_rostered_players(team))
      else
        socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_info({:bid_change, team = %Team{}}, socket) do
    socket =
      if team.id == socket.assigns.team.id do
        socket
          |> assign(:team, Teams.get_team!(team.id))
          |> assign(:dollars_available, Teams.total_dollars(team))
          |> assign(:dollars_spent, Teams.dollars_spent(team))
          |> assign(:dollars_bid_including_hidden, Teams.dollars_bid_including_hidden(team))
          |> assign(:dollars_bid, Teams.dollars_bid(team))
          |> assign(:number_of_bids, Bids.number_of_bids(team))
          |> assign(:number_of_rostered_players, Teams.number_of_rostered_players(team))
          |> assign(:dollars_remaining_for_bids_including_hidden, Teams.dollars_remaining_for_bids_including_hidden(team))
          |> assign(:dollars_remaining_for_bids, Teams.dollars_remaining_for_bids(team))
      else
        socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_info({_, _}, socket) do
    {:noreply, socket} # ignore
  end

  defp current_user_in_team?(team, current_user) do
    current_user != nil and Teams.user_in_team?(team, current_user)
  end
end
