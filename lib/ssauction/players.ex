defmodule SSAuction.Players do
  @moduledoc """
  The Players context.
  """

  import Ecto.Query, warn: false
  alias SSAuction.Repo

  alias SSAuction.Players.AllPlayer

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
  def create_all_player(attrs \\ %{}) do
    %AllPlayer{}
    |> AllPlayer.changeset(attrs)
    |> Repo.insert()
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
  Returns an `%Ecto.Changeset{}` for tracking all_player changes.

  ## Examples

      iex> change_all_player(all_player)
      %Ecto.Changeset{data: %AllPlayer{}}

  """
  def change_all_player(%AllPlayer{} = all_player, attrs \\ %{}) do
    AllPlayer.changeset(all_player, attrs)
  end

  alias SSAuction.Players.Player

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

  alias SSAuction.Players.RosteredPlayer

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
    Repo.delete(rostered_player)
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

  alias SSAuction.Players.OrderedPlayer

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
end
