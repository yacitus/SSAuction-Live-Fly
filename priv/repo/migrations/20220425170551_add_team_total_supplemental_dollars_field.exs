defmodule SSAuction.Repo.Migrations.AddTeamTotalSupplementalDollarsField do
  use Ecto.Migration

  def change do
    alter table(:teams) do
      add :total_supplemental_dollars, :integer, default: 0
    end
  end
end
