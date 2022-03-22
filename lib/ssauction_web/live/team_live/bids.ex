defmodule SSAuctionWeb.TeamLive.Bids do
  use SSAuctionWeb, :live_view

  alias SSAuction.Accounts
  alias SSAuction.Teams
  alias SSAuction.Teams.Team
  alias SSAuction.Auctions
  alias SSAuction.Auctions.Auction
  alias SSAuction.Bids
  alias SSAuction.Bids.Bid

  @impl true
  def mount(_params, session, socket) do
    if connected?(socket) do
      Bids.subscribe()
      Auctions.subscribe()
      Teams.subscribe()
    end

    current_user =
      if Map.has_key?(session, "user_token") do
        Accounts.get_user_by_session_token(session["user_token"])
      else
        nil
      end

    socket =
      socket
        |> assign_locale()
        |> assign_timezone()
        |> assign_timezone_offset()
        |> assign(:current_user, current_user)
        |> assign(:show_modal, false)

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    team = Teams.get_team!(id)
    auction = Auctions.get_auction!(team.auction_id)
    {:noreply,
     socket
       |> assign(:team, team)
       |> assign(:auction, auction)
       |> assign(:bids, Bids.list_bids_with_expires_in(team))
       |> assign(:show_modal, false)
       |> assign(:links, [%{label: "#{auction.name} auction", to: "/auction/#{auction.id}"},
                          %{label: "#{team.name}", to: "/team/#{id}"}])
    }
  end

  @impl true
  def handle_event("bid-log", %{"id" => id}, socket) do
    bid = Bids.get_bid_with_team_and_player!(id)
    {:noreply, redirect(socket, to: Routes.player_show_path(socket, :show, bid.player.id, back_to: "team"))}
  end

  @impl true
  def handle_event("edit", %{"id" => id}, socket) do
    bid_for_edit = Bids.get_bid_with_team_and_player!(id)

    {:noreply,
     socket
       |> assign(:bid_for_edit, bid_for_edit)
       |> assign(:show_modal, true)
    }
  end

  @impl true
  def handle_event("validate-edited-bid", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("submit-edited-bid", params, socket) do
    with {:ok, _} <- Bids.validate_edited_bid(socket.assigns.auction,
                                              socket.assigns.team,
                                              socket.assigns.bid_for_edit,
                                              params["changeset"]["bid_amount"],
                                              params["changeset"]["hidden_high_bid"],
                                              nil),
         {:ok, _} <- Bids.submit_edited_bid(socket.assigns.auction,
                                            socket.assigns.team,
                                            socket.assigns.bid_for_edit,
                                            params["changeset"]["bid_amount"],
                                            params["changeset"]["hidden_high_bid"],
                                            nil) do
      {:noreply, push_patch_to_live_path(socket)}
    else
      {_, message} ->
        {:noreply, put_flash(socket, :error, message)}
    end
  end

  @impl true
  def handle_event("close", _, socket) do
    {:noreply, push_patch_to_live_path(socket)}
  end

  @impl true
  def handle_info({:new_nomination, bid = %Bid{}}, socket) do
    socket =
      if bid.team_id == socket.assigns.team.id do
        assign(socket, :bids, Bids.list_bids_with_expires_in(socket.assigns.team))
      else
        socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_info({:bid_expiration_update, auction = %Auction{}}, socket) do
    socket =
      if auction.id == socket.assigns.auction.id do
        assign(socket, :bids, Bids.list_bids_with_expires_in(socket.assigns.team))
      else
        socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_info({:bid_change, team = %Team{}}, socket) do
    socket =
      if team.id == socket.assigns.team.id do
        assign(socket, :bids, Bids.list_bids_with_expires_in(team))
      else
        socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_info({_, _}, socket) do
    {:noreply, socket} # ignore
  end

  defp current_user_in_team?(team, current_user) do
    current_user != nil and Teams.user_in_team?(team, current_user)
  end

  defp push_patch_to_live_path(socket) do
    push_patch(socket,
      to:
        Routes.live_path(
          socket,
          __MODULE__,
          socket.assigns.team.id)
    )
  end
end
