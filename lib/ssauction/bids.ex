defmodule SSAuction.Bids do
  @moduledoc """
  The Bids context.
  """

  import Ecto.Query, warn: false
  alias SSAuction.Repo

  alias SSAuction.Bids.Bid
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

  def list_bids_with_expires_in(%Auction{} = auction) do
    bids = list_bids(auction)
    add_expires_in_to_bids(bids, auction)
  end

  def list_bids_with_expires_in(%Team{} = team) do
    bids = list_bids(team)
    auction = Auctions.get_auction!(team.auction_id)
    add_expires_in_to_bids(bids, auction)
  end

  def list_bids_with_expires_in(%Auction{} = auction, sort_options) do
    list_bids_with_expires_in(auction)
      |> sort_bids(sort_options)
  end

  def list_bids_with_expires_in(%Team{} = team, sort_options) do
    list_bids_with_expires_in(team)
      |> sort_bids(sort_options)
  end

  def list_bids_with_expires_in_and_surplus(%Team{} = team, %Team{} = current_team) do
    list_bids_with_expires_in(team)
      |> add_surplus_to_bids(current_team)
  end

  def list_bids_with_expires_in_and_surplus(%Team{} = team, nil) do
    list_bids_with_expires_in(team)
  end

  def list_bids_with_expires_in_and_surplus(%Auction{} = auction, %Team{} = team, sort_options) do
    list_bids_with_expires_in(auction)
      |> add_surplus_to_bids(team)
      |> sort_bids(sort_options)
  end

  def list_bids_with_expires_in_and_surplus(%Auction{} = auction, nil, sort_options) do
    list_bids_with_expires_in(auction, sort_options)
  end

  defp add_expires_in_to_bids(bids, auction) do
    Enum.map(bids,
             fn bid -> seconds_until_bid_expires = seconds_until_bid_expires(bid, auction)
                       bid
                       |> Map.put(:seconds_until_bid_expires, seconds_until_bid_expires)
                       |> Map.put(:expires_in, Auctions.seconds_to_string(seconds_until_bid_expires))
                       |> Map.put(:team_name, bid.team.name)
                       |> Map.put(:player_name, bid.player.name)
                       |> Map.put(:player_position, bid.player.position)
                       |> Map.put(:player_ssnum, bid.player.ssnum)
             end)
  end

  defp add_surplus_to_bids(bids, team) do
    Enum.map(bids,
             fn bid -> value_struct = Players.get_value(bid.player, team)
                       value = if value_struct == nil, do: 0, else: value_struct.value
                       Map.put(bid, :surplus, value - bid.bid_amount)
             end)
  end

  defp sort_bids(bids, %{sort_by: sort_by, sort_order: sort_order}) do
    Enum.sort_by(bids, fn bid -> Map.get(bid, sort_by) end, sort_order)
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

  def get_bid_with_team_and_player!(id) do
    get_bid!(id)
      |> Repo.preload([:team, :player])
  end

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
        log_bid(auction, team, player, bid.bid_amount, "N")
        broadcast({:ok, bid}, :new_nomination)
    end
    insert
  end

  @doc """
  Updates an existing bid

  """
  def update_existing_bid(bid, new_team = %Team{}, attrs) do
    bid
      |> Repo.preload([:team, :auction, :player])
      |> change_bid(attrs)
      |> Ecto.Changeset.put_assoc(:team, new_team)
      |> Repo.update()
  end

  def submit_bid_changeset(auction = %Auction{}, team = %Team{}, player = %Player{}, args) do
    {:ok, utc_datetime} = DateTime.now("Etc/UTC")
    args = Map.put(args, :expires_at, DateTime.add(utc_datetime, auction.initial_bid_timeout_seconds, :second))

    args = if not Map.has_key?(args, :hidden_high_bid) do
      Map.put(args, :hidden_high_bid, nil)
    else
      args
    end

    case submit_new_bid(auction, team, player, args) do
      {:error, changeset} ->
        { :error, "Could not submit nomination: " <> ChangesetErrors.error_details(changeset) }

      {:ok, bid} ->
        Teams.update_info_post_nomination(team.id)
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

  def submit_bid_changeset(auction = %Auction{}, team = %Team{}, existing_bid = %Bid{}, args) do
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

    current_team_max_bid =
      if existing_bid.hidden_high_bid != nil do
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
        { :error, "Could not update bid:" <> ChangesetErrors.error_details(changeset) }

      {:ok, bid} ->
        Auctions.broadcast({:ok, auction}, :bid_change)
        Teams.broadcast({:ok, team}, :bid_change)
        previous_team = Teams.get_team!(existing_bid.team_id)
        Teams.broadcast({:ok, previous_team}, :bid_change)
        Teams.broadcast({:ok, team}, :info_change)
        Teams.broadcast({:ok, previous_team}, :info_change)
        Auctions.broadcast({:ok, auction}, :teams_info_change)
        Players.broadcast({:ok, existing_bid.player}, :info_change)
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
    if auction.active do
      {:ok, now} = DateTime.now("Etc/UTC")
      DateTime.diff(bid.expires_at, now)
    else
      DateTime.diff(bid.expires_at, auction.started_or_paused_at)
    end
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
    broadcast({:ok, bid}, :deleted_bid)
    log_bid(auction, team, player, bid.bid_amount, "R")
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
  def log_bid(auction = %Auction{}, team = %Team{}, player = %Player{}, bid_amount, type) do
    {:ok, now} = DateTime.now("Etc/UTC")
    %BidLog{}
    |> BidLog.changeset(%{amount: bid_amount,
                          type: type,
                          datetime: now})
    |> Ecto.Changeset.put_assoc(:auction, auction)
    |> Ecto.Changeset.put_assoc(:team, team)
    |> Ecto.Changeset.put_assoc(:player, player)
    |> Repo.insert()
    Players.broadcast({:ok, player}, :bid_log_change)
  end

  def string_to_integer(string) do
    if string == nil do
      nil
    else
      case Integer.parse(string) do
        {int, _} -> int
        :error -> nil
      end
    end
  end

  def validate_nomination(auction_id, team_id, player_id, bid_amount, hidden_high_bid) do
    auction = Auctions.get_auction!(auction_id)
    team = Teams.get_team!(team_id)
    player = Players.get_player!(player_id)

    bid_amount = string_to_integer(bid_amount)
    hidden_high_bid = string_to_integer(hidden_high_bid)

    cond do
      not auction.active ->
        { :error, "Auction is paused" }
      not Auctions.team_is_in_auction?(auction, team) ->
        { :error, "Team is not in auction" }
      Players.is_rostered?(player) ->
        { :error, "Player is already rostered" }
      bid_amount == nil ->
        { :error, "Bid amount invalid" }
      not hidden_high_bid_legal?(hidden_high_bid, bid_amount) ->
        { :error, "Hidden high bid must be nothing or above bid amount" }
      Players.in_bids?(player) ->
        { :error, "Player already nominated" }
      team.unused_nominations == 0 ->
        { :error, "Team does not have an open nomination" }
      not Teams.legal_bid_amount?(team, bid_amount, hidden_high_bid) ->
        { :error, "Bid amount not legal for team" }
      not Teams.has_open_roster_spot?(team, auction) ->
        { :error, "Team does not have open roster spot for another bid" }
      true ->
        {:ok, nil}
    end
  end

  def validate_edited_bid(bid_for_edit = %Bid{}, auction_id, team_id, bid_amount, hidden_high_bid, keep_bidding_up_to) do
    auction = Auctions.get_auction!(auction_id)
    team = Teams.get_team!(team_id)

    bid_amount = string_to_integer(bid_amount)
    hidden_high_bid = string_to_integer(hidden_high_bid)
    keep_bidding_up_to = string_to_integer(keep_bidding_up_to)

    cond do
      bid_for_edit.team_id != team.id and bid_amount <= bid_for_edit.bid_amount ->
        { :error, "Bid amount is not larger than existing bid"}
      bid_for_edit.team_id != team.id and not keep_bidding_up_to_legal?(keep_bidding_up_to, bid_amount) ->
        { :error, "Keep bidding up to amount is not larger than bid amount"}
      bid_for_edit.team_id != team.id and not keep_bidding_up_to_and_hidden_high_bid_legal?(keep_bidding_up_to, hidden_high_bid) ->
        { :error, "Hidden high bid is less than keep bidding up to amount"}
      bid_for_edit.team_id == team.id and bid_amount != nil ->
        { :error, "Cannot change bid amount"}
      bid_for_edit.team_id == team.id and bid_for_edit.hidden_high_bid == hidden_high_bid ->
        { :error, "Nothing is changed"}
      bid_for_edit.team_id == team.id and keep_bidding_up_to != nil ->
        { :error, "Keep Bidding Up To does not apply when editing bid"}
      not auction.active ->
        { :error, "Auction is paused" }
      not Auctions.team_is_in_auction?(auction, team) ->
        { :error, "Team is not in auction" }
      bid_for_edit.team_id != team.id and bid_amount == nil ->
        { :error, "Bid amount invalid" }
      bid_for_edit.team_id != team.id and not hidden_high_bid_legal?(hidden_high_bid, bid_amount) ->
        { :error, "Hidden high bid must be nothing or above bid amount" }
      not Teams.legal_bid_amount?(team, bid_amount, hidden_high_bid, bid_for_edit.hidden_high_bid) ->
        { :error, "Bid amount not legal for team" }
      true ->
        {:ok, nil}
    end
  end

  defp hidden_high_bid_legal?(nil, _) do
    true
  end

  defp hidden_high_bid_legal?(hidden, bid_amount) do
    hidden > bid_amount
  end

  defp keep_bidding_up_to_legal?(nil, _) do
    true
  end

  defp keep_bidding_up_to_legal?(keep_bidding_up_to, bid_amount) do
    keep_bidding_up_to > bid_amount
  end

  defp keep_bidding_up_to_and_hidden_high_bid_legal?(nil, _) do
    true
  end

  defp keep_bidding_up_to_and_hidden_high_bid_legal?(_, nil) do
    true
  end

  defp keep_bidding_up_to_and_hidden_high_bid_legal?(keep_bidding_up_to, hidden_high_bid) do
    hidden_high_bid >= keep_bidding_up_to
  end

  def submit_nomination(auction = %Auction{}, team = %Team{}, player = %Player{}, bid_amount, hidden_high_bid) do
    submit_bid_changeset(auction, team, player, %{bid_amount: bid_amount, hidden_high_bid: hidden_high_bid})
  end

  def submit_edited_bid(auction = %Auction{}, team = %Team{}, bid_for_edit = %Bid{}, bid_amount, hidden_high_bid, keep_bidding_up_to) do
    bid_amount = string_to_integer(bid_amount)
    hidden_high_bid = string_to_integer(hidden_high_bid)
    keep_bidding_up_to = string_to_integer(keep_bidding_up_to)

    cond do
      team.id == bid_for_edit.team_id ->
        submit_bid_changeset(auction, team, bid_for_edit, %{bid_amount: bid_for_edit.bid_amount, hidden_high_bid: hidden_high_bid})
      bid_amount > max_bid(bid_for_edit.bid_amount, bid_for_edit.hidden_high_bid) ->
        submit_bid_changeset(auction, team, bid_for_edit, %{bid_amount: bid_amount, hidden_high_bid: hidden_high_bid})
        log_bid(auction, team, bid_for_edit.player, bid_amount, "B")
      keep_bidding_up_to != nil and keep_bidding_up_to > max_bid(bid_for_edit.bid_amount, bid_for_edit.hidden_high_bid) ->
        bid_amount = max_bid(bid_for_edit.bid_amount, bid_for_edit.hidden_high_bid)+1
        submit_bid_changeset(auction, team, bid_for_edit, %{bid_amount: bid_amount, hidden_high_bid: hidden_high_bid})
        log_bid(auction, team, bid_for_edit.player, bid_amount, "B")
      bid_for_edit.hidden_high_bid != nil ->
        bid_amount = max_bid(bid_amount, keep_bidding_up_to)
        log_bid(auction, team, bid_for_edit.player, bid_amount, "U")
        same_team = Teams.get_team!(bid_for_edit.team_id)
        submit_bid_changeset(auction, same_team, bid_for_edit, %{bid_amount: bid_amount, hidden_high_bid: bid_for_edit.hidden_high_bid})
        log_bid(auction, same_team, bid_for_edit.player, bid_amount, "H")
      true ->
        nil
    end
  end

  defp max_bid(bid, nil) do
    bid
  end

  defp max_bid(bid, other) do
    max(bid, other)
  end
end
