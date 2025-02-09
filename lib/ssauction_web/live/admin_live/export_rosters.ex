defmodule SSAuctionWeb.AdminLive.ExportRosters do
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

  def handle_params(%{"id" => id}, _, socket) do
    auction = Auctions.get_auction!(id)
    {:noreply, assign(socket, :auction, auction)}
  end

  def handle_event("validate-export", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("export", params, socket) do
    {:noreply,
     redirect(socket,
       to:
         Routes.export_rosters_path(socket, :create,
           auction_id: socket.assigns.auction.id,
           start_date: params["changeset"]["start_date"]
         )
     )}
  end
end
