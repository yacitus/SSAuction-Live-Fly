defmodule SSAuctionWeb.AdminLive.ImportPlayers do
  use SSAuctionWeb, :live_view

  alias SSAuction.Players
  alias SSAuctionWeb.AdminLive.AllPlayers

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:changeset, Ecto.Changeset.cast({%{}, %{}}, %{}, []))
     |> assign(:uploaded_files, [])
     |> assign(:players_for_import, [])
     |> allow_upload(:csv, accept: ~w(.csv), max_entries: 1)}
  end

  def handle_event("validate-upload", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("upload", _params, socket) do
    [uploaded] =
      consume_uploaded_entries(socket, :csv, fn %{path: path}, _entry ->
        {:ok, players_from_csv(path)}
      end)
    {:noreply, assign(socket, :players_for_import, uploaded)}
  end

  def handle_event("validate-import", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("import", params, socket) do
    year_and_league = params["changeset"]["year_and_league"]

    if params["changeset"]["replace"] == "true" do
      Players.delete_all_players(year_and_league)
    end

    Enum.map(socket.assigns[:players_for_import],
             fn row -> row
                       |> Map.put(:year_range, year_and_league)
                       |> Players.create_all_player! end)

    {:noreply, redirect(socket, to: Routes.live_path(socket, AllPlayers, year_and_league: year_and_league))}
  end

  defp players_from_csv(csv_filepath) do
    columns = [:ssnum, :name, :position]

    csv_filepath
    |> File.read!()
    |> String.split("\n", trim: true)
    |> Enum.map(&String.split(&1, ",", trim: true))
    |> Enum.map(fn row -> columns |> Enum.zip(row) |> Map.new() end)
    |> Enum.map(fn row -> Map.update!(row, :ssnum, &String.to_integer/1) end)
    |> Enum.map(fn row -> Map.update!(row, :position, &String.trim/1) end)
  end
end
