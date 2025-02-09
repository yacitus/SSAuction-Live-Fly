defmodule SSAuctionWeb.AdminLive.ChangeTeamNewNominationsOpenAt do
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

    {:ok, socket}
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

    Teams.update_team(socket.assigns.team, %{new_nominations_open_at: nomination_time})

    {:noreply, socket}
  end
end
