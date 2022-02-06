defmodule SSAuction.Players.RosteredPlayer do
  use Ecto.Schema
  import Ecto.Changeset

  schema "rostered_players" do
    field :cost, :integer

    has_one :player, SSAuction.Players.Player
    belongs_to :team, SSAuction.Teams.Team
    belongs_to :auction, SSAuction.Auctions.Auction
  end

  def changeset(rostered_player, params \\ %{}) do
    required_fields = [:cost]

    rostered_player
    |> cast(params, required_fields)
    |> validate_required(required_fields)
  end
end
