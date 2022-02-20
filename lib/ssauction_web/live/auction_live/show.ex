defmodule SSAuctionWeb.AuctionLive.Show do
  use SSAuctionWeb, :live_view

  alias SSAuction.Auctions
  alias SSAuction.Teams
  alias SSAuction.Bids

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Auctions.subscribe()

     socket =
      socket
      |> assign_locale()
      |> assign_timezone()
      |> assign_timezone_offset()

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _, socket) do
    id = params["id"]
    auction = Auctions.get_auction!(id)

    sort_by = (params["sort_by"] || "id") |> String.to_atom()
    sort_order = (params["sort_order"] || "asc") |> String.to_atom()
    sort_options = %{sort_by: sort_by, sort_order: sort_order}

    {:noreply,
     socket
       |> assign(:auction, auction)
       |> assign(:options, sort_options)
       |> assign(:teams, Auctions.get_teams(auction, sort_options))
    }
  end

  @impl true
  def handle_event("team", %{"id" => id}, socket) do
    {:noreply, redirect(socket, to: Routes.team_show_path(socket, :show, id))}
  end

  @impl true
  def handle_info({:team_added, auction}, socket) do
    socket =
      if auction.id == socket.assigns.auction.id do
        assign(socket, :teams, Auctions.get_teams(auction))
      else
        socket
      end

    {:noreply, socket}
  end

  defp sort_link(socket, text, sort_by, auction_id, options) do
    text =
      if sort_by == options.sort_by do
        text <> emoji(options.sort_order)
      else
        text
      end

    live_patch(text,
      to:
        Routes.live_path(
          socket,
          __MODULE__,
          auction_id,
          sort_by: sort_by,
          sort_order: toggle_sort_order(options.sort_order)
        )
    )
  end

  defp toggle_sort_order(:asc), do: :desc
  defp toggle_sort_order(:desc), do: :asc

  defp emoji(:asc), do: " ⬇️"
  defp emoji(:desc), do: " ⬆️"
end
