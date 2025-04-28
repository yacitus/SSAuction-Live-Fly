defmodule SSAuctionWeb.PlayerLive.Show do
  use SSAuctionWeb, :live_view

  alias SSAuction.Accounts
  alias SSAuction.Players
  alias SSAuction.Auctions
  alias SSAuction.Teams
  alias SSAuction.Bids
  alias SSAuction.Repo

  @impl true
  def mount(_params, session, socket) do
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
      |> assign(:changeset, Ecto.Changeset.cast({%{}, %{}}, %{}, []))

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _, socket) do
    id = params["id"]
    player = Players.get_player!(id)
    rostered_player =
      if player.rostered_player_id == nil do
        nil
      else
        Repo.preload(player, :rostered_player).rostered_player |> Repo.preload(:team)
      end
    bid =
      if player.bid_id == nil do
        nil
      else
        Bids.get_bid_with_team_and_player!(player.bid_id)
      end
    auction = Auctions.get_auction!(player.auction_id)
    back_to = params["back_to"] || "auction"
    links =
      cond do
        String.starts_with?(back_to, "nomination_queue-") ->
          "nomination_queue-" <> team_id = back_to
          team = Teams.get_team!(String.to_integer(team_id))
          [%{label: "#{auction.name} auction", to: "/auction/#{auction.id}"},
           %{label: "#{team.name}", to: "/team/#{team.id}"},
           %{label: "nomination queue", to: "/team/#{team.id}/nomination_queue"}]
        player.rostered_player_id != nil and back_to == "team" ->
          [%{label: "#{auction.name} auction", to: "/auction/#{auction.id}"},
           %{label: "#{rostered_player.team.name}", to: "/team/#{rostered_player.team.id}"},
           %{label: "rostered players", to: "/team/#{rostered_player.team.id}/rostered_players"}]
        player.rostered_player_id != nil and back_to == "auction" ->
          [%{label: "#{auction.name} auction", to: "/auction/#{auction.id}"},
           %{label: "rostered players", to: "/auction/#{auction.id}/rostered_players"}]
        back_to == "team" ->
          team = ((Players.get_player!(id) |> Repo.preload(:bid)).bid |> Repo.preload(:team)).team
          [%{label: "#{auction.name} auction", to: "/auction/#{auction.id}"},
           %{label: "#{team.name}", to: "/team/#{team.id}"},
           %{label: "bids", to: "/team/#{team.id}/bids"}]
        true ->
          [%{label: "#{auction.name} auction", to: "/auction/#{auction.id}"},
           %{label: "bids", to: "/auction/#{auction.id}/bids"}]
      end

    current_team =
      if socket.assigns.current_user != nil do
        Teams.get_team_by_user_and_auction(socket.assigns.current_user, auction)
      else
        nil
      end

    current_value =
      if socket.assigns.current_user != nil do
        Players.get_value(player, current_team)
      else
        nil
      end

    {show_modal, bid_for_edit, different_team} = if params["bid"] do
      {
       true,
       bid,
       bid.team_id != current_team.id
      }
    else
      {false, nil, nil}
    end

    {:noreply,
     socket
       |> assign(:auction, auction)
       |> assign(:player, player)
       |> assign(:rostered_player, rostered_player)
       |> assign(:bid, bid)
       |> assign(:bid_logs, Bids.list_bid_logs(player))
       |> assign(:links, links)
       |> assign(:current_team, current_team)
       |> assign(:current_value, current_value)
       |> assign(:show_modal, show_modal)
       |> assign(:bid_for_edit, bid_for_edit)
       |> assign(:different_team, different_team)
       |> assign(:back_to, back_to)
    }
  end

  @impl true
  def handle_event("validate-change", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("change", params, socket) do
    new_value = String.to_integer(params["changeset"]["value"])

    {:ok, current_value} =
      if socket.assigns.current_value != nil do
        Players.update_value(socket.assigns.current_value, %{value: new_value})
      else
        Players.create_value(socket.assigns.player, socket.assigns.current_team, new_value)
      end

    {:noreply, assign(socket, :current_value, current_value)}
  end

  @impl true
  def handle_event("close", _, socket) do
    IO.inspect(socket)
    {:noreply, push_patch_to_live_path(socket, socket.assigns.back_to)}
  end

  @impl true
  def handle_event("bid", _, socket) do
    {:noreply, push_patch_to_live_path_bid(socket, socket.assigns.back_to)}
  end

  @impl true
  def handle_event("validate-edited-bid", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("submit-edited-bid", params, socket) do
    team = Teams.get_team_by_user_and_auction(socket.assigns.current_user, socket.assigns.auction)
    if team.id == socket.assigns.bid_for_edit.team_id do
        with {:ok, _} <- Bids.validate_edited_bid(socket.assigns.bid_for_edit,
                                                  socket.assigns.auction.id,
                                                  team.id,
                                                  params["changeset"]["hidden_high_bid"]),
             {:ok, _} <- Bids.submit_edited_bid(socket.assigns.auction,
                                                team,
                                                socket.assigns.bid_for_edit,
                                                params["changeset"]["bid_amount"],
                                                params["changeset"]["hidden_high_bid"],
                                                params["changeset"]["keep_bidding_up_to"]) do
          {:noreply, push_patch_to_live_path(socket, socket.assigns.back_to)}
        else
          {_, message} ->
            {:noreply, put_flash(socket, :error, message)}
        end
    else
        with {:ok, _} <- Bids.validate_new_bid(socket.assigns.auction.id,
                                               team.id,
                                               socket.assigns.bid_for_edit.player.id,
                                               params["changeset"]["bid_amount"],
                                               params["changeset"]["hidden_high_bid"],
                                               params["changeset"]["keep_bidding_up_to"]),
             {:ok, _} <- Bids.submit_edited_bid(socket.assigns.auction,
                                                team,
                                                socket.assigns.bid_for_edit,
                                                params["changeset"]["bid_amount"],
                                                params["changeset"]["hidden_high_bid"],
                                                params["changeset"]["keep_bidding_up_to"]) do
          {:noreply, push_patch_to_live_path(socket, socket.assigns.back_to)}
        else
          {_, message} ->
            {:noreply, put_flash(socket, :error, message)}
        end
    end
  end

  defp get_current_value(value_struct) do
    if value_struct != nil, do: value_struct.value, else: 0
  end

  defp push_patch_to_live_path(socket, back_to) do
    push_patch(socket,
      to:
        Routes.player_show_path(
          socket,
          :show,
          socket.assigns.player.id,
          back_to: back_to
        )
    )
  end

  # TODO - merge this with the above
  defp push_patch_to_live_path_bid(socket, back_to) do
    push_patch(socket,
      to:
        Routes.player_show_path(
          socket,
          :show,
          socket.assigns.player.id,
          bid: nil,
          back_to: back_to
        )
    )
  end
end
