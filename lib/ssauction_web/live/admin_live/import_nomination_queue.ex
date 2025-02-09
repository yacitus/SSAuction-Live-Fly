defmodule SSAuctionWeb.AdminLive.ImportNominationQueue do
  use SSAuctionWeb, :live_view

  import Ecto.Query, warn: false

  alias SSAuction.Auctions
  alias SSAuction.Players.Player
  alias SSAuction.Players.OrderedPlayer
  alias SSAuction.Repo
  alias SSAuctionWeb.AuctionLive.AutoNominationQueue

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:changeset, Ecto.Changeset.cast({%{}, %{}}, %{}, []))
     |> assign(:uploaded_files, [])
     |> assign(:players_for_import, [])
     |> allow_upload(:csv, accept: ~w(.csv), max_entries: 1)}
  end

  def handle_params(%{"id" => id}, _, socket) do
    auction = Auctions.get_auction!(id)
    {:noreply, assign(socket, :auction, auction)}
  end

  def handle_event("validate-upload", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("upload", _params, socket) do
    [uploaded] =
      consume_uploaded_entries(socket, :csv, fn %{path: path}, _entry ->
        {:ok, players_from_csv(path, socket.assigns.auction)}
      end)

    {:noreply, assign(socket, :players_for_import, uploaded)}
  end

  def handle_event("validate-import", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("import", params, socket) do
    if params["changeset"]["replace"] == "true" do
      Auctions.remove_all_players_in_nomination_queue(socket.assigns.auction)
    end

    Enum.with_index(socket.assigns.players_for_import, 1)
    |> Enum.map(fn {player, i} -> %OrderedPlayer{rank: i, player: player} end)
    |> Enum.map(fn ordered_player ->
      Ecto.build_assoc(socket.assigns.auction, :ordered_players, ordered_player)
    end)
    |> Enum.map(fn ordered_player -> Repo.insert!(ordered_player, on_conflict: :nothing) end)

    {:noreply,
     redirect(socket,
       to: Routes.live_path(socket, AutoNominationQueue, socket.assigns.auction.id)
     )}
  end

  defp players_from_csv(csv_filepath, auction) do
    columns = [:ssnum, :the_rest]

    csv_filepath
    |> File.read!()
    |> String.split("\n", trim: true)
    |> Enum.map(&String.split(&1, ",", trim: true, parts: 2))
    |> Enum.map(fn row -> columns |> Enum.zip(row) |> Map.new() end)
    |> Enum.map(fn row -> Map.update!(row, :ssnum, &String.to_integer/1) end)
    |> Enum.map(fn row ->
      Repo.one!(
        from player in Player,
          where: player.auction_id == ^auction.id and player.ssnum == ^row.ssnum,
          select: player
      )
    end)
  end
end
