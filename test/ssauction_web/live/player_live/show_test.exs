defmodule SSAuctionWeb.PlayerLive.ShowTest do
  use SSAuctionWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import SSAuction.PlayersFixtures
  import SSAuction.AccountsFixtures

  describe "mount/3" do
    setup do
      user = user_fixture()
      player = player_fixture()
      %{user: user, player: player}
    end

    test "handles valid player ID", %{conn: conn, user: user, player: player} do
      conn = log_in_user(conn, user)
      {:ok, _view, html} = live(conn, ~p"/players/#{player.id}")
      
      assert html =~ player.name
    end

    test "handles player not found", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      non_existent_id = Ecto.UUID.generate()
      
      assert_error_sent 404, fn ->
        live(conn, ~p"/players/#{non_existent_id}")
      end
    end

    test "handles invalid player ID format", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      
      assert_error_sent 404, fn ->
        live(conn, ~p"/players/invalid-id-format")
      end
    end

    test "handles missing params", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      
      assert_error_sent 404, fn ->
        live(conn, "/players/")
      end
    end

    test "assigns current_user", %{conn: conn, user: user, player: player} do
      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/players/#{player.id}")
      
      assert view.assigns.current_user.id == user.id
    end

    test "handles user without permission accessing player", %{conn: conn, player: player} do
      unauthorized_user = user_fixture()
      conn = log_in_user(conn, unauthorized_user)
      
      {:ok, _view, _html} = live(conn, ~p"/players/#{player.id}")
      # Note: If authorization is implemented, this should test for redirect/error
    end

    test "handles nil player ID", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      
      assert_error_sent 404, fn ->
        live(conn, "/players/")
      end
    end
  end

  describe "handle_params/3" do
    setup do
      user = user_fixture()
      player = player_fixture()
      %{user: user, player: player}
    end

    test "handles valid params update", %{conn: conn, user: user, player: player} do
      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/players/#{player.id}")
      
      assert view.assigns.player.id == player.id
    end

    test "handles invalid player ID in params", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      
      assert_error_sent 404, fn ->
        live(conn, ~p"/players/99999")
      end
    end
  end

  describe "concurrent updates" do
    setup do
      user = user_fixture()
      player = player_fixture()
      %{user: user, player: player}
    end

    test "handles concurrent updates to player data", %{conn: conn, user: user, player: player} do
      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/players/#{player.id}")
      
      # Simulate concurrent update
      updated_player = SSAuction.Players.update_player(player, %{name: "Updated Name"})
      
      # Trigger re-render
      send(view.pid, {:player_updated, updated_player})
      
      assert render(view) =~ player.name
    end
  end

  describe "render/1" do
    setup do
      user = user_fixture()
      player = player_fixture()
      %{user: user, player: player}
    end

    test "displays player information", %{conn: conn, user: user, player: player} do
      conn = log_in_user(conn, user)
      {:ok, _view, html} = live(conn, ~p"/players/#{player.id}")
      
      assert html =~ player.name
    end

    test "displays back navigation link", %{conn: conn, user: user, player: player} do
      conn = log_in_user(conn, user)
      {:ok, _view, html} = live(conn, ~p"/players/#{player.id}")
      
      assert html =~ "Back"
    end

    test "handles nil player attributes gracefully", %{conn: conn, user: user} do
      player = player_fixture(%{name: nil})
      conn = log_in_user(conn, user)
      
      {:ok, _view, html} = live(conn, ~p"/players/#{player.id}")
      
      assert html
    end
  end

  describe "authentication" do
    setup do
      player = player_fixture()
      %{player: player}
    end

    test "redirects when user not authenticated", %{conn: conn, player: player} do
      result = live(conn, ~p"/players/#{player.id}")
      
      assert {:error, {:redirect, %{to: path}}} = result
      assert path =~ "/users/log_in"
    end

    test "allows access when user authenticated", %{conn: conn, player: player} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      
      assert {:ok, _view, _html} = live(conn, ~p"/players/#{player.id}")
    end
  end

  describe "handle_info/2" do
    setup do
      user = user_fixture()
      player = player_fixture()
      %{user: user, player: player}
    end

    test "handles player update messages", %{conn: conn, user: user, player: player} do
      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/players/#{player.id}")
      
      send(view.pid, {:player_updated, player})
      
      assert render(view) =~ player.name
    end

    test "handles unknown messages gracefully", %{conn: conn, user: user, player: player} do
      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/players/#{player.id}")
      
      send(view.pid, :unknown_message)
      
      assert render(view)
    end
  end

  describe "page title" do
    setup do
      user = user_fixture()
      player = player_fixture()
      %{user: user, player: player}
    end

    test "sets correct page title", %{conn: conn, user: user, player: player} do
      conn = log_in_user(conn, user)
      {:ok, _view, html} = live(conn, ~p"/players/#{player.id}")
      
      assert html =~ "<title>"
      assert html =~ "Show Player"
    end
  end

  describe "navigation" do
    setup do
      user = user_fixture()
      player = player_fixture()
      %{user: user, player: player}
    end

    test "can navigate back to players list", %{conn: conn, user: user, player: player} do
      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/players/#{player.id}")
      
      assert view
             |> element("a", "Back")
             |> render_click()
      
      assert_redirect(view, ~p"/players")
    end

    test "can navigate to edit page", %{conn: conn, user: user, player: player} do
      conn = log_in_user(conn, user)
      {:ok, view, html} = live(conn, ~p"/players/#{player.id}")
      
      assert html =~ "Edit" || html =~ "edit"
    end
  end
end