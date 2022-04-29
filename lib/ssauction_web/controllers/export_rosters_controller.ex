
defmodule SSAuctionWeb.ExportRostersController do
  use SSAuctionWeb, :controller

  alias SSAuction.Auctions
  alias SSAuction.Teams

  def create(conn, params) do
    auction_id = String.to_integer(params["auction_id"])
    auction = Auctions.get_auction!(auction_id)
    teams = Auctions.list_teams(auction)
    txt_data = Enum.reduce(teams, "",
                           fn team, text -> "#{text}#{team.name}\n\n#{team_roster(team)}\n\n" end)

    conn
    |> put_resp_content_type("text/txt")
    |> put_resp_header("content-disposition", "attachment; filename=\"rosters.txt\"")
    |> put_root_layout(false)
    |> send_resp(200, txt_data)
  end

  defp team_roster(team) do
    rostered_players = Teams.get_rostered_players_with_rostered_at(team)
    Enum.reduce(rostered_players, "",
                fn rostered_player, text
                -> "#{text}#{rostered_player.player_ssnum} #{rostered_player.player_name}\n" end)
  end
end
