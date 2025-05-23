defmodule SSAuction.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  defp append_if(list, condition, item) do
    if condition, do: list ++ [item], else: list
  end

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      SSAuction.Repo,
      # Start the Telemetry supervisor
      SSAuctionWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: SSAuction.PubSub},
      # Start the Endpoint (http/https)
      SSAuctionWeb.Endpoint,
      # cache of SSAuction.Auctions.get_rostered_players_with_rostered_at(auction)
      {Cachex, [:auction_rostered_players]},
      # Start a worker by calling: SSAuction.Worker.start_link(arg)
      # {SSAuction.Worker, arg}
    ]
    |> append_if(System.get_env("PERIODIC_CHECK") == "ON", SSAuction.PeriodicCheck)

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: SSAuction.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    SSAuctionWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
