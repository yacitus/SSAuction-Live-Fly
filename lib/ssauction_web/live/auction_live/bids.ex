defmodule SSAuctionWeb.AuctionLive.Bids do
  use SSAuctionWeb, :live_view

  alias SSAuction.Accounts
  alias SSAuction.Auctions
  alias SSAuction.Auctions.Auction
  alias SSAuction.Bids
  alias SSAuction.Bids.Bid
  alias SSAuction.Teams

  @impl true
  def mount(_params, session, socket) do
    if connected?(socket) do
      Bids.subscribe()
      Auctions.subscribe()
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
  def handle_params(params, _, socket) do
    auction = Auctions.get_auction!(params["id"])

    sort_by = (params["sort_by"] || "expires_at") |> String.to_atom()
    sort_order = (params["sort_order"] || "asc") |> String.to_atom()
    sort_options = %{sort_by: sort_by, sort_order: sort_order}

    {:noreply,
     socket
       |> assign(:auction, auction)
       |> assign(:bids, Bids.list_bids_with_expires_in(auction, sort_options))
       |> assign(:show_modal, false)
       |> assign(:options, sort_options)
       |> assign(:links, [%{label: "#{auction.name} auction", to: "/auction/#{auction.id}"}])
    }
  end

  @impl true
  def handle_event("bid-log", %{"id" => id}, socket) do
    bid = Bids.get_bid_with_team_and_player!(id)
    {:noreply, redirect(socket, to: Routes.player_show_path(socket, :show, bid.player.id))}
  end

  @impl true
  def handle_event("edit", %{"id" => id}, socket) do
    bid_for_edit = Bids.get_bid_with_team_and_player!(id)

    {:noreply,
     socket
       |> assign(:bid_for_edit, bid_for_edit)
       |> assign(:different_team, false)
       |> assign(:show_modal, true)
    }
  end

  @impl true
  def handle_event("bid", %{"id" => id}, socket) do
    bid_for_new_bid = Bids.get_bid_with_team_and_player!(id)

    {:noreply,
     socket
       |> assign(:bid_for_edit, bid_for_new_bid)
       |> assign(:different_team, true)
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
                                              Teams.get_team_by_user_and_auction(socket.assigns.current_user, socket.assigns.auction),
                                              socket.assigns.bid_for_edit,
                                              params["changeset"]["bid_amount"],
                                              params["changeset"]["hidden_high_bid"],
                                              params["changeset"]["keep_bidding_up_to"]),
         {:ok, _} <- Bids.submit_edited_bid(socket.assigns.auction,
                                            Teams.get_team_by_user_and_auction(socket.assigns.current_user, socket.assigns.auction),
                                            socket.assigns.bid_for_edit,
                                            params["changeset"]["bid_amount"],
                                            params["changeset"]["hidden_high_bid"],
                                            params["changeset"]["keep_bidding_up_to"]) do
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
      if bid.auction_id == socket.assigns.auction.id do
        assign(socket, :bids, Bids.list_bids_with_expires_in(socket.assigns.auction))
      else
        socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_info({:bid_expiration_update, auction = %Auction{}}, socket) do
    socket =
      if auction.id == socket.assigns.auction.id do
        assign(socket, :bids, Bids.list_bids_with_expires_in(socket.assigns.auction))
      else
        socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_info({:bid_change, auction = %Auction{}}, socket) do
    socket =
      if auction.id == socket.assigns.auction.id do
        assign(socket, :bids, Bids.list_bids_with_expires_in(socket.assigns.auction))
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

  defp current_user_in_auction?(auction, current_user) do
    current_user != nil and Auctions.user_in_auction?(auction, current_user)
  end

  defp push_patch_to_live_path(socket) do
    push_patch(socket,
      to:
        Routes.live_path(
          socket,
          __MODULE__,
          socket.assigns.auction.id)
    )
  end

  defp sort_link(socket, text, sort_by, auction_id, options) do
    text =
      if sort_by == options.sort_by do
        text <> emoji(options.sort_order)
      else
        text
      end

    live_patch(text,
      to:
        Routes.live_path(
          socket,
          __MODULE__,
          auction_id,
          sort_by: sort_by,
          sort_order: toggle_sort_order(options.sort_order)
        )
    )
  end

  defp toggle_sort_order(:asc), do: :desc
  defp toggle_sort_order(:desc), do: :asc

  defp emoji(:asc), do: " ⬇️"
  defp emoji(:desc), do: " ⬆️"
end
