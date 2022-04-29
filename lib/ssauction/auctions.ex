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
  alias SSAuction.Players
  alias SSAuction.Bids.BidLog
  alias SSAuction.Bids.Bid
  alias SSAuction.Bids
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
                     dollars_per_team: dollars_per_team) do

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
        dollars_per_team: dollars_per_team,
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
    |> broadcast(:info_change)
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

  def start_auction(auction = %Auction{}) do
    {:ok, now} = DateTime.now("Etc/UTC")
    now = now
      |> DateTime.truncate(:second)
      |> DateTime.add(-now.second, :second)

    update_bids_to_new_start_time(auction, now)

    change_auction(auction, %{active: true, started_or_paused_at: now})
    |> Repo.update()
    |> broadcast(:auction_started_or_paused)
  end

  defp update_bids_to_new_start_time(%Auction{} = auction, new_start_time) do
    seconds_since_auction_paused = DateTime.diff(new_start_time, auction.started_or_paused_at)
    Enum.map(Repo.preload(auction, [:bids]).bids,
             fn (bid) -> add_seconds_to_expires_at(seconds_since_auction_paused, bid) end)
  end

  defp add_seconds_to_expires_at(seconds, %Bid{} = bid) do
    Bids.update_bid(bid, %{expires_at: DateTime.add(bid.expires_at, seconds, :second)})
  end

  def pause_auction(auction = %Auction{}) do
    {:ok, now} = DateTime.now("Etc/UTC")
    now = now
      |> DateTime.truncate(:second)
      |> DateTime.add(-now.second, :second)

    change_auction(auction, %{active: false, started_or_paused_at: now})
    |> Repo.update()
    |> broadcast(:auction_started_or_paused)
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
    if seconds != 0 and days == 0 and hours == 0 and minutes < 2 do
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

  @doc """
  Returns a list of teams in the auction

  """
  def list_teams(auction = %Auction{}) do
    Repo.preload(auction, [:teams]).teams
  end

  @doc """
  Returns true if the team is in the auction

  """
  def team_is_in_auction?(auction = %Auction{}, team = %Team{}) do
    team.auction_id == auction.id
  end

  @doc """
  Returns the number of dollars each team has in the auction

  """

  def dollars_per_team(auction = %Auction{}) do
    auction.dollars_per_team
  end

  def add_players_not_in_auction(auction = %Auction{}) do
    Players.players_not_in_auction(auction)
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
    broadcast({:ok, auction}, :queueable_auction_players_change)
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
                         |> Map.put(:rostered_at, Bids.rostered_bid_log(rp.player).datetime)
                         |> Map.put(:team_name, rp.team.name)
                         |> Map.put(:player_name, rp.player.name)
                         |> Map.put(:player_position, rp.player.position)
                         |> Map.put(:player_ssnum, rp.player.ssnum)
                end)
  end

  def get_rostered_players_with_rostered_at(%Auction{} = auction, %{sort_by: sort_by, sort_order: sort_order}) do
    sort_order = if sort_by == :rostered_at, do: {sort_order, DateTime}, else: sort_order
    get_rostered_players_with_rostered_at(auction)
    |> Enum.sort_by(fn rp -> Map.get(rp, sort_by) end, sort_order)
  end

  def get_rostered_players_with_rostered_at_and_surplus(%Auction{} = auction, %Team{} = team, %{sort_by: sort_by, sort_order: sort_order}) do
    sort_order = if sort_by == :rostered_at, do: {sort_order, DateTime}, else: sort_order
    get_rostered_players_with_rostered_at(auction)
    |> add_surplus_to_rostered_players(team)
    |> Enum.sort_by(fn rp -> Map.get(rp, sort_by) end, sort_order)
  end

  def get_rostered_players_with_rostered_at_and_surplus(%Auction{} = auction, nil, sort_options) do
    get_rostered_players_with_rostered_at(auction, sort_options)
  end

  defp add_surplus_to_rostered_players(rostered_players, team) do
    Enum.map(rostered_players,
             fn rostered_player -> value_struct = Players.get_value(rostered_player.player, team)
                                   value = if value_struct == nil, do: 0, else: value_struct.value
                                   Map.put(rostered_player, :surplus, value - rostered_player.cost)
             end)
  end

  def number_of_rostered_players(%Auction{} = auction) do
    auction
      |> Ecto.assoc(:rostered_players)
      |> Repo.aggregate(:count, :id)
  end

  def get_teams(%Auction{} = auction) do
    {:ok, now} = DateTime.now("Etc/UTC")
    Repo.preload(auction, [:teams]).teams
    |> Enum.map(fn team -> seconds_until_new_nominations_open = DateTime.diff(team.new_nominations_open_at, now)
                           time_nominations_expire = Teams.time_nominations_expire(team)
                           seconds_until_nominations_expire =
                              if time_nominations_expire == nil do
                                0
                              else
                                DateTime.diff(time_nominations_expire, now)
                              end
                           total_dollars = Teams.total_dollars(team)
                           dollars_spent = Teams.dollars_spent(team)
                           dollars_bid = Teams.dollars_bid(team)
                           dollars_available = total_dollars - dollars_spent
                           team
                           |> Map.put(:seconds_until_new_nominations_open, seconds_until_new_nominations_open)
                           |> Map.put(:seconds_until_nominations_expire, seconds_until_nominations_expire)
                           |> Map.put(:total_dollars, total_dollars)
                           |> Map.put(:dollars_spent, dollars_spent)
                           |> Map.put(:dollars_available, dollars_available)
                           |> Map.put(:dollars_bid, dollars_bid)
                           |> Map.put(:dollars_remaining, dollars_available - dollars_bid)
                           |> Map.put(:time_nominations_expire, time_nominations_expire)
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

  def user_in_auction?(%Auction{} = auction, %User{} = user) do
    Enum.member?(get_auction_user_ids(auction), user.id)
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

  @doc """
  Searches for expired bids in active auctions and roster them

  """
  def check_for_expired_bids() do
    q = from a in Auction, where: a.active, select: a.id
    Repo.all(q)
    |> Enum.each(&check_for_expired_bids/1)
  end

  @doc """
  Searches for expired bids in the auction and roster them

  """
  def check_for_expired_bids(auction_id) do
    broadcast({:ok, get_auction!(auction_id)}, :bid_expiration_update)
    auction_bids = from a in Auction,
                     where: a.id == ^auction_id,
                     join: bids in assoc(a, :bids),
                     select: bids
    open_bids = from b in subquery(auction_bids),
                  where: not b.closed
    Repo.all(open_bids)
    |> Enum.each(&check_for_expired_bid/1)
  end

  @doc """
  If this bid is expired, close it and roster the player

  """
  def check_for_expired_bid(bid = %Bid{}) do
    {:ok, now} = DateTime.now("Etc/UTC")
    if DateTime.diff(now, bid.expires_at) >= 0 do
      Bids.update_bid(bid, %{closed: true})
      Bids.roster_player_and_delete_bid(bid)
    end
  end

  @doc """
  Searches for teams ready to be given new nominations in active auctions

  """

  def check_for_new_nominations() do
    q = from a in Auction, where: a.active
    Repo.all(q)
    |> Enum.each(&check_for_new_nominations/1)
  end

  @doc """
  Searches for teams ready to be given new nominations in the auction

  """

  def check_for_new_nominations(auction = %Auction{}) do
    if auction.new_nominations_created == "time" do
      for team <- list_teams(auction) do
        check_for_new_nominations(team, auction)
      end
    end
  end

  @doc """
  Searches if the team is ready to be given new nominations

  """

  def check_for_new_nominations(team = %Team{}, auction = %Auction{}) do
    {:ok, now} = DateTime.now("Etc/UTC")
    if DateTime.diff(now, team.new_nominations_open_at) >= 0 do
      num_nominations = auction.nominations_per_team - team.unused_nominations
      Teams.give_team_new_nominations(team, auction, num_nominations)
    end
  end

  @doc """
  Searches for teams with expired nominations in active auctions and auto-nominate for them

  """

  def check_for_expired_nominations() do
    q = from a in Auction, where: a.active
    Repo.all(q)
    |> Enum.each(&check_for_expired_nominations/1)
  end

  @doc """
  Searches for teams with expired nominations in the auction and auto-nominate for them

  """

  def check_for_expired_nominations(auction = %Auction{}) do
    for team <- list_teams(auction) do
      check_for_expired_nominations(team, auction)
    end
  end

  @doc """
  Auto-nominate if the team has expired nomination

  """

  def check_for_expired_nominations(team = %Team{}, auction = %Auction{}) do
    {:ok, now} = DateTime.now("Etc/UTC")
    if team.time_nominations_expire != nil and DateTime.diff(now, team.time_nominations_expire) >= 0 do
      auto_nominate(team, auction)
    end
  end

  defp auto_nominate(team = %Team{}, auction = %Auction{}) do
    if team.unused_nominations > 0 do
      for _ <- 1..team.unused_nominations do
        if Teams.has_open_roster_spot?(team, auction) and Teams.dollars_remaining_for_bids_including_hidden(team) > 0 do
          cond do
            Teams.num_players_in_nomination_queue(team.id) > 0 ->
              player = Teams.next_in_nomination_queue(team)
              args = %{bid_amount: 1}
              Bids.submit_bid_changeset(auction, team, player, args)
              remove_from_nomination_queues(auction, player)
            num_players_in_nomination_queue(auction) > 0 ->
              player = next_in_nomination_queue(auction)
              args = %{bid_amount: 1}
              Bids.submit_bid_changeset(auction, team, player, args)
              remove_from_nomination_queues(auction, player)
            true ->
              nil
          end
        end
      end
      team
        |> Team.changeset(%{time_nominations_expire: nil,
                            unused_nominations: 0})
        |> Repo.update
      Teams.broadcast({:ok, team}, :info_change)
      broadcast({:ok, auction}, :teams_info_change)
    end
  end

  defp num_players_in_nomination_queue(auction = %Auction{}) do
    query = from a in Auction,
              where: a.id == ^auction.id,
              join: ordered_players in assoc(a, :ordered_players),
              select: ordered_players.id
    Repo.aggregate(query, :count, :id)
  end

  def remove_from_nomination_queues(auction = %Auction{}, player = %Player{}) do
    remove_from_nomination_queue(auction, player)
    broadcast({:ok, auction}, :nomination_queue_change)
    for team <- list_teams(auction) do
      Teams.remove_from_nomination_queue(team, player)
    end
  end

  @doc """
  Returns a the player at the top (lowest rank) of the auction's auto-nomination queue

  """
  def next_in_nomination_queue(auction = %Auction{}) do
    rank_of_next = smallest_rank_in_nomination_queue(auction)
    ordered_player = Repo.one!(from op in OrderedPlayer,
                               where: op.auction_id == ^auction.id and op.rank == ^rank_of_next)
    Players.get_player!(ordered_player.player_id)
  end

 defp smallest_rank_in_nomination_queue(auction = %Auction{}) do
    query = from a in Auction,
              where: a.id == ^auction.id,
              join: ordered_players in assoc(a, :ordered_players),
              select: ordered_players.rank,
              order_by: ordered_players.rank
    ranks = Repo.all(query)
    case ranks do
      [] ->
        nil

      _ ->
        Enum.min(ranks)
    end
  end

  def remove_from_nomination_queue(auction = %Auction{}, player = %Player{}) do
    ordered_player = find_ordered_player(player, auction)
    if ordered_player != nil do
      ordered_player
        |> Ecto.Changeset.change
        |> Repo.delete
    end
  end

  def remove_all_players_in_nomination_queue(auction = %Auction{}) do
    Repo.all(from op in OrderedPlayer, where: op.auction_id == ^auction.id)
    |> Ecto.Changeset.change
    |> Repo.delete
  end

  defp find_ordered_player(player = %Player{}, auction = %Auction{}) do
    Repo.one(from op in OrderedPlayer,
             where: op.auction_id == ^auction.id and op.player_id == ^player.id)
  end
end
