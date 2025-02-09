defmodule SSAuctionWeb.AdminLive.SetTeamSsnum do
  use SSAuctionWeb, :live_view

  alias SSAuction.Auctions
  alias SSAuction.Teams

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :changeset, Ecto.Changeset.cast({%{}, %{}}, %{}, []))}
  end

  def handle_params(params, _, socket) do
    team = Teams.get_team!(params["id"])
    auction = Auctions.get_auction!(team.auction_id)

    socket =
      socket
      |> assign(:team, team)
      |> assign(:auction, auction)

    {:noreply, socket}
  end

  def handle_event("validate-change", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("change", params, socket) do
    ssnum = String.to_integer(params["changeset"]["ssnum"])

    {:ok, team} = Teams.update_team(socket.assigns.team, %{ssnum: ssnum})

    {:noreply, assign(socket, :team, team)}
  end
end
