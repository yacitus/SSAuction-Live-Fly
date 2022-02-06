defmodule SSAuction.Teams do
  @moduledoc """
  The Teams context.
  """

  import Ecto.Query, warn: false
  alias SSAuction.Repo

  alias SSAuction.Teams.Team
  alias SSAuction.Auctions
  alias SSAuction.Auctions.Auction

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
