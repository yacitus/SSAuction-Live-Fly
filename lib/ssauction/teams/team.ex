defmodule SSAuction.Teams.Team do
  use Ecto.Schema
  import Ecto.Changeset

  schema "teams" do
    field :name, :string
    field :new_nominations_open_at, :utc_datetime
    field :time_nominations_expire, :utc_datetime
    field :unused_nominations, :integer
    field :total_supplemental_dollars, :integer

    belongs_to :auction, SSAuction.Auctions.Auction
    has_many :bids, SSAuction.Bids.Bid, on_replace: :nilify
    has_many :rostered_players, SSAuction.Players.RosteredPlayer
    has_many :cut_players, SSAuction.Players.CutPlayer
    has_many :ordered_players, SSAuction.Players.OrderedPlayer
    has_many :bid_logs, SSAuction.Bids.BidLog
    has_many :player_values, SSAuction.Players.Value

    many_to_many :users, SSAuction.Accounts.User, join_through: "teams_users"
  end

  @doc false
  def changeset(team, attrs) do
    required_fields = [:name, :unused_nominations, :new_nominations_open_at]
    optional_fields = [:time_nominations_expire, :total_supplemental_dollars]

    team
    |> cast(attrs, required_fields ++ optional_fields)
    |> validate_required(required_fields)
    |> unique_constraint(:name)
  end
end
