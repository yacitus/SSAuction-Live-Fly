defmodule SSAuction.Teams.Team do
  use Ecto.Schema
  import Ecto.Changeset

  schema "teams" do
    field :name, :string
    field :new_nominations_open_at, :utc_datetime
    field :time_nominations_expire, :utc_datetime
    field :unused_nominations, :integer

    belongs_to :auction, SSAuction.Auctions.Auction
    has_many :bids, SSAuction.Bids.Bid, on_replace: :nilify
    has_many :rostered_players, SSAuction.Players.RosteredPlayer
    has_many :ordered_players, SSAuction.Players.OrderedPlayer
    has_many :bid_logs, SSAuction.Bids.BidLog
  end

  @doc false
  def changeset(team, attrs) do
    team
    |> cast(attrs, [:name, :unused_nominations, :time_nominations_expire, :new_nominations_open_at])
    |> validate_required([:name, :unused_nominations, :time_nominations_expire, :new_nominations_open_at])
  end
end
