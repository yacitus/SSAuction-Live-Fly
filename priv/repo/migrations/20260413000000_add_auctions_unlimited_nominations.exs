defmodule SSAuction.Repo.Migrations.AddAuctionsUnlimitedNominations do
  use Ecto.Migration

  def change do
    alter table(:auctions) do
      add :unlimited_nominations, :boolean, default: false
    end
  end
end
