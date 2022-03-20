defmodule SSAuction.Bids do
  @moduledoc """
  The Bids context.
  """

  import Ecto.Query, warn: false
  alias SSAuction.Repo

  alias SSAuction.Bids.BidLog
  alias SSAuction.Players.Player
  alias SSAuction.Players.RosteredPlayer
  alias SSAuction.Auctions.Auction
  alias SSAuction.Teams.Team
  alias SSAuction.Auctions
  alias SSAuction.Teams
  alias SSAuction.Players
  alias SSAuction.ChangesetErrors

  def subscribe do
    Phoenix.PubSub.subscribe(SSAuction.PubSub, "bids")
  end

  def broadcast({:ok, bid}, event) do
    Phoenix.PubSub.broadcast(
      SSAuction.PubSub,
      "bids",
      {event, bid}
    )
    {:ok, bid}
  end

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
  Returns an `%Ecto.Changeset{}` for tracking bid changes.

  ## Examples

      iex> change_bid(bid)
      %Ecto.Changeset{data: %Bid{}}

  """
  def change_bid(%Bid{} = bid, attrs \\ %{}) do
    Bid.changeset(bid, attrs)
  end

  @doc """
  Submits a new bid

  """
  def submit_new_bid(auction = %Auction{}, team = %Team{}, player = %Player{}, attrs) do
    insert =
      change_bid(%Bid{}, Map.put(attrs, :nominated_by, team.id))
        |> Ecto.Changeset.put_assoc(:auction, auction)
        |> Ecto.Changeset.put_assoc(:team, team)
        |> Ecto.Changeset.put_assoc(:player, player)
        |> Repo.insert()
    case insert do
      {:ok, bid} ->
        log_bid(bid, auction, team, player, "N")
    end
    insert
  end

  @doc """
  Updates an existing bid

  """
  def update_existing_bid(bid, new_team = %Team{}, attrs) do
    update = bid
      |> Repo.preload([:team, :auction, :player])
      |> change_bid(attrs)
      |> Ecto.Changeset.put_assoc(:team, new_team)
      |> Repo.update()
    case update do
      {:ok, bid} ->
        log_bid(bid, bid.auction, bid.team, bid.player, "B")
    end
    update
  end

  def submit_bid_changeset(auction, team, player, args, nil) do
    {:ok, utc_datetime} = DateTime.now("Etc/UTC")
    args = Map.put(args, :expires_at, DateTime.add(utc_datetime, auction.initial_bid_timeout_seconds, :second))

    args = if not Map.has_key?(args, :hidden_high_bid) do
      Map.put(args, :hidden_high_bid, nil)
    else
      args
    end

    case submit_new_bid(auction, team, player, args) do
      {:error, changeset} ->
        {
          :error,
          message: "Could not submit bid!",
          details: ChangesetErrors.error_details(changeset)
        }

      {:ok, bid} ->
        Teams.update_info_post_nomination(team)
        Auctions.remove_from_nomination_queues(auction, player)
        Auctions.broadcast({:ok, auction}, :nomination_queue_change)
        Teams.broadcast({:ok, team}, :nomination_queue_change)
        Auctions.broadcast({:ok, auction}, :bid_change)
        Teams.broadcast({:ok, team}, :bid_change)
        Teams.broadcast({:ok, team}, :info_change)
        Auctions.broadcast({:ok, auction}, :teams_info_change)
        Players.broadcast({:ok, player}, :info_change)
        {:ok, bid}
    end
  end

  def submit_bid_changeset(auction, team, player, args, existing_bid) do
    args = if team.id != existing_bid.team_id do
      {:ok, utc_datetime} = DateTime.now("Etc/UTC")
      if DateTime.diff(existing_bid.expires_at, utc_datetime) < auction.bid_timeout_seconds do
        Map.put(args, :expires_at, DateTime.add(utc_datetime, auction.bid_timeout_seconds, :second))
      else
        args
      end
    else
      args
    end

    args = if not Map.has_key?(args, :hidden_high_bid) do
      Map.put(args, :hidden_high_bid, nil)
    else
      args
    end

    args = if not Map.has_key?(args, :keep_bidding_up_to) do
      Map.put(args, :keep_bidding_up_to, nil)
    else
      args
    end

    current_team_max_bid = if existing_bid.hidden_high_bid != nil do
      max(existing_bid.bid_amount, existing_bid.hidden_high_bid)
    else
      existing_bid.bid_amount
    end

    args =
      cond do
        team.id == existing_bid.team_id ->
          args
        args.bid_amount > current_team_max_bid ->
          args
        true ->
          Map.put(args, :bid_amount, current_team_max_bid + 1)
      end

    case update_existing_bid(existing_bid, team, args) do
      {:error, changeset} ->
        {
          :error,
          message: "Could not update bid!",
          details: ChangesetErrors.error_details(changeset)
        }

      {:ok, bid} ->
        Auctions.broadcast({:ok, auction}, :bid_change)
        Teams.broadcast({:ok, team}, :bid_change)
        previous_team = Teams.get_team!(existing_bid.team_id)
        Teams.broadcast({:ok, previous_team}, :bid_change)
        Teams.broadcast({:ok, team}, :info_change)
        Teams.broadcast({:ok, previous_team}, :info_change)
        Auctions.broadcast({:ok, auction}, :teams_info_change)
        Players.broadcast({:ok, player}, :info_change)
        {:ok, bid}
    end
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

  @doc """
  Roster the player from this bid and delete the bid

  """
  def roster_player_and_delete_bid(bid = %Bid{}) do
    bid = Repo.preload(bid, [:player, :team, :auction])
    auction = bid.auction
    team = bid.team
    player = bid.player
    rostered_player =
      %RosteredPlayer{
        cost: bid.bid_amount,
        player: player
      }
    rostered_player = Ecto.build_assoc(team, :rostered_players, rostered_player)
    rostered_player = Ecto.build_assoc(auction, :rostered_players, rostered_player)
    Repo.insert!(rostered_player)
    nominating_team = Teams.get_team!(bid.nominated_by)
    delete_bid(bid, auction, team, player, nominating_team)
    log_bid(bid, auction, team, player, "R")
    Teams.update_unused_nominations(nominating_team, auction)
    Auctions.broadcast({:ok, auction}, :roster_change)
    Teams.broadcast({:ok, team}, :roster_change)
    Players.broadcast({:ok, player}, :info_change)
  end

  @doc """
  Delete the bid

  """
  def delete_bid(bid = %Bid{}) do
    bid = Repo.preload(bid, [:player, :team, :auction])
    auction = bid.auction
    team = bid.team
    player = bid.player
    nominating_team = Teams.get_team!(bid.nominated_by)
    delete_bid(bid, auction, team, player, nominating_team)
  end


  def delete_bid(bid = %Bid{}, auction = %Auction{}, team = %Team{}, player = %Player{}, nominating_team = %Team{}) do
    player
    |> Ecto.Changeset.change(%{bid_id: nil})
    |> Repo.update
    bid
    |> Ecto.Changeset.change
    |> Repo.delete

    Auctions.broadcast({:ok, auction}, :bid_change)
    Teams.broadcast({:ok, team}, :bid_change)
    Teams.broadcast({:ok, team}, :info_change)
    Teams.broadcast({:ok, nominating_team}, :info_change)
    Auctions.broadcast({:ok, auction}, :teams_info_change)
  end

  @doc """
  Logs a bid

  """
  def log_bid(bid = %Bid{}, auction = %Auction{}, team = %Team{}, player = %Player{}, type) do
    {:ok, now} = DateTime.now("Etc/UTC")
    %BidLog{}
    |> BidLog.changeset(%{amount: bid.bid_amount,
                          type: type,
                          datetime: now})
    |> Ecto.Changeset.put_assoc(:auction, auction)
    |> Ecto.Changeset.put_assoc(:team, team)
    |> Ecto.Changeset.put_assoc(:player, player)
    |> Repo.insert()
    Players.broadcast({:ok, player}, :bid_log_change)
  end
end
