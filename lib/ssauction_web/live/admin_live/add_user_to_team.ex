defmodule SSAuctionWeb.AdminLive.AddUserToTeam do
  use SSAuctionWeb, :live_view

  alias SSAuction.Teams
  alias SSAuction.Auctions
  alias SSAuction.Accounts

  def mount(_params, _session, socket) do
     socket =
      socket
      |> assign(:changeset, Ecto.Changeset.cast({%{}, %{}}, %{}, []))
      |> assign(:users, [])
      |> assign(:users_not_in_auction, [])

   {:ok, socket}
  end

  def handle_params(params, _, socket) do
    id = params["id"]
    team = Teams.get_team!(id)
    auction = Auctions.get_auction!(team.auction_id)

    socket =
      socket
      |> assign(:team, team)
      |> assign(:auction, auction)
      |> assign(:users, Teams.get_users(team))
      |> assign(:users_not_in_auction, Auctions.get_users_not_in_auction(auction))

    {:noreply, socket}
  end

  def handle_event("validate-add", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("add", params, socket) do
    [user_id] = params["changeset"]["user"]
    user_id = String.to_integer(user_id)
    user = Accounts.get_user!(user_id)
    Teams.add_user(socket.assigns.team, user)

    socket =
      socket
      |> assign(:users, Teams.get_users(socket.assigns.team))
      |> assign(:users_not_in_auction, Auctions.get_users_not_in_auction(socket.assigns.auction))

    {:noreply, push_patch(socket, to: Routes.live_path(socket, SSAuctionWeb.AdminLive.AddUserToTeam, socket.assigns.team.id))}
  end

  defp users_not_in_auction_selections(_socket, users_not_in_auction) do
    Enum.zip(Enum.map(users_not_in_auction, fn user -> user.username <> " - " <> user.email end),
             Enum.map(users_not_in_auction, fn user -> user.id end))
  end
end
