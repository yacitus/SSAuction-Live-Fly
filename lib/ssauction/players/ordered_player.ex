defmodule SSAuction.Players.OrderedPlayer do
  use Ecto.Schema
  import Ecto.Changeset

  schema "ordered_players" do
    field :rank, :integer

    belongs_to :player, SSAuction.Players.Player
    belongs_to :team, SSAuction.Teams.Team
    belongs_to :auction, SSAuction.Auctions.Auction
  end

  @doc false
  def changeset(ordered_player, attrs) do
    required_fields = [:rank]

    ordered_player
    |> cast(attrs, required_fields)
    |> validate_required(required_fields)
  end
end
