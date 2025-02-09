defmodule SSAuctionWeb.AdminLive.CreateTeam do
  use SSAuctionWeb, :live_view

  alias SSAuction.Auctions
  alias SSAuction.Teams

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign_locale()
      |> assign_timezone()
      |> assign_timezone_offset()
      |> assign(:changeset, Ecto.Changeset.cast({%{}, %{}}, %{}, []))
      |> assign(:teams, [])

    {:ok, socket}
  end

  def handle_params(params, _, socket) do
    id = params["id"]
    auction = Auctions.get_auction!(id)

    socket =
      socket
      |> assign(:auction, auction)
      |> assign(:teams, Auctions.get_teams(auction))

    {:noreply, socket}
  end

  def handle_event("validate-create", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("create", params, socket) do
    {:ok, new_nominations_open_at_date} =
      Date.from_iso8601(params["changeset"]["new_nominations_open_at_date"])

    {:ok, new_nominations_open_at_time} =
      Time.from_iso8601(params["changeset"]["new_nominations_open_at_time"] <> ":00")

    {:ok, nomination_time} =
      DateTime.new(
        new_nominations_open_at_date,
        new_nominations_open_at_time,
        socket.assigns.timezone
      )

    {:ok, nomination_time} = DateTime.shift_zone(nomination_time, "Etc/UTC")
    nomination_time = DateTime.truncate(nomination_time, :second)

    Auctions.create_team(socket.assigns.auction,
      name: params["changeset"]["name"],
      new_nominations_open_at: nomination_time
    )

    socket = assign(socket, :teams, Auctions.get_teams(socket.assigns.auction))

    {:noreply, socket}
  end
end
