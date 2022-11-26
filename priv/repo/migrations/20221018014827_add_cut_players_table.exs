defmodule SSAuction.Repo.Migrations.AddCutPlayersTable do
  use Ecto.Migration

  def change do
    create table("cut_players") do
      add :cost, :integer, null: false
      add :team_id, references("teams"), null: false
      add :auction_id, references("auctions"), null: false

      timestamps()
    end
  end
end
