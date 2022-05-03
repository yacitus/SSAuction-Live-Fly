defmodule SSAuctionWeb.AdminLive.StopNominations do
  use SSAuctionWeb, :live_view

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

  def handle_params(params, _, socket) do
    auction = Auctions.get_auction!(params["id"])

    socket =
      socket
      |> assign(:auction, auction)
      |> assign(:teams, Auctions.get_teams(auction))

    {:noreply, socket}
  end

  def handle_event("validate-change", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("change", params, socket) do
    {:ok, reset_nominations_open_at_date} = Date.from_iso8601(params["changeset"]["reset_nominations_open_at_date"])

    Auctions.stop_nominations(socket.assigns.auction, reset_nominations_open_at_date)

    {:noreply, assign(socket, :teams, Auctions.get_teams(socket.assigns.auction))}
  end
end
