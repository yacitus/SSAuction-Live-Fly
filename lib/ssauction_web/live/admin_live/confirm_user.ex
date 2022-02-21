defmodule SSAuctionWeb.AdminLive.ConfirmUser do
  use SSAuctionWeb, :live_view

  alias SSAuction.Accounts
  alias SSAuction.Repo

  def mount(_params, _session, socket) do
     socket =
      socket
      |> assign(:changeset, Ecto.Changeset.cast({%{}, %{}}, %{}, []))
      |> assign(:confirmed_users, Accounts.get_confirmed_users())
      |> assign(:users_not_confirmed, Accounts.get_users_not_confirmed())

   {:ok, socket}
  end

  def handle_event("validate-confirm", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("confirm", params, socket) do
    [user_id] = params["changeset"]["user"]
    user_id = String.to_integer(user_id)
    user = Accounts.get_user!(user_id)
    IO.inspect(user)
    Repo.transaction(Accounts.confirm_user_multi(user))

    socket =
      socket
      |> assign(:confirmed_users, Accounts.get_confirmed_users())
      |> assign(:users_not_confirmed, Accounts.get_users_not_confirmed())

    {:noreply, socket}
  end

  defp users_not_confirmed_selections(_socket, users_not_confirmed) do
    Enum.zip(Enum.map(users_not_confirmed, fn user -> user.username <> " - " <> user.email end),
             Enum.map(users_not_confirmed, fn user -> user.id end))
  end
end
