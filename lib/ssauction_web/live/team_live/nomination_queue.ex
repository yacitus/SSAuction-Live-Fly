defmodule SSAuctionWeb.TeamLive.NominationQueue do
  use SSAuctionWeb, :live_view
  on_mount SSAuctionWeb.UserLiveAuth

  alias SSAuction.Teams
  alias SSAuction.Auctions
  alias SSAuction.Players

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Teams.subscribe()

    socket =
      socket
      |> assign_locale()
      |> assign_timezone()
      |> assign_timezone_offset()
      |> assign(positions: [])
  
    {:ok, socket, temporary_assigns: [players_available_for_nomination: [],
                                      players_in_nomination_queue: []]}
  end

  @impl true
  def handle_params(params, _, socket) do
    id = params["id"]
    team = Teams.get_team!(id)
    if Teams.user_in_team(team, socket.assigns.current_user) do
      sort_by = (params["sort_by"] || "ssnum") |> String.to_atom()
      sort_order = (params["sort_order"] || "asc") |> String.to_atom()
      positions = String.split((params["positions"] || ""), "|", trim: true)
      search = (params["search"] || "")
      options = %{sort_by: sort_by, sort_order: sort_order, positions: positions, search: search}

      auction = Auctions.get_auction!(team.auction_id)

      {:noreply,
       socket
         |> assign(:team, team)
         |> assign(:players_in_nomination_queue, Teams.players_in_nomination_queue(team))
         |> assign(:smallest_rank_in_nomination_queue, Teams.smallest_rank_in_nomination_queue(team))
         |> assign(:players_available_for_nomination, Teams.queueable_players(team, options))
         |> assign(:options, options)
         |> assign(:positions, positions)
         |> assign(:search, search)
         |> assign(:links, [%{label: "#{auction.name} auction", to: "/auction/#{auction.id}"},
                            %{label: "#{team.name}", to: "/team/#{id}"}])
      }
    else
      socket = put_flash(socket, :error, "You must be a team owner to access this page.")
      {:noreply, redirect(socket, to: "/team/#{id}")}
    end
  end

  @impl true
  def handle_event("filter", %{"positions" => positions}, socket) do
    socket =
      push_patch(socket,
        to:
          Routes.live_path(
            socket,
            __MODULE__,
            socket.assigns.team.id,
            positions: Enum.join(positions, "|"),
            search: socket.assigns.search,
            sort_by: socket.assigns.options.sort_by,
            sort_order: socket.assigns.options.sort_order
          )
      )

    {:noreply, socket}
  end

  @impl true
  def handle_event("filter", _params, socket) do
    socket =
      push_patch(socket,
        to:
          Routes.live_path(
            socket,
            __MODULE__,
            socket.assigns.team.id,
            positions: "",
            search: socket.assigns.search,
            sort_by: socket.assigns.options.sort_by,
            sort_order: socket.assigns.options.sort_order
          )
      )

    {:noreply, socket}
  end

  @impl true
  def handle_event("filter-submit", %{"search" => search}, socket) do
    search = String.downcase(search)
    socket =
      push_patch(socket,
        to:
          Routes.live_path(
            socket,
            __MODULE__,
            socket.assigns.team.id,
            positions: Enum.join(socket.assigns.positions, "|"),
            search: search,
            sort_by: socket.assigns.options.sort_by,
            sort_order: socket.assigns.options.sort_order
          )
      )

    {:noreply, socket}
  end

  @impl true
  def handle_event("add-player-to-queue", %{"id" => id}, socket) do
    player = Players.get_player!(id)
    Teams.add_to_nomination_queue(player, socket.assigns.team)

    {:noreply, socket}
  end

  @impl true
  def handle_event("move-to-top-of-queue", %{"id" => id}, socket) do
    ordered_player = Players.get_ordered_player!(id)
    Teams.move_to_top_of_nomination_queue(ordered_player, socket.assigns.team)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:nomination_queue_changed, team}, socket) do
    socket =
      if team.id == socket.assigns.team.id do
        players_in_nomination_queue = Teams.players_in_nomination_queue(team)
        IO.inspect(players_in_nomination_queue)
        socket =
          socket
          |> assign(:players_in_nomination_queue, players_in_nomination_queue)
          |> assign(:smallest_rank_in_nomination_queue, Teams.smallest_rank_in_nomination_queue(team))
      else
        socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_info({:queueable_players_changed, team}, socket) do
    socket =
      if team.id == socket.assigns.team.id do
        assign(socket, :players_available_for_nomination, Teams.queueable_players(team, socket.assigns.options))
      else
        socket
      end

    {:noreply, socket}
  end

  defp position_checkbox(assigns) do
    assigns = Enum.into(assigns, %{})

    ~H"""
    <label>
      <input type="checkbox" id={@position}
             class="hidden peer"
             name="positions[]" value={@position}
             checked={@checked} />
      <div class="inline-block border border-gray-400 bg-gray-300 py-2 px-3 text-lg font-semibold leading-5
                    peer-checked:bg-blue-300 peer-checked:border-blue-500 hover:bg-blue-400 hover:cursor-pointer">
           <%= @position %></div>
               
    </label>
    """
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
          positions: Enum.join(options.positions, "|"),
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
