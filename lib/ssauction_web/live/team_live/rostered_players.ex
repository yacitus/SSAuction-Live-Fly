defmodule SSAuctionWeb.TeamLive.RosteredPlayers do
  use SSAuctionWeb, :live_view

  alias SSAuction.Accounts
  alias SSAuction.Teams
  alias SSAuction.Teams.Team
  alias SSAuction.Auctions
  alias SSAuction.Players
  alias SSAuction.Repo

  @impl true
  def mount(_params, session, socket) do
    if connected?(socket) do
      Teams.subscribe()
    end

    current_user =
      if Map.has_key?(session, "user_token") do
        Accounts.get_user_by_session_token(session["user_token"])
      else
        nil
      end

    socket =
      socket
      |> assign_locale()
      |> assign_timezone()
      |> assign_timezone_offset()
      |> assign(:current_user, current_user)
      |> assign(show_modal: false)

    {:ok, socket, temporary_assigns: [rostered_players: []]}
  end

  @impl true
  def handle_params(params, _, socket) do
    id = params["id"]
    team = Teams.get_team!(id)
    auction = Auctions.get_auction!(team.auction_id)

    current_team =
      if socket.assigns.current_user != nil do
        Teams.get_team_by_user_and_auction(socket.assigns.current_user, auction)
      else
        nil
      end

    sort_by = (params["sort_by"] || "rostered_at") |> String.to_atom()
    sort_order = (params["sort_order"] || "desc") |> String.to_atom()
    sort_options = %{sort_by: sort_by, sort_order: sort_order}

    {:noreply,
     socket
     |> assign(:team, team)
     |> assign(:auction, auction)
     |> assign(:current_team, current_team)
     |> assign(
       :rostered_players,
       Teams.get_rostered_players_with_rostered_at_and_surplus(team, current_team, sort_options)
     )
     |> assign(:options, sort_options)
     |> assign(:show_modal, false)
     |> assign(:links, [
       %{label: "#{auction.name} auction", to: "/auction/#{auction.id}"},
       %{label: "#{team.name}", to: "/team/#{id}"}
     ])}
  end

  @impl true
  def handle_event("rostered_players", %{"id" => id}, socket) do
    rostered_player = Players.get_rostered_player!(id) |> Repo.preload([:player])

    {:noreply,
     redirect(socket,
       to: Routes.player_show_path(socket, :show, rostered_player.player.id, back_to: "team")
     )}
  end

  @impl true
  def handle_event("cut-player", %{"id" => id}, socket) do
    player_to_cut = Players.get_rostered_player!(id) |> Repo.preload([:player])

    {:noreply,
     socket
     |> assign(:player_to_cut, player_to_cut)
     |> assign(:player_to_cut_cost, Teams.cut_player_dollar_cost(player_to_cut.cost))
     |> assign(:show_modal, true)}
  end

  @impl true
  def handle_event("validate-cut-player", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("submit-cut-player", _params, socket) do
    Players.cut_player_and_remove_from_rostered_players(socket.assigns.player_to_cut)
    {:noreply, push_patch_to_live_path(socket)}
  end

  @impl true
  def handle_event("close", _params, socket) do
    {:noreply, socket |> assign(:show_modal, false)}
  end

  @impl true
  def handle_info({:roster_change, team = %Team{}}, socket) do
    socket =
      if team.id == socket.assigns.team.id do
        assign(
          socket,
          :rostered_players,
          Teams.get_rostered_players_with_rostered_at_and_surplus(
            team,
            socket.assigns.current_team,
            socket.assigns.sort_options
          )
        )
      else
        socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_info({_, _}, socket) do
    # ignore
    {:noreply, socket}
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

  defp push_patch_to_live_path(socket) do
    push_patch(socket,
      to:
        Routes.live_path(
          socket,
          __MODULE__,
          socket.assigns.team.id,
          sort_by: socket.assigns.options.sort_by,
          sort_order: socket.assigns.options.sort_order
        )
    )
  end
end
