
defmodule SSAuctionWeb.ExportRostersController do
  use SSAuctionWeb, :controller

  alias SSAuction.Auctions
  alias SSAuction.Teams

  def create(conn, params) do
    auction_id = String.to_integer(params["auction_id"])
    auction = Auctions.get_auction!(auction_id)

    {:ok, true} = Cachex.put(:auction_rostered_players, auction_id,
      Auctions.get_rostered_players_with_rostered_at_no_cache(auction))

    start_date =
      case Date.from_iso8601(params["start_date"]) do
        {:ok, start_date} ->
          start_date
        _ ->
          nil
      end
    teams = Auctions.list_teams_with_ssnum(auction)
    txt_data = Enum.reduce(teams, "",
                           fn team, text -> "#{text}#{team.ssnum} - #{team.name}\n\n#{team_roster(team, start_date)}\n\n" end)

    conn
    |> put_resp_content_type("text/txt")
    |> put_resp_header("content-disposition", "attachment; filename=\"rosters.txt\"")
    |> put_root_layout(false)
    |> send_resp(200, txt_data)
  end

  defp team_roster(team, nil) do
    Teams.get_rostered_players_with_rostered_at(team, %{sort_by: :rostered_at, sort_order: :desc})
    |> Enum.reduce("", fn rostered_player, text
                        -> "#{text}#{rostered_player.player_ssnum} #{rostered_player.player_name}\n" end)
  end

  defp team_roster(team, start_date) do
    Teams.get_rostered_players_with_rostered_at(team, %{sort_by: :rostered_at, sort_order: :desc})
    |> Enum.filter(fn rostered_player ->
                     rostered_date = DateTime.to_date(rostered_player.rostered_at)
                     Date.compare(start_date, rostered_date) != :gt
                   end)
    |> Enum.reduce("", fn rostered_player, text
                        -> "#{text}#{rostered_player.player_ssnum} #{rostered_player.player_name} - #{rostered_player.rostered_at}\n" end)
  end
end
