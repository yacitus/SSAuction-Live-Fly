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
        assign(socket, :team, team)
      else
        socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_info({_, _}, socket) do
    {:noreply, socket} # ignore
  end

  defp current_user_in_team(team, current_user) do
    current_user != nil and Teams.user_in_team(team, current_user)
  end
end
