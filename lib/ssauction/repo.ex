defmodule SSAuction.Repo do
  use Ecto.Repo,
    otp_app: :ssauction,
    adapter: Ecto.Adapters.Postgres
end
