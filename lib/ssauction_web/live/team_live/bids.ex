defmodule SSAuctionWeb.TeamLive.Bids do
  use SSAuctionWeb, :live_view

  alias SSAuction.Teams
  alias SSAuction.Auctions
  alias SSAuction.Bids
  alias SSAuction.Bids.Bid

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Bids.subscribe()

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
    {:noreply,
     socket
       |> assign(:team, team)
       |> assign(:auction, auction)
       |> assign(:bids, Bids.list_bids(team))
       |> assign(:links, [%{label: "#{auction.name} auction", to: "/auction/#{auction.id}"},
                          %{label: "#{team.name}", to: "/team/#{id}"}])
    }
  end

  @impl true
  def handle_info({:new_nomination, bid = %Bid{}}, socket) do
    socket =
      if bid.team_id == socket.assigns.team.id do
        assign(socket, :bids, Bids.list_bids(socket.assigns.team))
      else
        socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_info({_, _}, socket) do
    {:noreply, socket} # ignore
  end
end
