defmodule Ssauction.Repo.Migrations.CreatePlayerValues do
  use Ecto.Migration

  def change do
    create table(:player_values) do
      add :value, :integer
      add :player_id, references(:players), null: false
      add :team_id, references(:teams), null: false

      timestamps()
    end

    # alter table("players") do
    #   add :player_value_id, references(:player_values)
    # end

    # alter table("auctions") do
    #   add :player_value_id, references(:player_values)
    # end
  end

  # def down do
  #   drop table("player_values")
  # end
end
