defmodule SSAuction.Auctions do
  @moduledoc """
  The Auctions context.
  """

  import Ecto.Query, warn: false
  alias SSAuction.Repo

  alias SSAuction.Auctions.Auction
  alias SSAuction.Players.AllPlayer
  alias SSAuction.Players.Player
  alias SSAuction.Players.OrderedPlayer
  alias SSAuction.Players.RosteredPlayer
  alias SSAuction.Bids.BidLog
  alias SSAuction.Bids.Bid
  alias SSAuction.Teams.Team
  alias SSAuction.Teams
  alias SSAuction.Accounts
  alias SSAuction.Accounts.User

  def subscribe do
    Phoenix.PubSub.subscribe(SSAuction.PubSub, "auctions")
  end

  @doc """
  Returns the list of auctions.

  ## Examples

      iex> list_auctions()
      [%Auction{}, ...]

  """
  def list_auctions do
    Repo.all(Auction)
  end

  @doc """
  Gets a single auction.

  Raises `Ecto.NoResultsError` if the Auction does not exist.

  ## Examples

      iex> get_auction!(123)
      %Auction{}

      iex> get_auction!(456)
      ** (Ecto.NoResultsError)

  """
  def get_auction!(id), do: Repo.get!(Auction, id)

  @doc """
  Creates an auction.

  """
  def create_auction(name: name,
                     year_range: year_range,
                     nominations_per_team: nominations_per_team,
                     seconds_before_autonomination: seconds_before_autonomination,
                     new_nominations_created: new_nominations_created,
                     initial_bid_timeout_seconds: initial_bid_timeout_seconds,
                     bid_timeout_seconds: bid_timeout_seconds,
                     players_per_team: players_per_team,
                     must_roster_all_players: must_roster_all_players,
                     team_dollars_per_player: team_dollars_per_player) do

    {:ok, now} = DateTime.now("Etc/UTC")
    now = now
          |> DateTime.truncate(:second)
          |> DateTime.add(-now.second, :second)


    auction =
      %Auction{
        name: name,
        year_range: year_range,
        nominations_per_team: nominations_per_team,
        seconds_before_autonomination: seconds_before_autonomination,
        new_nominations_created: new_nominations_created,
        initial_bid_timeout_seconds: initial_bid_timeout_seconds,
        bid_timeout_seconds: bid_timeout_seconds,
        players_per_team: players_per_team,
        must_roster_all_players: must_roster_all_players,
        team_dollars_per_player: team_dollars_per_player,
        started_or_paused_at: now
        } |> Repo.insert!

    q = from p in AllPlayer,
          where: p.year_range == ^year_range,
          select: p
    Repo.all(q)
    |> Enum.each(fn player -> %Player{}
                              |> Player.changeset(%{
                                   year_range: player.year_range,
                                   name: player.name,
                                   ssnum: player.ssnum,
                                   position: player.position,
                                   auction_id: auction.id
                                 })
                              |> Repo.insert!
                 end)
    broadcast({:ok, auction}, :auction_created)
    auction
  end

  def broadcast({:ok, auction}, event) do
    Phoenix.PubSub.broadcast(
      SSAuction.PubSub,
      "auctions",
      {event, auction}
    )
    {:ok, auction}
  end

  def broadcast({:error, _reason} = error, _event), do: error

  @doc """
  Updates a auction.

  ## Examples

      iex> update_auction(auction, %{field: new_value})
      {:ok, %Auction{}}

      iex> update_auction(auction, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_auction(%Auction{} = auction, attrs) do
    auction
    |> Auction.changeset(attrs)
    |> Repo.update()
    |> broadcast(:auction_updated)
  end

  @doc """
  Deletes a auction.

  ## Examples

      iex> delete_auction(auction)
      {:ok, %Auction{}}

      iex> delete_auction(auction)
      {:error, %Ecto.Changeset{}}

  """
  def delete_auction(%Auction{} = auction) do
    Repo.delete_all(from bl in BidLog, where: bl.auction_id == ^auction.id)
    Repo.delete_all(from op in OrderedPlayer, where: op.auction_id == ^auction.id)
    Repo.all(from t in Team, where: t.auction_id == ^auction.id)
    |> Enum.each(fn team ->
                   Repo.delete_all(from op in OrderedPlayer, where: op.team_id == ^team.id)
                   Repo.all(from b in Bid, where: b.team_id == ^team.id)
                   |> Enum.each(fn bid ->
                                  player = Repo.preload(bid, [:player]).player
                                  if player do
                                    player
                                    |> Ecto.Changeset.change(%{bid_id: nil})
                                    |> Repo.update
                                  end
                                  Repo.delete!(bid)
                                end)
                   Repo.all(from rp in RosteredPlayer, where: rp.team_id == ^team.id)
                   |> Enum.each(fn rostered_player ->
                                  player = Repo.preload(rostered_player, [:player]).player
                                  if player do
                                    player
                                    |> Ecto.Changeset.change(%{rostered_player_id: nil})
                                    |> Repo.update
                                  end
                                  Repo.delete!(rostered_player)
                                end)
                   Repo.delete_all(from r in "teams_users", where: r.team_id == ^team.id, select: [r.id, r.team_id, r.user_id])
                   Repo.delete!(team)
                 end)
    Repo.delete_all(from r in "auctions_users", where: r.auction_id == ^auction.id, select: [r.id, r.auction_id, r.user_id])
    Repo.delete_all(from p in Player, where: p.auction_id == ^auction.id)
    Repo.delete!(auction)
    broadcast({:ok, auction}, :auction_deleted)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking auction changes.

  ## Examples

      iex> change_auction(auction)
      %Ecto.Changeset{data: %Auction{}}

  """
  def change_auction(%Auction{} = auction, attrs \\ %{}) do
    Auction.changeset(auction, attrs)
  end

  defp append(string1, string2) do
    if String.length(string1) > 0 do
      string1 <> ", " <> string2
    else
      string2
    end
  end

  defp pluralize(number) do
    if number > 1 do
      "s"
    else
      ""
    end
  end

  def seconds_to_string(seconds) do
    string = ""
    days = div(seconds, 86400)
    string = if days != 0 do
      append(string, Integer.to_string(days) <> " day" <> pluralize(days))
    else
      string
    end
    seconds = rem(seconds, 86400)
    hours = div(seconds, 3600)
    string = if hours != 0 do
      append(string, Integer.to_string(hours) <> " hour" <> pluralize(hours))
    else
      string
    end
    seconds = rem(seconds, 3600)
    minutes = div(seconds, 60)
    string = if minutes != 0 do
      append(string, Integer.to_string(minutes) <> " minute" <> pluralize(minutes))
    else
      string
    end
    seconds = rem(seconds, 60)
    if seconds != 0 do
      append(string, Integer.to_string(seconds) <> " second" <> pluralize(seconds))
    else
      string
    end
  end

  def active_emoji(auction) do
    if auction.active do
      "✅"
    else    
      "❌"
    end
  end

  def dedup_years(%Auction{} = auction) do
    years_and_league = correct_league(auction.year_range)

    case Regex.named_captures(~r/(?<year1>\d{4})-(?<year2>\d{4})-(?<league>\w\w)/, years_and_league) do
      %{"year1" => year1, "year2" => year2, "league" => league} ->
        if year1 == year2 do
          year1 <> "-" <> league
        else
          years_and_league
        end
      _ ->
       years_and_league 
    end
  end

  defp correct_league(year_range) do
    if String.slice(year_range, -2, 2) == "SL" do
      String.slice(year_range, 0..-3) <> "CL"
    else
      year_range
    end
  end

  def get_admin_users(%Auction{} = auction) do
    Enum.sort_by(Repo.preload(auction, [:admins]).admins, fn user -> user.username end)
  end

  def add_user_to_auction_admins(%Auction{} = auction, %User{} = user) do
    auction = Repo.preload(auction, [:admins])
    changeset = Ecto.Changeset.change(auction)
      |> Ecto.Changeset.put_assoc(:admins, [user | auction.admins])
    Repo.update!(changeset)
  end

  def get_rostered_players(%Auction{} = auction) do
    auction
      |> Ecto.assoc(:rostered_players)
      |> Repo.all
      |> Repo.preload([:player, :team])
  end

  alias SSAuction.Bids

  def get_rostered_players_with_rostered_at(%Auction{} = auction) do
    get_rostered_players(auction)
    |> Enum.map(fn rp -> rp
                         |> Map.put(:rostered_at, Bids.rostered_bid_log(rp.player).updated_at)
                         |> Map.put(:team_name, rp.team.name)
                         |> Map.put(:player_name, rp.player.name)
                         |> Map.put(:player_position, rp.player.position)
                         |> Map.put(:player_ssnum, rp.player.ssnum)
                end)
  end

  def get_rostered_players_with_rostered_at(%Auction{} = auction, %{sort_by: sort_by, sort_order: sort_order}) do
    get_rostered_players_with_rostered_at(auction)
    |> Enum.sort_by(fn rp -> Map.get(rp, sort_by) end, sort_order)
  end

  def number_of_rostered_players(%Auction{} = auction) do
    auction
      |> Ecto.assoc(:rostered_players)
      |> Repo.aggregate(:count, :id)
  end

  def get_teams(%Auction{} = auction) do
    Repo.preload(auction, [:teams]).teams
    |> Enum.map(fn team -> team
                           |> Map.put(:dollars_spent, Teams.dollars_spent(team))
                           |> Map.put(:time_nominations_expire, Teams.time_nominations_expire(team))
                           |> Map.put(:number_of_rostered_players, Teams.number_of_rostered_players(team))
                end)
  end

  def get_teams(%Auction{} = auction, %{sort_by: sort_by, sort_order: sort_order}) do
    get_teams(auction)
    |> Enum.sort_by(fn rp -> Map.get(rp, sort_by) end, sort_order)
  end

  def create_team(%Auction{} = auction,
                  name: team_name,
                  new_nominations_open_at: new_nominations_open_at) do
    team = Ecto.build_assoc(auction, :teams, %{name: team_name, new_nominations_open_at: new_nominations_open_at, unused_nominations: 0})
    Repo.insert!(team)
    broadcast({:ok, auction}, :team_added)
  end

  def get_users_not_in_auction(%Auction{} = auction) do
    all_user_ids = Repo.all(from u in User, select: u.id, order_by: u.username)
    user_ids_not_in_auction = all_user_ids -- get_auction_user_ids(auction)
    Enum.map(user_ids_not_in_auction, fn id -> Accounts.get_user!(id) end)
  end

  def get_users_in_auction(%Auction{} = auction) do
    Enum.map(get_auction_user_ids(auction), fn id -> Accounts.get_user!(id) end)
  end

  defp get_auction_user_ids(%Auction{} = auction) do
    Enum.sort(Enum.map(Enum.concat(Enum.map(Repo.preload(auction, [:teams]).teams, fn t -> Repo.preload(t, [:users]).users end)), fn u -> u.id end))
  end

  def dollars_per_team(%Auction{} = auction) do
    auction.players_per_team * auction.team_dollars_per_player
  end

  def players_in_autonomination_queue(%Auction{} = auction) do
    query = from op in OrderedPlayer,
              where: op.auction_id == ^auction.id,
              join: p in assoc(op, :player),
              preload: [player: p],
              order_by: :rank
    Repo.all(query)
  end

  @doc """
  Returns a query of all players in the auction's bids

  """
  def players_in_bids_query(auction = %Auction{}) do
    from a in Auction,
      where: a.id == ^auction.id,
      join: bids in assoc(a, :bids),
      join: player in assoc(bids, :player),
      select: player
  end

  @doc """
  Returns a query of all players rostered in the auction

  """
  def players_rostered_in_query(auction = %Auction{}) do
    from a in Auction,
      where: a.id == ^auction.id,
      join: rostered_players in assoc(a, :rostered_players),
      join: player in assoc(rostered_players, :player),
      select: player
  end

  @doc """
  Returns a query of all players in the auction

  """
  def players_in_query(auction = %Auction{}) do
    from player in Player,
      where: player.auction_id == ^auction.id,
      select: player
  end
end
