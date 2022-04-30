defmodule SSAuction.Players.Value do
  use Ecto.Schema
  import Ecto.Changeset

  schema "player_values" do
    field :value, :integer

    belongs_to :player, SSAuction.Players.Player
    belongs_to :team, SSAuction.Teams.Team

    timestamps()
  end

  @doc false
  def changeset(value, attrs) do
    value
    |> cast(attrs, [:value])
    |> validate_required([:value])
  end
end
