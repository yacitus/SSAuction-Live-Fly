defmodule SSAuctionWeb.TeamLive.Edit do
  use SSAuctionWeb, :live_view
  on_mount SSAuctionWeb.UserLiveAuth

  alias SSAuction.Teams
  alias SSAuction.Auctions

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign_locale()
      |> assign_timezone()
      |> assign_timezone_offset()
      |> assign(:changeset, Ecto.Changeset.cast({%{}, %{}}, %{}, []))

    {:ok, socket}
  end

  def handle_params(%{"id" => id}, _, socket) do
    team = Teams.get_team!(id)

    if Teams.user_in_team?(team, socket.assigns.current_user) do
      socket =
        socket
        |> assign(:team, team)
        |> assign(:auction, Auctions.get_auction!(team.auction_id))

      {:noreply, socket}
    else
      socket = put_flash(socket, :error, "You must be a team owner to access this page.")
      {:noreply, redirect(socket, to: "/team/#{id}")}
    end
  end

  def handle_event("validate-edit", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("edit", params, socket) do
    {:ok, team} = Teams.update_team(socket.assigns.team, %{name: params["changeset"]["name"]})

    {:noreply, assign(socket, :team, team)}
  end
end
