defmodule SSAuction.Repo.Migrations.AddTeamsSsnum do
  use Ecto.Migration

  def change do
    alter table(:teams) do
      add :ssnum, :integer
    end
  end
end
