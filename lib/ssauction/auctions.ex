defmodule SSAuction.Auctions do
  @moduledoc """
  The Auctions context.
  """

  import Ecto.Query, warn: false
  alias SSAuction.Repo

  alias SSAuction.Auctions.Auction
  alias SSAuction.Players.OrderedPlayer

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
  Creates a auction.

  ## Examples

      iex> create_auction(%{field: value})
      {:ok, %Auction{}}

      iex> create_auction(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_auction(attrs \\ %{}) do
    %Auction{}
    |> Auction.changeset(attrs)
    |> Repo.insert()
  end

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
    Repo.delete(auction)
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
end
