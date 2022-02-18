defmodule SSAuction.Repo.Migrations.DropTeamsNameUniqueIndex do
  use Ecto.Migration

  def change do
    drop unique_index(:teams, [:name])
  end
end
