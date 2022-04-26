defmodule Ssauction.Repo.Migrations.CreatePlayerValues do
  use Ecto.Migration

  def change do
    create table(:player_values) do
      add :value, :integer
      add :player_id, references(:players), null: false
      add :team_id, references(:teams), null: false

      timestamps()
    end
    create index("player_values", :player_id)
    create index("player_values", :team_id)
  end
end
