defmodule SSAuction.Teams do
  @moduledoc """
  The Teams context.
  """

  import Ecto.Query, warn: false

  alias SSAuction.Repo
  alias SSAuction.Teams.Team
  alias SSAuction.Players.Player
  alias SSAuction.Auctions
  alias SSAuction.Auctions.Auction
  alias SSAuction.Accounts.User

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
  def get_team!(id), do: Repo.get!(Team, id)

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
    |> broadcast(:team_updated)
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

  def get_users(%Team{} = team) do
    Enum.sort_by(Repo.preload(team, [:users]).users, fn user -> user.username end)
  end

  def user_in_team(%Team{} = team, %User{} = user) do
    Enum.member?(Enum.map(Repo.preload(team, [:users]).users, fn u -> u.id end), user.id)
  end

  def add_user(%Team{} = team, %User{} = user) do
    team = Repo.preload(team, [:users])
    changeset = Ecto.Changeset.change(team)
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

  def dollars_spent(%Team{} = team) do
    rostered_players =
      team
      |> Ecto.assoc(:rostered_players)
      |> Repo.all
    Enum.sum(for p <- rostered_players, do: p.cost)
  end

  def dollars_bid(%Team{} = _team) do
    0
  end

  def number_of_bids(%Team{} = _team) do
    0
  end

  def dollars_remaining_for_bids(%Team{} = team) do
    auction = Auctions.get_auction!(team.auction_id)
    dollars_remaining_for_bids(auction, team)
  end

  def dollars_remaining_for_bids(%Auction{} = auction, %Team{} = team) do
    dollars_left = Auctions.dollars_per_team(auction) \
                    - (dollars_spent(team) + dollars_bid(team))
    if auction.must_roster_all_players do
      dollars_left - (auction.players_per_team \
                      - number_of_rostered_players(team) \
                      - number_of_bids(team))
    else
      dollars_left
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
      |> Repo.all
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

  defp filter_players_with_positions(players_all_positions, positions) do
    Enum.filter(players_all_positions,
                fn player ->
                  Enum.any?(String.split(player.position, "/", trim: true),
                            fn position -> position in positions end)
                end)
  end

  @doc """
  Returns a list of players (sorted by id) who can be added to the team's nomination queue,
  sorted and filtered as specified

  """
  def queueable_players(team = %Team{}, %{sort_by: sort_by, sort_order: sort_order, positions: positions}) do
    query = queueable_players_query(team)

    players_all_positions = Repo.all(from p in subquery(query), order_by: [{^sort_order, ^sort_by}])

    if Kernel.length(positions) == 0 or positions == [""] do
      players_all_positions
    else
      filter_players_with_positions(players_all_positions, positions)
    end
  end

  @doc """
  Returns true if the player can be added to the team's nomination queue

  """
  def queueable_player?(player = %Player{}, team = %Team{}) do
    query = queueable_players_query(team)

    Enum.any?(Repo.all(from p in subquery(query), order_by: p.id,  select: p.id),
              fn id -> id == player.id end)
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

  alias SSAuction.Bids

  def get_rostered_players_with_rostered_at(%Team{} = team) do
    Enum.map(get_rostered_players(team),
             fn rp -> rp
                      |> Map.put(:rostered_at, Bids.rostered_bid_log(rp.player).updated_at)
                      |> Map.put(:player_name, rp.player.name)
                      |> Map.put(:player_position, rp.player.position)
                      |> Map.put(:player_ssnum, rp.player.ssnum)
             end)
  end

  def get_rostered_players_with_rostered_at(%Team{} = team, %{sort_by: sort_by, sort_order: sort_order}) do
    get_rostered_players_with_rostered_at(team)
    |> Enum.sort_by(fn rp -> Map.get(rp, sort_by) end, sort_order)
  end
end
