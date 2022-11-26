defmodule SSAuction.Repo.Migrations.AddCutPlayerIdToPlayers do
  use Ecto.Migration

  def change do
    alter table(:players) do
      add :cut_player_id, references("cut_players")
    end
  end
end
