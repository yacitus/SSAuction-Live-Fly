defmodule SSAuctionWeb.AuctionLive.Edit do
  use SSAuctionWeb, :live_view
  on_mount SSAuctionWeb.UserLiveAuth

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
    if Auctions.user_is_admin(auction, socket.assigns.current_user) do
      socket =
        socket
        |> assign(:auction, auction)
      {:noreply, socket}
    else
      socket = put_flash(socket, :error, "You must be an auction admin to access this page.")
      {:noreply, redirect(socket, to: "/auction/#{id}")}
    end
  end

  def handle_event("validate-start-pause", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("start-pause", params, socket) do
    IO.inspect(params)

    {:noreply, socket}
  end
end
