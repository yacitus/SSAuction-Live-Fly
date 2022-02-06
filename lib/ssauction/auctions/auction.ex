defmodule SSAuction.Auctions.Auction do
  use Ecto.Schema
  import Ecto.Changeset

  schema "auctions" do
    field :active, :boolean, default: false
    field :bid_timeout_seconds, :integer, default: 60*60*12 # bid timeout after new team places new high bid
    field :initial_bid_timeout_seconds, :integer, default: 60*60*24 # bid timeout after nomination
    field :must_roster_all_players, :boolean, default: true
    field :name, :string
    field :new_nominations_created, :string, default: "time" # "time" means at a time specified in the team record; "auction" means when the auction closes on a previously nominated player
    field :nominations_per_team, :integer, default: 2
    field :players_per_team, :integer
    field :seconds_before_autonomination, :integer, default: 60*60
    field :started_or_paused_at, :utc_datetime
    field :team_dollars_per_player, :integer
    field :year_range, :string

    has_many :players, SSAuction.Players.Player
    has_many :teams, SSAuction.Teams.Team
    has_many :bids, SSAuction.Bids.Bid
    has_many :rostered_players, SSAuction.Players.RosteredPlayer
    has_many :ordered_players, SSAuction.Players.OrderedPlayer
    has_many :bid_logs, SSAuction.Bids.BidLog

    timestamps()
  end

  @doc false
  def changeset(auction, attrs) do
    auction
    |> cast(attrs, [:name, :year_range, :nominations_per_team, :seconds_before_autonomination, :new_nominations_created, :initial_bid_timeout_seconds, :bid_timeout_seconds, :players_per_team, :must_roster_all_players, :team_dollars_per_player, :active, :started_or_paused_at])
    |> validate_required([:name, :year_range, :nominations_per_team, :seconds_before_autonomination, :new_nominations_created, :initial_bid_timeout_seconds, :bid_timeout_seconds, :players_per_team, :must_roster_all_players, :team_dollars_per_player, :active, :started_or_paused_at])
  end
end
