defmodule SSAuction.Players do
  @moduledoc """
  The Players context.
  """

  import Ecto.Query, warn: false
  alias SSAuction.Repo
  alias SSAuction.Auctions
  alias SSAuction.Auctions.Auction
  alias SSAuction.Bids
  alias SSAuction.Bids.BidLog
  alias SSAuction.Players
  alias SSAuction.Players.AllPlayer
  alias SSAuction.Players.CutPlayer
  alias SSAuction.Players.OrderedPlayer
  alias SSAuction.Players.Player
  alias SSAuction.Players.RosteredPlayer
  alias SSAuction.Players.Value
  alias SSAuction.Teams
  alias SSAuction.Teams.Team

  def subscribe do
    Phoenix.PubSub.subscribe(SSAuction.PubSub, "players")
  end

  def broadcast({:ok, player}, event) do
    Phoenix.PubSub.broadcast(
      SSAuction.PubSub,
      "players",
      {event, player}
    )
    {:ok, player}
  end

  @doc """
  Returns the list of all_players.

  ## Examples

      iex> list_all_players()
      [%AllPlayer{}, ...]

  """
  def list_all_players do
    Repo.all(AllPlayer)
  end

  @doc """
  Returns the number records in all_players.

  ## Examples

      iex> count_all_players()
      320

  """
  def count_all_players do
    Repo.one(from p in AllPlayer, select: count(p.id))
  end

 @doc """
  Returns the list of all_players with indicated year and league.

  ## Examples

      iex> list_all_players("2022-AL")
      [%AllPlayer{}, ...]

  """
  def list_all_players(year_and_league) do
    list_all_players(year_and_league, :asc)
  end

  def list_all_players(year_and_league, sort_order) do
    order_by
      = if sort_order == :asc do
          [asc: :ssnum]
        else
          [desc: :ssnum]
        end
    Repo.all(from p in AllPlayer,
              where: p.year_range == ^year_and_league,
              order_by: ^order_by,
              select: p)
  end

  @doc """
  Returns the number records in all_players with indicated year and league.

  ## Examples

      iex> count_all_players()
      320

  """
  def count_all_players(year_and_league) do
    Repo.one(from p in AllPlayer,
              where: p.year_range == ^year_and_league,
              select: count(p.id))
  end

  @doc """
  Gets a single all_player.

  Raises `Ecto.NoResultsError` if the All player does not exist.

  ## Examples

      iex> get_all_player!(123)
      %AllPlayer{}

      iex> get_all_player!(456)
      ** (Ecto.NoResultsError)

  """
  def get_all_player!(id), do: Repo.get!(AllPlayer, id)

  @doc """
  Creates a all_player.

  ## Examples

      iex> create_all_player(%{field: value})
      {:ok, %AllPlayer{}}

      iex> create_all_player(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_all_player!(attrs \\ %{}) do
    %AllPlayer{}
    |> AllPlayer.changeset(attrs)
    |> Repo.insert!()
  end

  @doc """
  Updates a all_player.

  ## Examples

      iex> update_all_player(all_player, %{field: new_value})
      {:ok, %AllPlayer{}}

      iex> update_all_player(all_player, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_all_player(%AllPlayer{} = all_player, attrs) do
    all_player
    |> AllPlayer.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a all_player.

  ## Examples

      iex> delete_all_player(all_player)
      {:ok, %AllPlayer{}}

      iex> delete_all_player(all_player)
      {:error, %Ecto.Changeset{}}

  """
  def delete_all_player(%AllPlayer{} = all_player) do
    Repo.delete(all_player)
  end

  @doc """
  Deletes all all_player records with indicated year and league.

  ## Examples

      iex> delete_all_players("2022-AL")
      {:ok, %AllPlayer{}}

      iex> delete_all_players("2022-AL")
      {:error, %Ecto.Changeset{}}

  """
  def delete_all_players(year_and_league) do
    Repo.delete_all(from p in AllPlayer,
                      where: p.year_range == ^year_and_league,
                      select: p)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking all_player changes.

  ## Examples

      iex> change_all_player(all_player)
      %Ecto.Changeset{data: %AllPlayer{}}

  """
  def change_all_player(%AllPlayer{} = all_player, attrs \\ %{}) do
    AllPlayer.changeset(all_player, attrs)
  end

  @doc """
  Returns the list of players.

  ## Examples

      iex> list_players()
      [%Player{}, ...]

  """
  def list_players do
    Repo.all(Player)
  end

  @doc """
  Gets a single player.

  Raises `Ecto.NoResultsError` if the Player does not exist.

  ## Examples

      iex> get_player!(123)
      %Player{}

      iex> get_player!(456)
      ** (Ecto.NoResultsError)

  """
  def get_player!(id), do: Repo.get!(Player, id)

  @doc """
  Creates a player.

  ## Examples

      iex> create_player(%{field: value})
      {:ok, %Player{}}

      iex> create_player(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_player(attrs \\ %{}) do
    %Player{}
    |> Player.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a player.

  ## Examples

      iex> update_player(player, %{field: new_value})
      {:ok, %Player{}}

      iex> update_player(player, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_player(%Player{} = player, attrs) do
    player
    |> Player.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a player.

  ## Examples

      iex> delete_player(player)
      {:ok, %Player{}}

      iex> delete_player(player)
      {:error, %Ecto.Changeset{}}

  """
  def delete_player(%Player{} = player) do
    if in_bids?(player) do
      Bids.delete_bid(Bids.get_bid!(player.bid_id))
    end
    if is_rostered?(player) do
      delete_rostered_player(get_rostered_player!(player.rostered_player_id))
    end
    if is_cut?(player) do
      delete_cut_player(get_cut_player!(player.cut_player_id))
    end
    Repo.delete_all(from bl in BidLog, where: bl.player_id == ^player.id)
    Repo.delete_all(from op in OrderedPlayer, where: op.player_id == ^player.id)
    Repo.delete_all(from v in Value, where: v.player_id == ^player.id)
    Repo.delete(player)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking player changes.

  ## Examples

      iex> change_player(player)
      %Ecto.Changeset{data: %Player{}}

  """
  def change_player(%Player{} = player, attrs \\ %{}) do
    Player.changeset(player, attrs)
  end

  @doc """
  Returns true if the player is rostered

  """
  def is_rostered?(player = %Player{}) do
    player.rostered_player_id != nil
  end

  @doc """
  Returns true if the player is cut

  """
  def is_cut?(player = %Player{}) do
    player.cut_player_id != nil
  end

  @doc """
  Returns true if the player is in the auction's bid

  """
  def in_bids?(player = %Player{}) do
    player.bid_id != nil
  end

  def num_players_in_auction(auction = %Auction{}) do
    Repo.aggregate(from(p in Player, where: p.auction_id == ^auction.id), :count, :id)
  end

  def players_not_in_auction(auction = %Auction{}) do
    player_ssnums_in_auction = Repo.all(from p in Player,
                                        where: p.auction_id == ^auction.id,
                                        order_by: [asc: :ssnum],
                                        select: p.ssnum)
    all_players = list_all_players(auction.year_range)
    Enum.filter(all_players, fn ap -> not Enum.member?(player_ssnums_in_auction, ap.ssnum) end)
  end

  def get_player_from_ssnum(auction = %Auction{}, ssnum) do
    Repo.one(from p in Player, where: p.auction_id == ^auction.id and p.ssnum == ^ssnum)
  end

  @doc """
  Returns the list of rostered_players.

  ## Examples

      iex> list_rostered_players()
      [%RosteredPlayer{}, ...]

  """
  def list_rostered_players do
    Repo.all(RosteredPlayer)
  end

  @doc """
  Gets a single rostered_player.

  Raises `Ecto.NoResultsError` if the Rostered player does not exist.

  ## Examples

      iex> get_rostered_player!(123)
      %RosteredPlayer{}

      iex> get_rostered_player!(456)
      ** (Ecto.NoResultsError)

  """
  def get_rostered_player!(id), do: Repo.get!(RosteredPlayer, id)

  @doc """
  Creates a rostered_player.

  ## Examples

      iex> create_rostered_player(%{field: value})
      {:ok, %RosteredPlayer{}}

      iex> create_rostered_player(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_rostered_player(attrs \\ %{}) do
    %RosteredPlayer{}
    |> RosteredPlayer.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a rostered_player.

  ## Examples

      iex> update_rostered_player(rostered_player, %{field: new_value})
      {:ok, %RosteredPlayer{}}

      iex> update_rostered_player(rostered_player, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_rostered_player(%RosteredPlayer{} = rostered_player, attrs) do
    rostered_player
    |> RosteredPlayer.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a rostered_player.

  ## Examples

      iex> delete_rostered_player(rostered_player)
      {:ok, %RosteredPlayer{}}

      iex> delete_rostered_player(rostered_player)
      {:error, %Ecto.Changeset{}}

  """
  def delete_rostered_player(%RosteredPlayer{} = rostered_player) do
    rostered_player = Repo.preload(rostered_player, [:player])
    rostered_player.player
    |> Ecto.Changeset.change(%{rostered_player_id: nil})
    |> Repo.update
    rostered_player
    |> Ecto.Changeset.change
    |> Repo.delete
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking rostered_player changes.

  ## Examples

      iex> change_rostered_player(rostered_player)
      %Ecto.Changeset{data: %RosteredPlayer{}}

  """
  def change_rostered_player(%RosteredPlayer{} = rostered_player, attrs \\ %{}) do
    RosteredPlayer.changeset(rostered_player, attrs)
  end

  @doc """
  Returns the list of cut_players.

  ## Examples

      iex> list_cut_players()
      [%CutPlayer{}, ...]

  """
  def list_cut_players do
    Repo.all(CutPlayer)
  end

  @doc """
  Gets a single cut_player.

  Raises `Ecto.NoResultsError` if the Rostered player does not exist.

  ## Examples

      iex> get_cut_player!(123)
      %CutPlayer{}

      iex> get_cut_player!(456)
      ** (Ecto.NoResultsError)

  """
  def get_cut_player!(id), do: Repo.get!(CutPlayer, id)

  @doc """
  Creates a cut_player.

  ## Examples

      iex> create_cut_player(%{field: value})
      {:ok, %CutPlayer{}}

      iex> create_cut_player(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_cut_player(attrs \\ %{}) do
    %CutPlayer{}
    |> CutPlayer.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a cut_player.

  ## Examples

      iex> update_cut_player(cut_player, %{field: new_value})
      {:ok, %CutPlayer{}}

      iex> update_cut_player(cut_player, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_cut_player(%CutPlayer{} = cut_player, attrs) do
    cut_player
    |> CutPlayer.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a cut_player.

  ## Examples

      iex> delete_cut_player(cut_player)
      {:ok, %CutPlayer{}}

      iex> delete_cut_player(cut_player)
      {:error, %Ecto.Changeset{}}

  """
  def delete_cut_player(%CutPlayer{} = cut_player) do
    cut_player = Repo.preload(cut_player, [:player])
    cut_player.player
    |> Ecto.Changeset.change(%{cut_player_id: nil})
    |> Repo.update
    cut_player
    |> Ecto.Changeset.change
    |> Repo.delete
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking cut_player changes.

  ## Examples

      iex> change_cut_player(cut_player)
      %Ecto.Changeset{data: %CutPlayer{}}

  """
  def change_cut_player(%CutPlayer{} = cut_player, attrs \\ %{}) do
    CutPlayer.changeset(cut_player, attrs)
  end

  @doc """
  Cut the player and remove from rostered_players

  """
  def cut_player_and_remove_from_rostered_players(rostered_player = %RosteredPlayer{}) do
    rostered_player = Repo.preload(rostered_player, [:player, :team, :auction])
    auction = rostered_player.auction
    team = rostered_player.team
    player = rostered_player.player
    cut_player =
      %CutPlayer{
        cost: rostered_player.cost,
        player: player
      }
    cut_player = Ecto.build_assoc(team, :cut_players, cut_player)
    cut_player = Ecto.build_assoc(auction, :cut_players, cut_player)
    Repo.transaction(fn ->
      Repo.insert!(cut_player)
      delete_rostered_player(rostered_player)
      Bids.log_bid(auction, team, player, cut_player.cost, "C")
      Auctions.broadcast({:ok, auction}, :roster_change)
      Teams.broadcast({:ok, team}, :roster_change)
      Players.broadcast({:ok, player}, :info_change)
    end)
  end

  @doc """
  Returns the list of ordered_players.

  ## Examples

      iex> list_ordered_players()
      [%OrderedPlayer{}, ...]

  """
  def list_ordered_players do
    Repo.all(OrderedPlayer)
  end

  @doc """
  Gets a single ordered_player.

  Raises `Ecto.NoResultsError` if the Ordered player does not exist.

  ## Examples

      iex> get_ordered_player!(123)
      %OrderedPlayer{}

      iex> get_ordered_player!(456)
      ** (Ecto.NoResultsError)

  """
  def get_ordered_player!(id), do: Repo.get!(OrderedPlayer, id)

  @doc """
  Creates a ordered_player.

  ## Examples

      iex> create_ordered_player(%{field: value})
      {:ok, %OrderedPlayer{}}

      iex> create_ordered_player(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_ordered_player(attrs \\ %{}) do
    %OrderedPlayer{}
    |> OrderedPlayer.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a ordered_player.

  ## Examples

      iex> update_ordered_player(ordered_player, %{field: new_value})
      {:ok, %OrderedPlayer{}}

      iex> update_ordered_player(ordered_player, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_ordered_player(%OrderedPlayer{} = ordered_player, attrs) do
    ordered_player
    |> OrderedPlayer.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a ordered_player.

  ## Examples

      iex> delete_ordered_player(ordered_player)
      {:ok, %OrderedPlayer{}}

      iex> delete_ordered_player(ordered_player)
      {:error, %Ecto.Changeset{}}

  """
  def delete_ordered_player(%OrderedPlayer{} = ordered_player) do
    Repo.delete(ordered_player)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking ordered_player changes.

  ## Examples

      iex> change_ordered_player(ordered_player)
      %Ecto.Changeset{data: %OrderedPlayer{}}

  """
  def change_ordered_player(%OrderedPlayer{} = ordered_player, attrs \\ %{}) do
    OrderedPlayer.changeset(ordered_player, attrs)
  end

  def list_values do
    Repo.all(Value)
  end

  def get_value!(id), do: Repo.get!(Value, id)

  def create_value(%Player{} = player, %Team{} = team, value) do
    %Value{}
    |> Value.changeset(%{value: value})
    |> Ecto.Changeset.put_assoc(:player, player)
    |> Ecto.Changeset.put_assoc(:team, team)
    |> Repo.insert()
  end

  def update_value(%Value{} = value, attrs) do
    value
    |> Value.changeset(attrs)
    |> Repo.update()
  end

  def get_value(%Player{} = player, %Team{} = team) do
    Repo.one(from v in Value, where: v.player_id == ^player.id and v.team_id == ^team.id)
  end

  def delete_value(%Value{} = value) do
    Repo.delete(value)
  end

  def change_value(%Value{} = value, attrs \\ %{}) do
    Value.changeset(value, attrs)
  end
end
