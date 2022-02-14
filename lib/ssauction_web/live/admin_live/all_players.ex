defmodule SSAuctionWeb.AdminLive.AllPlayers do
  use SSAuctionWeb, :live_view

  alias SSAuction.Players

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:year_and_league, "")
      |> assign(:num_players, Players.count_all_players())
  
    {:ok, socket, temporary_assigns: [all_players: []]}
  end

  @impl true
  def handle_params(params, _, socket) do
    year_and_league = (params["year_and_league"] || "")
    num_players =
      if year_and_league == "" do
        Players.count_all_players()
      else
        Players.count_all_players(year_and_league)
      end

    all_players =
      if year_and_league != "" do
        Players.list_all_players(year_and_league)
      else
        []
      end

    {:noreply,
     socket
       |> assign(:year_and_league, year_and_league)
       |> assign(:num_players, num_players)
       |> assign(:all_players, all_players)
    }
  end
end
