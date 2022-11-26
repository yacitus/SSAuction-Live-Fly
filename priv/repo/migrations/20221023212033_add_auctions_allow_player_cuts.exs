defmodule SSAuction.Repo.Migrations.AddAuctionsAllowPlayerCuts do
  use Ecto.Migration

  def change do
    alter table(:auctions) do
      add :allow_player_cuts, :boolean, default: false
    end
  end
end
