defmodule SSAuctionWeb.TeamLive.RosteredPlayers do
  use SSAuctionWeb, :live_view

  alias SSAuction.Teams
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
    team = Teams.get_team!(id)
    auction = Auctions.get_auction!(team.auction_id)

    sort_by = (params["sort_by"] || "id") |> String.to_atom()
    sort_order = (params["sort_order"] || "asc") |> String.to_atom()
    sort_options = %{sort_by: sort_by, sort_order: sort_order}

    {:noreply,
     socket
       |> assign(:team, team)
       |> assign(:rostered_players, Teams.get_rostered_players_with_rostered_at(team, sort_options))
       |> assign(:options, sort_options)
       |> assign(:links, [%{label: "#{auction.name} auction", to: "/auction/#{auction.id}"},
                          %{label: "#{team.name}", to: "/team/#{id}"}])
    }
  end

  @impl true
  def handle_event("rostered_players", %{"id" => id}, socket) do
    rostered_player = Players.get_rostered_player!(id) |> Repo.preload([:player])
    {:noreply, redirect(socket, to: Routes.player_show_path(socket, :show, rostered_player.player.id, back_to: "team"))}
  end

  defp sort_link(socket, text, sort_by, team_id, options) do
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
          team_id,
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
