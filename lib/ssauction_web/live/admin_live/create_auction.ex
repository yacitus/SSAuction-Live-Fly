defmodule SSAuctionWeb.AdminLive.CreateAuction do
  use SSAuctionWeb, :live_view

  alias SSAuction.Auctions

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:changeset, Ecto.Changeset.cast({%{}, %{}}, %{}, []))}
  end

  def handle_event("validate-create", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("create", params, socket) do
    new_nominations_created =
      if params["changeset"]["new_nominations_created"] == ["1"] do
        "time"
      else
        "auction"
      end

    Auctions.create_auction(
      name: params["changeset"]["name"],
      year_range: params["changeset"]["year_and_league"],
      nominations_per_team: String.to_integer(params["changeset"]["nominations_per_team"]),
      seconds_before_autonomination:
        String.to_integer(params["changeset"]["seconds_before_autonomination"]),
      new_nominations_created: new_nominations_created,
      initial_bid_timeout_seconds:
        String.to_integer(params["changeset"]["initial_bid_timeout_seconds"]),
      bid_timeout_seconds: String.to_integer(params["changeset"]["bid_timeout_seconds"]),
      players_per_team: String.to_integer(params["changeset"]["players_per_team"]),
      must_roster_all_players: params["changeset"]["must_roster_all_players"] == ["1"],
      dollars_per_team: String.to_integer(params["changeset"]["dollars_per_team"])
    )

    {:noreply, socket}
  end
end
