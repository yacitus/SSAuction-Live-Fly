defmodule SSAuction.Bids do
  @moduledoc """
  The Bids context.
  """

  import Ecto.Query, warn: false
  alias SSAuction.Repo

  alias SSAuction.Bids.BidLog
  alias SSAuction.Players.Player
  alias SSAuction.Auctions.Auction
  alias SSAuction.Teams.Team

  @doc """
  Returns the list of bid_logs.

  ## Examples

      iex> list_bid_logs()
      [%BidLog{}, ...]

  """
  def list_bid_logs do
    Repo.all(BidLog)
  end

  @doc """
  Gets a single bid_log.

  Raises `Ecto.NoResultsError` if the Bid log does not exist.

  ## Examples

      iex> get_bid_log!(123)
      %BidLog{}

      iex> get_bid_log!(456)
      ** (Ecto.NoResultsError)

  """
  def get_bid_log!(id), do: Repo.get!(BidLog, id)

  @doc """
  Creates a bid_log.

  ## Examples

      iex> create_bid_log(%{field: value})
      {:ok, %BidLog{}}

      iex> create_bid_log(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_bid_log(attrs \\ %{}) do
    %BidLog{}
    |> BidLog.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a bid_log.

  ## Examples

      iex> update_bid_log(bid_log, %{field: new_value})
      {:ok, %BidLog{}}

      iex> update_bid_log(bid_log, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_bid_log(%BidLog{} = bid_log, attrs) do
    bid_log
    |> BidLog.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a bid_log.

  ## Examples

      iex> delete_bid_log(bid_log)
      {:ok, %BidLog{}}

      iex> delete_bid_log(bid_log)
      {:error, %Ecto.Changeset{}}

  """
  def delete_bid_log(%BidLog{} = bid_log) do
    Repo.delete(bid_log)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking bid_log changes.

  ## Examples

      iex> change_bid_log(bid_log)
      %Ecto.Changeset{data: %BidLog{}}

  """
  def change_bid_log(%BidLog{} = bid_log, attrs \\ %{}) do
    BidLog.changeset(bid_log, attrs)
  end

  def list_bid_logs(%Player{} = player) do
    Repo.all(from bl in BidLog,
              where: bl.player_id == ^player.id,
              join: t in assoc(bl, :team),
              preload: [team: t],
              order_by: bl.datetime)
  end

  def rostered_bid_log(%Player{} = player) do
    Repo.one(from bl in BidLog,
              where: bl.player_id == ^player.id,
              where: bl.type == "R")
  end

  def bid_log_type_string(type) do
    case type do
      "N" -> "nomination"
      "B" -> "bid"
      "U" -> "bid under hidden high bid"
      "H" -> "hidden high bid"
      "R" -> "rostered"
      _   -> "UNKNOWN"
    end
  end

  alias SSAuction.Bids.Bid

  @doc """
  Returns the list of bids.

  ## Examples

      iex> list_bids()
      [%Bid{}, ...]

  """
  def list_bids do
    Repo.all(Bid)
  end

  def list_bids(%Auction{} = auction) do
    Repo.all(from bl in Bid,
              where: bl.auction_id == ^auction.id,
              join: t in assoc(bl, :team),
              preload: [team: t],
              join: p in assoc(bl, :player),
              preload: [player: p],
              order_by: bl.expires_at)
  end

  def list_bids(%Team{} = team) do
    Repo.all(from bl in Bid,
              where: bl.team_id == ^team.id,
              join: t in assoc(bl, :team),
              preload: [team: t],
              join: p in assoc(bl, :player),
              preload: [player: p],
              order_by: bl.expires_at)
  end

  @doc """
  Gets a single bid.

  Raises `Ecto.NoResultsError` if the Bid does not exist.

  ## Examples

      iex> get_bid!(123)
      %Bid{}

      iex> get_bid!(456)
      ** (Ecto.NoResultsError)

  """
  def get_bid!(id), do: Repo.get!(Bid, id)

  @doc """
  Creates a bid.

  ## Examples

      iex> create_bid(%{field: value})
      {:ok, %Bid{}}

      iex> create_bid(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_bid(attrs \\ %{}) do
    %Bid{}
    |> Bid.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a bid.

  ## Examples

      iex> update_bid(bid, %{field: new_value})
      {:ok, %Bid{}}

      iex> update_bid(bid, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_bid(%Bid{} = bid, attrs) do
    bid
    |> Bid.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a bid.

  ## Examples

      iex> delete_bid(bid)
      {:ok, %Bid{}}

      iex> delete_bid(bid)
      {:error, %Ecto.Changeset{}}

  """
  def delete_bid(%Bid{} = bid) do
    Repo.delete(bid)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking bid changes.

  ## Examples

      iex> change_bid(bid)
      %Ecto.Changeset{data: %Bid{}}

  """
  def change_bid(%Bid{} = bid, attrs \\ %{}) do
    Bid.changeset(bid, attrs)
  end

  def number_of_bids(%Auction{} = auction) do
    auction
      |> Ecto.assoc(:bids)
      |> Repo.aggregate(:count, :id)
  end

  def number_of_bids(%Team{} = team) do
    team
      |> Ecto.assoc(:bids)
      |> Repo.aggregate(:count, :id)
  end

  def seconds_until_bid_expires(%Bid{} = bid, %Auction{} = auction) do
    DateTime.diff(bid.expires_at, auction.started_or_paused_at)
  end
end
