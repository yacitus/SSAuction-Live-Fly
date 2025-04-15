defmodule SSAuctionWeb.AdminLive.AdminMenu do
  use SSAuctionWeb, :live_view

  alias SSAuction.Auctions

  def mount(_params, _session, socket) do
    auctions = Auctions.list_auctions() |> Enum.sort_by(& &1.name)
    selected_auction = List.last(auctions)
    teams = Auctions.list_teams(selected_auction) |> Enum.sort_by(& &1.name)
    selected_team = List.first(teams)

    socket =
      socket
      |> assign(:auctions, auctions)
      |> assign(:selected_auction_id, selected_auction.id)
      |> assign(:teams, teams)
      |> assign(:selected_team_id, selected_team && selected_team.id)
      |> assign(:changeset, Ecto.Changeset.cast({%{}, %{}}, %{}, []))
      |> assign(:auction_links, auction_links(selected_auction.id))
      |> assign(:team_links, team_links(selected_team && selected_team.id))

    {:ok, socket}
  end

  def handle_event("validate-change", params, socket) do
    socket =
      case params["_target"] do
        ["changeset", "auction-" <> id] ->
          selected_auction_id = String.to_integer(id)
          selected_auction = Auctions.get_auction!(selected_auction_id)
          teams = Auctions.list_teams(selected_auction) |> Enum.sort_by(& &1.name)
          selected_team = List.first(teams)
          socket
          |> assign(:selected_auction_id, selected_auction_id)
          |> assign(:teams, teams)
          |> assign(:selected_team_id, selected_team.id)
          |> assign(:auction_links, auction_links(selected_auction_id))
        ["changeset", "team-" <> id] ->
          selected_team_id = String.to_integer(id)
          socket
          |> assign(:selected_team_id, selected_team_id)
          |> assign(:team_links, team_links(selected_team_id))
        _ ->
          socket
      end

    {:noreply, socket}
  end

  def handle_event("change", _params, socket) do
    {:noreply, socket}
  end

  defp auction_links(selected_auction_id) do
    link_base = "/admin/auction"
    link_pairs = [["create_team", "Create Team"],
                  ["add_admin_user", "Add User To Auction Admins"],
                  ["import_nomination_queue", "Import Nomination Queue"],
                  ["edit", "Edit Auction"],
                  ["start_or_pause", "Start Or Pause Auction"],
                  ["add_new_players", "Add New Players To Auction"],
                  ["remove_player", "Remove Player From Auction"],
                  ["uncut_player", "Un-cut Player"],
                  ["export_rosters", "Export Rosters"],
                  ["stop_nominations", "Stop Nominations"]]

    Enum.map(link_pairs, 
             fn [link_end, link_name] ->
               [link_name, "#{link_base}/#{selected_auction_id}/#{link_end}"]
             end)
  end

  defp team_links(selected_team_id) do
    link_base = "/admin/team"
    link_pairs = [["add_user", "Add User To Team"],
                  ["set_team_ssnum", "Set Team Scoresheet Number"],
                  ["change_team_new_nominations_open_at", "Change Team New Nominations Open At"],
                  ["change_team_total_supplemental_dollars", "Change Team Total Supplemental Dollars"]]

    Enum.map(link_pairs, 
             fn [link_end, link_name] ->
               [link_name, "#{link_base}/#{selected_team_id}/#{link_end}"]
             end)
  end
end
