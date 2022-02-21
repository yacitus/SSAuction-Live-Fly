defmodule SSAuctionWeb.AdminLive.AddUserToAuctionAdmins do
  use SSAuctionWeb, :live_view

  alias SSAuction.Auctions
  alias SSAuction.Accounts

  def mount(_params, _session, socket) do
     socket =
      socket
      |> assign(:changeset, Ecto.Changeset.cast({%{}, %{}}, %{}, []))
      |> assign(:auction_admin_users, [])
      |> assign(:users_in_auction, [])

   {:ok, socket}
  end

  def handle_params(params, _, socket) do
    id = params["id"]
    auction = Auctions.get_auction!(id)

    socket =
      socket
      |> assign(:auction, auction)
      |> assign(:auction_admin_users, Auctions.get_admin_users(auction))
      |> assign(:users_in_auction, Auctions.get_users_in_auction(auction))

    {:noreply, socket}
  end

  def handle_event("validate-add", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("add", params, socket) do
    [user_id] = params["changeset"]["user"]
    user_id = String.to_integer(user_id)
    user = Accounts.get_user!(user_id)
    Auctions.add_user_to_auction_admins(socket.assigns.auction, user)

    socket =
      socket
      |> assign(:auction_admin_users, Auctions.get_admin_users(socket.assigns.auction))
      |> assign(:users_in_auction, Auctions.get_users_in_auction(socket.assigns.auction))

    {:noreply, socket}
  end

  defp users_in_auction_selections(users_in_auction) do
    Enum.zip(Enum.map(users_in_auction, fn user -> user.username <> " - " <> user.email end),
             Enum.map(users_in_auction, fn user -> user.id end))
  end
end
