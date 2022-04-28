defmodule SSAuction.Repo.Migrations.RenameAuctionsTableTeamDollarsPerPlayerColumn do
  use Ecto.Migration

  def change do
    rename table(:auctions), :team_dollars_per_player, to: :dollars_per_team
  end
end
