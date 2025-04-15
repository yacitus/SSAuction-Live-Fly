defmodule SSAuctionWeb.AdminLive.ChangeTeamUnusedNominations do
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
      |> assign(:unused_nominations, team.unused_nominations)

    {:noreply, socket}
  end

  def handle_event("validate-change", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("change", params, socket) do
    unused_nominations = String.to_integer(params["changeset"]["unused_nominations"])

    {:ok, team} = Teams.update_team(socket.assigns.team, %{unused_nominations: unused_nominations})

    socket =
      socket
      |> assign(:team, team)
      |> assign(:unused_nominations, team.unused_nominations)

    {:noreply, socket}
  end
end
