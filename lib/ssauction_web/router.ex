defmodule SSAuctionWeb.Router do
  use SSAuctionWeb, :router

  import SSAuctionWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {SSAuctionWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", SSAuctionWeb do
    pipe_through :browser

    live "/", AuctionLive.Index, :index
    live "/auctions", AuctionLive.Index, :index
    live "/auction/:id", AuctionLive.Show
    live "/auction/:id/autonomination_queue", AuctionLive.AutoNominationQueue
    live "/auction/:id/bids", AuctionLive.Bids
    live "/auction/:id/rostered_players", AuctionLive.RosteredPlayers

    live "/team/:id", TeamLive.Show, :show
    live "/team/:id/bids", TeamLive.Bids
    live "/team/:id/rostered_players", TeamLive.RosteredPlayers

    live "/player/:id", PlayerLive.Show, :show

    get "/export_rosters", ExportRostersController, :create
  end

  # Other scopes may use custom stacks.
  # scope "/api", SSAuctionWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: SSAuctionWeb.Telemetry
    end
  end

  # Enables the Swoosh mailbox preview in development.
  #
  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", SSAuctionWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    # get "/users/register", UserRegistrationController, :new
    # post "/users/register", UserRegistrationController, :create
    get "/users/log_in", UserSessionController, :new
    post "/users/log_in", UserSessionController, :create
    get "/users/reset_password", UserResetPasswordController, :new
    post "/users/reset_password", UserResetPasswordController, :create
    get "/users/reset_password/:token", UserResetPasswordController, :edit
    put "/users/reset_password/:token", UserResetPasswordController, :update
  end

  scope "/", SSAuctionWeb do
    pipe_through [:browser, :require_authenticated_user]

    get "/users/settings", UserSettingsController, :edit
    put "/users/settings", UserSettingsController, :update
    get "/users/settings/confirm_email/:token", UserSettingsController, :confirm_email

    live "/auction/:id/edit", AuctionLive.Edit

    live "/team/:id/edit", TeamLive.Edit
    live "/team/:id/nomination_queue", TeamLive.NominationQueue
  end

  scope "/", SSAuctionWeb do
    pipe_through [:browser, :require_authenticated_super_user]

    live "/admin/import_players", AdminLive.ImportPlayers
    live "/admin/allplayers", AdminLive.AllPlayers
    live "/admin/create_auction", AdminLive.CreateAuction
    live "/admin/auction/:id/create_team", AdminLive.CreateTeam
    live "/admin/team/:id/add_user", AdminLive.AddUserToTeam
    live "/admin/team/:id/change_team_new_nominations_open_at", AdminLive.ChangeTeamNewNominationsOpenAt
    live "/admin/team/:id/change_team_total_supplemental_dollars", AdminLive.ChangeTeamTotalSupplementalDollars
    live "/admin/auction/:id/add_admin_user", AdminLive.AddUserToAuctionAdmins
    live "/admin/confirm_user", AdminLive.ConfirmUser
    live "/admin/auction/:id/import_nomination_queue", AdminLive.ImportNominationQueue
    live "/admin/auction/:id/edit", AdminLive.EditAuction
    live "/admin/auction/:id/start_or_pause", AdminLive.StartOrPauseAuction
    live "/admin/auction/:id/add_new_players", AdminLive.AddNewPlayersToAuction
    live "/admin/auction/:id/export_rosters", AdminLive.ExportRosters
  end

  scope "/", SSAuctionWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete
    get "/users/confirm", UserConfirmationController, :new
    post "/users/confirm", UserConfirmationController, :create
    get "/users/confirm/:token", UserConfirmationController, :edit
    post "/users/confirm/:token", UserConfirmationController, :update
  end
end
