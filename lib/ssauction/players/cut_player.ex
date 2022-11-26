defmodule SSAuction.Players.CutPlayer do
  use Ecto.Schema
  import Ecto.Changeset

  schema "cut_players" do
    field :cost, :integer

    has_one :player, SSAuction.Players.Player
    belongs_to :team, SSAuction.Teams.Team
    belongs_to :auction, SSAuction.Auctions.Auction

    timestamps()
  end

  def changeset(cut_player, params \\ %{}) do
    required_fields = [:cost]

    cut_player
    |> cast(params, required_fields)
    |> validate_required(required_fields)
  end
end
