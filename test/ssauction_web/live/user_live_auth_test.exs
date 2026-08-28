defmodule SSAuctionWeb.UserLiveAuthTest do
  use SSAuctionWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import SSAuction.AccountsFixtures

  alias SSAuction.Accounts

  defmodule TestLive do
    use Phoenix.LiveView

    on_mount SSAuctionWeb.UserLiveAuth

    def mount(_params, _session, socket) do
      {:ok, assign(socket, :page_title, "Test Page")}
    end

    def render(assigns) do
      ~H"""
      <div>
        <p>User ID: <%= @current_user.id %></p>
      </div>
      """
    end
  end

  setup %{conn: conn} do
    conn = 
      conn
      |> Map.replace!(:secret_key_base, SSAuctionWeb.Endpoint.config(:secret_key_base))
      |> init_test_session(%{})
    
    %{conn: conn}
  end

  describe "on_mount/4 with authenticated user" do
    setup %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      %{conn: conn, user: user}
    end

    test "assigns current_user to socket", %{conn: conn, user: user} do
      {:ok, _view, html} = live(conn, "/test")
      
      assert html =~ "User ID: #{user.id}"
    end

    test "handles valid session token", %{conn: conn, user: user} do
      assert {:cont, socket} = 
        SSAuctionWeb.UserLiveAuth.on_mount(:default, %{}, %{"user_token" => get_session(conn, :user_token)}, %Phoenix.LiveView.Socket{})
      
      assert socket.assigns.current_user.id == user.id
    end
  end

  describe "on_mount/4 with unauthenticated user" do
    test "redirects to login page", %{conn: conn} do
      result = live(conn, "/test")
      
      assert {:error, {:redirect, %{to: path}}} = result
      assert path == "/users/log_in"
    end

    test "handles missing user in session", %{conn: conn} do
      conn = put_session(conn, :user_token, "invalid_token")
      
      result = live(conn, "/test")
      
      assert {:error, {:redirect, %{to: path}}} = result
      assert path == "/users/log_in"
    end

    test "handles nil session token", %{conn: conn} do
      socket = %Phoenix.LiveView.Socket{
        endpoint: SSAuctionWeb.Endpoint,
        router: SSAuctionWeb.Router
      }
      
      assert {:halt, socket} = 
        SSAuctionWeb.UserLiveAuth.on_mount(:default, %{}, %{}, socket)
      
      assert socket.redirected == {:redirect, %{to: "/users/log_in"}}
    end

    test "handles empty session", %{conn: conn} do
      socket = %Phoenix.LiveView.Socket{
        endpoint: SSAuctionWeb.Endpoint,
        router: SSAuctionWeb.Router
      }
      
      assert {:halt, socket} = 
        SSAuctionWeb.UserLiveAuth.on_mount(:default, %{}, %{}, socket)
      
      refute Map.has_key?(socket.assigns, :current_user)
    end
  end

  describe "on_mount/4 with expired session tokens" do
    test "redirects when token is expired", %{conn: conn} do
      user = user_fixture()
      token = Accounts.generate_user_session_token(user)
      
      # Simulate expired token by deleting it from database
      Accounts.delete_user_session_token(token)
      
      conn = put_session(conn, :user_token, token)
      
      result = live(conn, "/test")
      
      assert {:error, {:redirect, %{to: path}}} = result
      assert path == "/users/log_in"
    end

    test "handles invalid token format", %{conn: conn} do
      conn = put_session(conn, :user_token, "completely_invalid_token_format")
      
      result = live(conn, "/test")
      
      assert {:error, {:redirect, %{to: path}}} = result
      assert path == "/users/log_in"
    end
  end

  describe "on_mount/4 with concurrent session invalidation" do
    setup %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      %{conn: conn, user: user}
    end

    test "handles session deleted during request", %{conn: conn, user: user} do
      token = get_session(conn, :user_token)
      
      # Delete all user sessions
      Accounts.delete_user_session_token(token)
      
      result = live(conn, "/test")
      
      assert {:error, {:redirect, %{to: path}}} = result
      assert path == "/users/log_in"
    end

    test "handles user deleted during session", %{conn: conn, user: user} do
      # Delete the user
      Accounts.delete_user(user)
      
      result = live(conn, "/test")
      
      assert {:error, {:redirect, %{to: path}}} = result
      assert path == "/users/log_in"
    end
  end

  describe "on_mount/4 authorization bypass attempts" do
    test "rejects tampered session token", %{conn: conn} do
      user = user_fixture()
      token = Accounts.generate_user_session_token(user)
      
      # Tamper with token
      tampered_token = token <> "tampered"
      
      conn = put_session(conn, :user_token, tampered_token)
      
      result = live(conn, "/test")
      
      assert {:error, {:redirect, %{to: path}}} = result
      assert path == "/users/log_in"
    end

    test "rejects token for different user", %{conn: conn} do
      user1 = user_fixture()
      user2 = user_fixture()
      
      token = Accounts.generate_user_session_token(user1)
      
      # Try to use user1's token but expect user2
      conn = put_session(conn, :user_token, token)
      
      {:ok, _view, html} = live(conn, "/test")
      
      # Should authenticate as user1, not user2
      assert html =~ "User ID: #{user1.id}"
      refute html =~ "User ID: #{user2.id}"
    end

    test "handles malformed session data", %{conn: conn} do
      conn = put_session(conn, :user_token, %{invalid: "data"})
      
      result = live(conn, "/test")
      
      assert {:error, {:redirect, %{to: path}}} = result
      assert path == "/users/log_in"
    end

    test "rejects empty string token", %{conn: conn} do
      conn = put_session(conn, :user_token, "")
      
      result = live(conn, "/test")
      
      assert {:error, {:redirect, %{to: path}}} = result
      assert path == "/users/log_in"
    end

    test "rejects binary token with invalid encoding", %{conn: conn} do
      conn = put_session(conn, :user_token, <<0, 1, 2, 3>>)
      
      result = live(conn, "/test")
      
      assert {:error, {:redirect, %{to: path}}} = result
      assert path == "/users/log_in"
    end
  end

  describe "on_mount/4 flash messages" do
    test "sets error flash on redirect for unauthenticated access", %{conn: conn} do
      socket = %Phoenix.LiveView.Socket{
        endpoint: SSAuctionWeb.Endpoint,
        router: SSAuctionWeb.Router
      }
      
      assert {:halt, socket} = 
        SSAuctionWeb.UserLiveAuth.on_mount(:default, %{}, %{}, socket)
      
      assert Phoenix.Flash.get(socket.assigns.flash, :error) == "You must log in to access this page."
    end
  end

  defp log_in_user(conn, user) do
    token = Accounts.generate_user_session_token(user)
    put_session(conn, :user_token, token)
  end
end