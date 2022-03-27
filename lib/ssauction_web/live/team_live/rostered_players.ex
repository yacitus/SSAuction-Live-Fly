defmodule SSAuctionWeb.TeamLive.RosteredPlayers do
  use SSAuctionWeb, :live_view

  alias SSAuction.Teams
  alias SSAuction.Teams.Team
  alias SSAuction.Auctions
  alias SSAuction.Players
  alias SSAuction.Repo

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Teams.subscribe()
    end

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

    sort_by = (params["sort_by"] || "rostered_at") |> String.to_atom()
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

  @impl true
  def handle_info({:roster_change, team = %Team{}}, socket) do
    socket =
      if team.id == socket.assigns.team.id do
        assign(socket, :rostered_players, Teams.get_rostered_players_with_rostered_at(team, socket.assigns.sort_options))
      else
        socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_info({_, _}, socket) do
    {:noreply, socket} # ignore
  end

  defp sort_link(socket, text, sort_by, team_id, options) do
    {text, sort_order} =
      if sort_by == options.sort_by do
        {text <> emoji(options.sort_order), toggle_sort_order(options.sort_order)}
      else
        {text, options.sort_order}
      end

    live_patch(text,
      to:
        Routes.live_path(
          socket,
          __MODULE__,
          team_id,
          sort_by: sort_by,
          sort_order: sort_order
        )
    )
  end
end
