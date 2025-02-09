defmodule SSAuctionWeb.AdminLive.EditAuction do
  use SSAuctionWeb, :live_view

  alias SSAuction.Auctions
  alias SSAuction.Bids

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
    auction = Auctions.get_auction!(id)
    {:noreply, assign(socket, :auction, auction)}
  end

  def handle_event("validate-change", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("change", params, socket) do
    nominations_per_team = params["changeset"]["nominations_per_team"]

    seconds_before_autonomination =
      String.to_integer(params["changeset"]["seconds_before_autonomination"])

    {:ok, auction} =
      Auctions.update_auction(
        socket.assigns.auction,
        %{
          nominations_per_team: nominations_per_team,
          seconds_before_autonomination: seconds_before_autonomination
        }
      )

    {:noreply, assign(socket, :auction, auction)}
  end
end
