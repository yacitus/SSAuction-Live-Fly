defmodule SSAuction.Players.Player do
  use Ecto.Schema
  import Ecto.Changeset

  schema "players" do
    field :year_range, :string
    field :ssnum, :integer
    field :name, :string
    field :position, :string

    belongs_to :auction, SSAuction.Auctions.Auction
    belongs_to :bid, SSAuction.Bids.Bid
    belongs_to :rostered_player, SSAuction.Players.RosteredPlayer
    belongs_to :cut_player, SSAuction.Players.CutPlayer
    has_many :ordered_players, SSAuction.Players.OrderedPlayer
    has_many :bid_logs, SSAuction.Bids.BidLog
    has_many :player_values, SSAuction.Players.Value
  end

  def changeset(player, params \\ %{}) do
    required_fields = [:year_range, :ssnum, :name, :position, :auction_id]

    player
    |> cast(params, required_fields)
    |> validate_required(required_fields)
    # TODO - :position should be split by / and each slice confirmed to be in the list below
    # |> validate_inclusion(:position, ["SP", "RP", "C", "1B", "2B", "3B", "SS", "OF", "DH"])
    |> validate_year_range()
    |> assoc_constraint(:auction)
  end

  def validate_year_range(changeset) do
    case changeset.valid? do
      true ->
        year_range = get_field(changeset, :year_range)

        case String.length(year_range) do
          7 ->
            case parse_year_range(year_range) do
              %{"year" => _year, "league" => _league} ->
                changeset

              _ ->
                add_error(changeset, :year_range, "can't find start and end year")
            end

          _ ->
            add_error(changeset, :year_range, "must be 7 characters")
        end

      _ ->
        changeset
    end
  end

  def parse_year_range(year_range) do
    Regex.named_captures(~r/(?<year>\d{4})-(?<league>[A-Z]{2})/, year_range)
  end
end
