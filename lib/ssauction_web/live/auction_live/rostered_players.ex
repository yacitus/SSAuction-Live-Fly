defmodule SSAuctionWeb.AuctionLive.RosteredPlayers do
  use SSAuctionWeb, :live_view

  alias SSAuction.Auctions
  alias SSAuction.Players
  alias SSAuction.Repo

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign_locale()
      |> assign_timezone()
      |> assign_timezone_offset()
  
    {:ok, socket, temporary_assigns: [rostered_players: []]}
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
       |> assign(:rostered_players, Auctions.get_rostered_players_with_rostered_at(auction, sort_options))
       |> assign(:options, sort_options)
       |> assign(:links, [%{label: "#{auction.name} auction", to: "/auction/#{auction.id}"}])
    }
  end

  @impl true
  def handle_event("rostered_player", %{"id" => id}, socket) do
    rostered_player = Players.get_rostered_player!(id) |> Repo.preload([:player])
    {:noreply, redirect(socket, to: Routes.player_show_path(socket, :show, rostered_player.player.id))}
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
