defmodule SSAuction.Teams do
  @moduledoc """
  The Teams context.
  """

  import Ecto.Query, warn: false

  alias SSAuction.Repo
  alias SSAuction.Teams.Team
  alias SSAuction.Players
  alias SSAuction.Players.Player
  alias SSAuction.Players.OrderedPlayer
  alias SSAuction.Players.CutPlayer
  alias SSAuction.Auctions
  alias SSAuction.Auctions.Auction
  alias SSAuction.Accounts.User
  alias SSAuction.Bids

  def subscribe do
    Phoenix.PubSub.subscribe(SSAuction.PubSub, "teams")
  end

  @doc """
  Returns the list of teams.

  ## Examples

      iex> list_teams()
      [%Team{}, ...]

  """
  def list_teams do
    Repo.all(Team)
  end

  @doc """
  Returns the list of teams that don't belong to an auction

  ## Examples

      iex> list_teams_not_in_an_auction()
      [%Team{}, ...]

  """
  def list_teams_not_in_an_auction do
    Repo.all(from t in Team, where: is_nil(t.auction_id))
  end

  @doc """
  Gets a single team.

  Raises `Ecto.NoResultsError` if the Team does not exist.

  ## Examples

      iex> get_team!(123)
      %Team{}

      iex> get_team!(456)
      ** (Ecto.NoResultsError)

  """
  def get_team!(id) do
    Repo.get!(Team, id)
    |> Map.put(:num_players_in_nomination_queue, num_players_in_nomination_queue(id))
  end

  @doc """
  Returns the team in the indicated auction with the indicated user.

  """
  def get_team_by_user_and_auction(user = %User{}, auction = %Auction{}) do
    [team] =
      Enum.filter(
        Repo.preload(user, [:teams]).teams,
        fn team -> team.auction_id == auction.id end
      )

    team
  end

  @doc """
  Creates a team.

  ## Examples

      iex> create_team(%{field: value})
      {:ok, %Team{}}

      iex> create_team(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_team(attrs \\ %{}) do
    %Team{}
    |> Team.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a team.

  ## Examples

      iex> update_team(team, %{field: new_value})
      {:ok, %Team{}}

      iex> update_team(team, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_team(%Team{} = team, attrs) do
    team
    |> Team.changeset(attrs)
    |> Repo.update()
    |> broadcast(:info_change)
  end

  @doc """
  Deletes a team.

  ## Examples

      iex> delete_team(team)
      {:ok, %Team{}}

      iex> delete_team(team)
      {:error, %Ecto.Changeset{}}

  """
  def delete_team(%Team{} = team) do
    Repo.delete(team)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking team changes.

  ## Examples

      iex> change_team(team)
      %Ecto.Changeset{data: %Team{}}

  """
  def change_team(%Team{} = team, attrs \\ %{}) do
    Team.changeset(team, attrs)
  end

  def total_dollars(%Team{} = team) do
    auction = Auctions.get_auction!(team.auction_id)

    Auctions.dollars_per_team(auction) + team.total_supplemental_dollars
  end

  def get_users(%Team{} = team) do
    Enum.sort_by(Repo.preload(team, [:users]).users, fn user -> user.username end)
  end

  def user_in_team?(%Team{} = team, %User{} = user) do
    Enum.member?(Enum.map(Repo.preload(team, [:users]).users, fn u -> u.id end), user.id)
  end

  def add_user(%Team{} = team, %User{} = user) do
    team = Repo.preload(team, [:users])

    changeset =
      Ecto.Changeset.change(team)
      |> Ecto.Changeset.put_assoc(:users, [user | team.users])

    team = Repo.update!(changeset)
    broadcast({:ok, team}, :user_added)
  end

  def broadcast({:ok, team}, event) do
    Phoenix.PubSub.broadcast(
      SSAuction.PubSub,
      "teams",
      {event, team}
    )

    {:ok, team}
  end

  def time_nominations_expire(%Team{} = team) do
    if team.unused_nominations > 0 do
      team.time_nominations_expire
    else
      nil
    end
  end

  @doc """
  Returns all open bids for a team

  """
  def open_bids(team = %Team{}) do
    team_bids =
      from t in Team,
        where: t.id == ^team.id,
        join: bids in assoc(t, :bids),
        select: bids

    Repo.all(from b in subquery(team_bids), where: not b.closed)
  end

  def num_players_in_nomination_queue(team_id) do
    Repo.one(from op in OrderedPlayer, where: op.team_id == ^team_id, select: count())
  end

  def players_in_nomination_queue(%Team{} = team) do
    Repo.all(
      from op in OrderedPlayer,
        where: op.team_id == ^team.id,
        order_by: op.rank,
        preload: [:player]
    )
  end

  def players_in_nomination_queue_with_values(%Team{} = team) do
    players_in_nomination_queue(team)
    |> add_value_to_ordered_players(team)
  end

  defp add_value_to_ordered_players(ordered_players, team) do
    Enum.map(
      ordered_players,
      fn ordered_player ->
        value_struct = Players.get_value(ordered_player.player, team)
        value = if value_struct == nil, do: 0, else: value_struct.value
        Map.put(ordered_player, :value, value)
      end
    )
  end

  def add_to_nomination_queue(player = %Player{}, team = %Team{}) do
    ordered_player =
      %OrderedPlayer{
        rank: largest_rank_in_nomination_queue(team) + 1,
        player: player
      }

    ordered_player = Ecto.build_assoc(team, :ordered_players, ordered_player)
    map = Repo.insert!(ordered_player)
    broadcast({:ok, team}, :nomination_queue_change)
    broadcast({:ok, team}, :queueable_players_change)
    map
  end

  def remove_from_nomination_queue(ordered_player = %OrderedPlayer{}, team = %Team{}) do
    Players.delete_ordered_player(ordered_player)
    broadcast({:ok, team}, :nomination_queue_change)
    broadcast({:ok, team}, :queueable_players_change)
  end

  def remove_from_nomination_queue(team = %Team{}, player = %Player{}) do
    ordered_player = find_ordered_player(player, team)

    if ordered_player != nil do
      remove_from_nomination_queue(ordered_player, team)
    end
  end

  def move_to_top_of_nomination_queue(ordered_player = %OrderedPlayer{}, team = %Team{}) do
    query =
      from op in OrderedPlayer,
        where: op.team_id == ^team.id,
        where: op.rank < ^ordered_player.rank,
        order_by: [desc: op.rank]

    Enum.map(
      Repo.all(query),
      fn op -> Players.update_ordered_player(op, %{rank: op.rank + 1}) end
    )

    Players.update_ordered_player(ordered_player, %{
      rank: smallest_rank_in_nomination_queue(team) - 1
    })

    broadcast({:ok, team}, :nomination_queue_change)
  end

  def move_to_bottom_of_nomination_queue(ordered_player = %OrderedPlayer{}, team = %Team{}) do
    Players.update_ordered_player(ordered_player, %{
      rank: largest_rank_in_nomination_queue(team) + 1
    })

    broadcast({:ok, team}, :nomination_queue_change)
  end

  def move_up_in_nomination_queue(ordered_player = %OrderedPlayer{}, team = %Team{}) do
    previous = previous_in_nomination_queue(ordered_player, team)

    if previous do
      swap_ranks(ordered_player, previous)
      broadcast({:ok, team}, :nomination_queue_change)
    end
  end

  def move_down_in_nomination_queue(ordered_player = %OrderedPlayer{}, team = %Team{}) do
    next = next_in_nomination_queue(ordered_player, team)

    if next do
      swap_ranks(ordered_player, next)
      broadcast({:ok, team}, :nomination_queue_change)
    end
  end

  defp swap_ranks(op1 = %OrderedPlayer{}, op2 = %OrderedPlayer{}) do
    rank2 = op2.rank
    Players.update_ordered_player(op2, %{rank: op1.rank})
    Players.update_ordered_player(op1, %{rank: rank2})
  end

  defp largest_rank_in_nomination_queue(team = %Team{}) do
    query =
      from op in OrderedPlayer,
        where: op.team_id == ^team.id,
        order_by: [desc: op.rank],
        select: op.rank

    ranks = Repo.all(query)

    case ranks do
      [] ->
        0

      _ ->
        Enum.at(ranks, 0)
    end
  end

  defp smallest_rank_in_nomination_queue(team = %Team{}) do
    query =
      from op in OrderedPlayer,
        where: op.team_id == ^team.id,
        order_by: [asc: op.rank],
        select: op.rank

    ranks = Repo.all(query)

    case ranks do
      [] ->
        1

      _ ->
        Enum.at(ranks, 0)
    end
  end

  defp previous_in_nomination_queue(ordered_player = %OrderedPlayer{}, team = %Team{}) do
    query =
      from op in OrderedPlayer,
        where: op.team_id == ^team.id,
        where: op.rank < ^ordered_player.rank,
        order_by: [desc: op.rank]

    ordered_players = Repo.all(query)

    case ordered_players do
      [] ->
        nil

      _ ->
        Enum.at(ordered_players, 0)
    end
  end

  defp next_in_nomination_queue(ordered_player = %OrderedPlayer{}, team = %Team{}) do
    query =
      from op in OrderedPlayer,
        where: op.team_id == ^team.id,
        where: op.rank > ^ordered_player.rank,
        order_by: [asc: op.rank]

    ordered_players = Repo.all(query)

    case ordered_players do
      [] ->
        nil

      _ ->
        Enum.at(ordered_players, 0)
    end
  end

  def number_of_rostered_players(%Team{} = team) do
    team
    |> Ecto.assoc(:rostered_players)
    |> Repo.aggregate(:count, :id)
  end

  def get_rostered_players(%Team{} = team) do
    team
    |> Ecto.assoc(:rostered_players)
    |> Repo.all()
    |> Repo.preload([:player])
  end

  @doc """
  Returns a query for players who can be added to the team's nomination queue

  """
  def queueable_players_query(team = %Team{}) do
    auction = Auctions.get_auction!(team.auction_id)

    bid_players = Auctions.players_in_bids_query(auction)
    rostered_players = Auctions.players_rostered_in_query(auction)
    queued_players = players_in_nomination_queue_query(team)

    from player in Player,
      where: player.auction_id == ^auction.id,
      select: player,
      except_all: ^bid_players,
      except_all: ^rostered_players,
      except_all: ^queued_players
  end

  @doc """
  Returns a list of players (sorted by id) who can be added to the team's nomination queue

  """
  def queueable_players(team = %Team{}) do
    query = queueable_players_query(team)

    Repo.all(from p in subquery(query), order_by: p.id)
  end

  defp filter_players_with_positions(players, positions) do
    Enum.filter(
      players,
      fn player ->
        Enum.any?(
          String.split(player.position, "/", trim: true),
          fn position -> position in positions end
        )
      end
    )
  end

  defp filter_players_by_search_string(players, search_string) do
    Enum.filter(
      players,
      fn player ->
        String.contains?(String.downcase(player.name), String.downcase(search_string))
      end
    )
  end

  @doc """
  Returns a list of players (sorted by id) who can be added to the team's nomination queue,
  sorted and filtered as specified

  """
  def queueable_players(
        team = %Team{},
        %{sort_by: sort_by, sort_order: sort_order, positions: positions, search: search}
      ) do
    query = queueable_players_query(team)

    players = Repo.all(from p in subquery(query), order_by: [{^sort_order, ^sort_by}])

    players =
      if Kernel.length(positions) == 0 or positions == [""] do
        players
      else
        filter_players_with_positions(players, positions)
      end

    if search == "" do
      players
    else
      filter_players_by_search_string(players, search)
    end
  end

  @doc """
  Returns true if the player can be added to the team's nomination queue

  """
  def queueable_player?(player = %Player{}, team = %Team{}) do
    query = queueable_players_query(team)

    Enum.any?(
      Repo.all(from p in subquery(query), order_by: p.id, select: p.id),
      fn id -> id == player.id end
    )
  end

  @doc """
  Returns a the player at the top (lowest rank) of the teams's auto-nomination queue

  """
  def next_in_nomination_queue(team = %Team{}) do
    rank_of_next = smallest_rank_in_nomination_queue(team)

    ordered_player =
      Repo.one!(
        from op in OrderedPlayer,
          where: op.team_id == ^team.id and op.rank == ^rank_of_next
      )

    Players.get_player!(ordered_player.player_id)
  end

  defp find_ordered_player(player = %Player{}, team = %Team{}) do
    Repo.one(
      from op in OrderedPlayer,
        where: op.team_id == ^team.id and op.player_id == ^player.id
    )
  end

  def update_unused_nominations(team = %Team{}, auction = %Auction{}) do
    if auction.new_nominations_created == "auction" do
      give_team_new_nominations(team, auction, 1)
    end
  end

  def give_team_new_nominations(team = %Team{}, auction = %Auction{}, num_nominations) do
    open_roster_spots = open_roster_spots(team, auction)

    new_unused_nominations =
      Enum.min([team.unused_nominations + num_nominations, open_roster_spots])

    if new_unused_nominations > 0 do
      time_nominations_expire =
        if auction.seconds_before_autonomination == 0 do
          nil
        else
          {:ok, now} = DateTime.now("Etc/UTC")

          now
          |> DateTime.truncate(:second)
          |> DateTime.add(-now.second, :second)
          |> DateTime.add(auction.seconds_before_autonomination, :second)
        end

      team
      |> Team.changeset(%{
        unused_nominations: new_unused_nominations,
        time_nominations_expire: time_nominations_expire
      })
      |> Repo.update()
    end

    set_new_nominations_open_at(
      team,
      DateTime.add(team.new_nominations_open_at, 24 * 60 * 60, :second)
    )
  end

  def set_new_nominations_open_at(team = %Team{}, new_nominations_open_at) do
    team
    |> Team.changeset(%{new_nominations_open_at: new_nominations_open_at})
    |> Repo.update()

    broadcast({:ok, team}, :info_change)
    auction = Auctions.get_auction!(team.auction_id)
    Auctions.broadcast({:ok, auction}, :teams_info_change)
  end

  def change_nominations_open_at_date(team = %Team{}, new_nominations_open_at_date) do
    {_, time} = String.split_at(DateTime.to_iso8601(team.new_nominations_open_at), 11)

    {:ok, new_nominations_open_at, 0} =
      DateTime.from_iso8601(Date.to_iso8601(new_nominations_open_at_date) <> "T" <> time)

    set_new_nominations_open_at(team, new_nominations_open_at)
  end

  @doc """
  Returns a query of all players in the team's nomination queue

  """
  def players_in_nomination_queue_query(team = %Team{}) do
    from t in Team,
      where: t.id == ^team.id,
      join: ordered_players in assoc(t, :ordered_players),
      join: player in assoc(ordered_players, :player),
      select: player
  end

  @doc """
  Update a team's info after a nomination

  """
  def update_info_post_nomination(team_id) do
    team = get_team!(team_id)
    set_unused_nominations(team, team.unused_nominations - 1)
  end

  def set_unused_nominations(team = %Team{}, num_unused_nominations) do
    team
    |> Team.changeset(%{unused_nominations: num_unused_nominations})
    |> Repo.update()

    broadcast({:ok, team}, :info_change)
    auction = Auctions.get_auction!(team.auction_id)
    Auctions.broadcast({:ok, auction}, :teams_info_change)
  end

  @doc """
  Returns the number of open roster spots for a team

  """
  def open_roster_spots(team = %Team{}, auction = %Auction{}) do
    auction.players_per_team - number_of_rostered_players_in_team(team) -
      number_of_bids_for_team(team)
  end

  @doc """
  Returns true if the team has an open roster spot for a bid

  """
  def has_open_roster_spot?(team = %Team{}, auction = %Auction{}) do
    open_roster_spots(team, auction) > 0
  end

  @doc """
  Returns the number of rostered players in a team

  """
  def number_of_rostered_players_in_team(team = %Team{}) do
    team
    |> Ecto.assoc(:rostered_players)
    |> Repo.aggregate(:count, :id)
  end

  @doc """
  Returns the number of dollars the team has spent

  """

  def dollars_spent(team = %Team{}) do
    rostered_players =
      team
      |> Ecto.assoc(:rostered_players)
      |> Repo.all()

    rostered_dollars = Enum.sum(for p <- rostered_players, do: p.cost)

    rostered_dollars + dollars_on_cut_players(team)
  end

  @doc """
  Returns the number of dollars the team has spent on cut players

  """

  def dollars_on_cut_players(team = %Team{}) do
    cut_players =
      team
      |> Ecto.assoc(:cut_players)
      |> Repo.all()

    Enum.sum(for p <- cut_players, do: cut_player_dollar_cost(p))
  end

  @doc """
  Returns the number of dollars a cut player costs (or might cost) a team

  """

  def cut_player_dollar_cost(cut_player = %CutPlayer{}) do
    cut_player_dollar_cost(cut_player.cost)
  end

  def cut_player_dollar_cost(cost) do
    div(cost + 1, 2)
  end

  def get_cut_players_with_cut_at_and_cost(%Team{} = team) do
    get_cut_players(team)
    |> Enum.map(fn cp ->
      cp
      |> Map.put(:cut_at, Bids.cut_bid_log(cp.player).datetime)
      |> Map.put(:cost, cut_player_dollar_cost(cp))
      |> Map.put(:team_name, cp.team.name)
      |> Map.put(:player_name, cp.player.name)
      |> Map.put(:player_position, cp.player.position)
      |> Map.put(:player_ssnum, cp.player.ssnum)
    end)
  end

  def get_cut_players_with_cut_at_and_cost(%Team{} = team, %{
        sort_by: sort_by,
        sort_order: sort_order
      }) do
    sort_order = if sort_by == :cut_at, do: {sort_order, DateTime}, else: sort_order

    get_cut_players_with_cut_at_and_cost(team)
    |> Enum.sort_by(fn rp -> Map.get(rp, sort_by) end, sort_order)
  end

  def get_cut_players(%Team{} = team) do
    team
    |> Ecto.assoc(:cut_players)
    |> Repo.all()
    |> Repo.preload([:player, :team])
  end

  @doc """
  Returns the number of dollars the team has in open bids (not counting hidden high bids)

  """

  def dollars_bid(team = %Team{}) do
    Enum.sum(for b <- open_bids(team), do: b.bid_amount)
  end

  def dollars_bid_including_hidden(team = %Team{}) do
    Enum.sum(
      for b <- open_bids(team),
          do: calculate_max_bid_vs_hidden_high_bid(b.bid_amount, b.hidden_high_bid)
    )
  end

  defp calculate_max_bid_vs_hidden_high_bid(bid, nil) do
    bid
  end

  defp calculate_max_bid_vs_hidden_high_bid(bid, hidden_high_bid) do
    max(bid, hidden_high_bid)
  end

  @doc """
  Returns the number of bids a team has

  """
  def number_of_bids_for_team(team = %Team{}) do
    team
    |> Ecto.assoc(:bids)
    |> Repo.aggregate(:count, :id)
  end

  def get_rostered_players_with_rostered_at(%Team{} = team) do
    Enum.map(
      get_rostered_players(team),
      fn rp ->
        rp
        |> Map.put(:rostered_at, Bids.rostered_bid_log(rp.player).datetime)
        |> Map.put(:player_name, rp.player.name)
        |> Map.put(:player_position, rp.player.position)
        |> Map.put(:player_ssnum, rp.player.ssnum)
      end
    )
  end

  def get_rostered_players_with_rostered_at(%Team{} = team, %{
        sort_by: sort_by,
        sort_order: sort_order
      }) do
    sort_order = if sort_by == :rostered_at, do: {sort_order, DateTime}, else: sort_order

    get_rostered_players_with_rostered_at(team)
    |> Enum.sort_by(fn rp -> Map.get(rp, sort_by) end, sort_order)
  end

  def get_rostered_players_with_rostered_at_and_surplus(%Team{} = team, %Team{} = current_team, %{
        sort_by: sort_by,
        sort_order: sort_order
      }) do
    sort_order = if sort_by == :rostered_at, do: {sort_order, DateTime}, else: sort_order

    get_rostered_players_with_rostered_at(team)
    |> add_surplus_to_rostered_players(current_team)
    |> Enum.sort_by(fn rp -> Map.get(rp, sort_by) end, sort_order)
  end

  def get_rostered_players_with_rostered_at_and_surplus(%Team{} = team, nil, sort_options) do
    get_rostered_players_with_rostered_at(team, sort_options)
  end

  defp add_surplus_to_rostered_players(rostered_players, team) do
    Enum.map(
      rostered_players,
      fn rostered_player ->
        value_struct = Players.get_value(rostered_player.player, team)
        value = if value_struct == nil, do: 0, else: value_struct.value
        Map.put(rostered_player, :surplus, value - rostered_player.cost)
      end
    )
  end

  @doc """
  Returns the number of dollars the team has left to bid (not including hidden)

  """

  def dollars_remaining_for_bids(team = %Team{}) do
    auction = Auctions.get_auction!(team.auction_id)
    team_dollars_remaining_for_bids(team, auction)
  end

  def team_dollars_remaining_for_bids(team = %Team{}, auction = %Auction{}) do
    dollars_left = total_dollars(team) - (dollars_spent(team) + dollars_bid(team))

    if auction.must_roster_all_players do
      dollars_left -
        (auction.players_per_team - number_of_rostered_players(team) - number_of_bids(team))
    else
      dollars_left
    end
  end

  @doc """
  Returns the number of dollars the team has left to bid (including hidden)

  """

  def dollars_remaining_for_bids_including_hidden(team = %Team{}) do
    auction = Auctions.get_auction!(team.auction_id)
    dollars_remaining_for_bids_including_hidden(team, auction)
  end

  def dollars_remaining_for_bids_including_hidden(team = %Team{}, auction = %Auction{}) do
    dollars_left =
      total_dollars(team) - (dollars_spent(team) + dollars_bid_including_hidden(team))

    if auction.must_roster_all_players do
      dollars_left -
        (auction.players_per_team - number_of_rostered_players(team) - number_of_bids(team))
    else
      dollars_left
    end
  end

  @doc """
  Returns the number of bids a team has

  """
  def number_of_bids(team = %Team{}) do
    team
    |> Ecto.assoc(:bids)
    |> Repo.aggregate(:count, :id)
  end

  @doc """
  Returns true if the team has enough money left for the bid amount, the "keep bidding up to" amount, and the hidden high bid

  """

  def legal_bid_amount?(team = %Team{}, bid_amount, hidden_high_bid) do
    legal_bid_amount?(team, bid_amount, hidden_high_bid, 0, 0)
  end

  def legal_bid_amount?(team = %Team{}, bid_amount, hidden_high_bid, nil, nil) do
    legal_bid_amount?(team, bid_amount, hidden_high_bid, 0, 0)
  end

  def legal_bid_amount?(team = %Team{}, bid_amount, hidden_high_bid, existing_bid_amount, nil) do
    legal_bid_amount?(team, bid_amount, hidden_high_bid, existing_bid_amount, 0)
  end

  def legal_bid_amount?(
        team = %Team{},
        bid_amount,
        hidden_high_bid,
        existing_bid_amount,
        existing_hidden_high_bid
      ) do
    max_old_dollars = calculate_max_bid(existing_bid_amount, existing_hidden_high_bid)
    max_new_dollars = calculate_max_bid(bid_amount, hidden_high_bid)
    dollars_remaining_for_bids_including_hidden(team) + max_old_dollars - max_new_dollars >= 0
  end

  defp calculate_max_bid(bid_amount, nil) do
    bid_amount
  end

  defp calculate_max_bid(nil, hidden_high_bid) do
    hidden_high_bid
  end

  defp calculate_max_bid(bid_amount, hidden_high_bid) do
    max(bid_amount, hidden_high_bid)
  end
end
