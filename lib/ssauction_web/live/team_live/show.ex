defmodule SSAuctionWeb.TeamLive.Show do
  use SSAuctionWeb, :live_view

  alias SSAuction.Teams
  alias SSAuction.Bids
  alias SSAuction.Auctions

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Teams.subscribe()

    socket =
      socket
      |> assign_locale()
      |> assign_timezone()
      |> assign_timezone_offset()
  
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
  def handle_info({:user_added, team}, socket) do
    socket =
      if team.id == socket.assigns.team.id do
        assign(socket, :users, Teams.get_users(team))
      else
        socket
      end

    {:noreply, socket}
  end
end
