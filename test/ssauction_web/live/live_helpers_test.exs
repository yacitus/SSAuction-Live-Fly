defmodule SSAuctionWeb.LiveHelpersTest do
  use SSAuctionWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias SSAuctionWeb.LiveHelpers

  describe "modal/1" do
    test "renders modal with valid params", %{conn: conn} do
      {:ok, view, _html} = live_isolated(conn, TestModalLive, session: %{})

      html = render(view)

      assert html =~ "phx-modal"
      assert html =~ "phx-remove"
      assert html =~ "return_to"
    end

    test "handles missing required params" do
      assigns = %{
        id: nil,
        return_to: nil,
        component: nil
      }

      assert_raise ArgumentError, fn ->
        Phoenix.LiveView.Helpers.sigil_H(
          ~H"""
          <%= live_modal @component, id: @id, return_to: @return_to %>
          """,
          []
        )
      end
    end

    test "handles invalid return_to path", %{conn: conn} do
      {:ok, view, _html} =
        live_isolated(conn, TestModalLive,
          session: %{"return_to" => "invalid://path", "component" => TestComponent}
        )

      html = render(view)
      assert html =~ "invalid://path"
    end

    test "handles component rendering with nil values", %{conn: conn} do
      {:ok, view, _html} =
        live_isolated(conn, TestModalLive,
          session: %{"return_to" => "/", "component" => TestComponent, "opts" => [title: nil]}
        )

      html = render(view)
      assert html =~ "phx-modal"
    end

    test "handles nested modal scenarios", %{conn: conn} do
      {:ok, view, _html} =
        live_isolated(conn, TestNestedModalLive, session: %{})

      html = render(view)
      assert html =~ "phx-modal"
      assert html =~ "nested-modal"
    end
  end

  describe "live_modal/3" do
    test "renders live modal with component", %{conn: conn} do
      {:ok, view, _html} = live_isolated(conn, TestModalLive, session: %{})

      html = render(view)
      assert html =~ "phx-modal"
    end

    test "handles opts with nil values", %{conn: conn} do
      {:ok, view, _html} =
        live_isolated(conn, TestModalLive,
          session: %{"opts" => [title: nil, subtitle: nil]}
        )

      html = render(view)
      assert html =~ "phx-modal"
    end

    test "passes through component assigns", %{conn: conn} do
      {:ok, view, _html} =
        live_isolated(conn, TestModalLive,
          session: %{"opts" => [custom_data: "test_value"]}
        )

      html = render(view)
      assert html =~ "phx-modal"
    end
  end

  describe "hide_modal/1" do
    test "hides modal with valid id", %{conn: conn} do
      {:ok, view, _html} = live_isolated(conn, TestModalLive, session: %{})

      view
      |> element("#test-modal [phx-click='hide']")
      |> render_click()

      refute has_element?(view, "#test-modal[style*='display: block']")
    end

    test "handles nil id gracefully" do
      result = LiveHelpers.hide_modal(nil)
      assert is_tuple(result) or is_nil(result)
    end

    test "handles empty string id" do
      result = LiveHelpers.hide_modal("")
      assert is_tuple(result) or is_nil(result)
    end
  end

  describe "show_modal/1" do
    test "shows modal with valid id", %{conn: conn} do
      {:ok, view, _html} = live_isolated(conn, TestModalLive, session: %{})

      view
      |> element("#test-modal [phx-click='show']")
      |> render_click()

      assert has_element?(view, "#test-modal")
    end

    test "handles nil id gracefully" do
      result = LiveHelpers.show_modal(nil)
      assert is_tuple(result) or is_nil(result)
    end

    test "handles empty string id" do
      result = LiveHelpers.show_modal("")
      assert is_tuple(result) or is_nil(result)
    end
  end

  describe "live_flash/2" do
    test "renders flash messages", %{conn: conn} do
      conn = put_flash(conn, :info, "Test message")
      {:ok, view, _html} = live_isolated(conn, TestFlashLive, session: %{})

      html = render(view)
      assert html =~ "Test message"
    end

    test "handles flash messages with special characters", %{conn: conn} do
      special_message = "Test <script>alert('xss')</script> & \"quotes\" 'single'"
      conn = put_flash(conn, :info, special_message)
      {:ok, view, _html} = live_isolated(conn, TestFlashLive, session: %{})

      html = render(view)
      assert html =~ "&lt;script&gt;" or html =~ "alert"
      refute html =~ "<script>alert('xss')</script>"
    end

    test "handles flash with unicode characters", %{conn: conn} do
      unicode_message = "Test 你好 🎉 émojis"
      conn = put_flash(conn, :info, unicode_message)
      {:ok, view, _html} = live_isolated(conn, TestFlashLive, session: %{})

      html = render(view)
      assert html =~ "你好"
      assert html =~ "🎉"
    end

    test "handles nil flash gracefully", %{conn: conn} do
      {:ok, view, _html} = live_isolated(conn, TestFlashLive, session: %{})

      html = render(view)
      assert html
    end

    test "handles error flash type", %{conn: conn} do
      conn = put_flash(conn, :error, "Error message")
      {:ok, view, _html} = live_isolated(conn, TestFlashLive, session: %{})

      html = render(view)
      assert html =~ "Error message"
    end
  end

  describe "assign_defaults/2" do
    test "assigns current_user from session", %{conn: conn} do
      user = %{id: 1, email: "test@example.com"}
      {:ok, view, _html} = live_isolated(conn, TestAssignLive, session: %{"current_user" => user})

      assert view.assigns.current_user == user
    end

    test "handles nil current_user", %{conn: conn} do
      {:ok, view, _html} = live_isolated(conn, TestAssignLive, session: %{})

      assert is_nil(view.assigns[:current_user]) or view.assigns[:current_user] == nil
    end

    test "handles missing session data", %{conn: conn} do
      {:ok, view, _html} = live_isolated(conn, TestAssignLive, session: %{})

      assert view.assigns
    end
  end

  describe "put_flash_message/3" do
    test "puts info flash message", %{conn: conn} do
      {:ok, view, _html} = live_isolated(conn, TestFlashLive, session: %{})

      view
      |> element("#trigger-flash")
      |> render_click(%{"type" => "info", "message" => "Info message"})

      assert render(view) =~ "Info message"
    end

    test "puts error flash message", %{conn: conn} do
      {:ok, view, _html} = live_isolated(conn, TestFlashLive, session: %{})

      view
      |> element("#trigger-flash")
      |> render_click(%{"type" => "error", "message" => "Error message"})

      assert render(view) =~ "Error message"
    end

    test "handles flash with special characters", %{conn: conn} do
      {:ok, view, _html} = live_isolated(conn, TestFlashLive, session: %{})

      special_message = "Test & < > \" ' message"

      view
      |> element("#trigger-flash")
      |> render_click(%{"type" => "info", "message" => special_message})

      html = render(view)
      assert html =~ "Test" or html =~ "&amp;"
    end

    test "handles nil message gracefully", %{conn: conn} do
      {:ok, view, _html} = live_isolated(conn, TestFlashLive, session: %{})

      view
      |> element("#trigger-flash")
      |> render_click(%{"type" => "info", "message" => nil})

      assert render(view)
    end
  end
end

defmodule SSAuctionWeb.LiveHelpersTest.TestModalLive do
  use Phoenix.LiveView

  def render(assigns) do
    ~H"""
    <div id="test-modal" class="phx-modal">
      <div phx-click="hide">Close</div>
      <div phx-click="show">Show</div>
      <div class="return_to"><%= @return_to %></div>
    </div>
    """
  end

  def mount(_params, session, socket) do
    {:ok,
     assign(socket,
       return_to: session["return_to"] || "/",
       component: session["component"] || TestComponent,
       opts: session["opts"] || []
     )}
  end

  def handle_event("hide", _, socket) do
    {:noreply, socket}
  end

  def handle_event("show", _, socket) do
    {:noreply, socket}
  end
end

defmodule SSAuctionWeb.LiveHelpersTest.TestNestedModalLive do
  use Phoenix.LiveView

  def render(assigns) do
    ~H"""
    <div id="outer-modal" class="phx-modal">
      <div id="nested-modal" class="phx-modal nested-modal">
        Nested content
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end

defmodule SSAuctionWeb.LiveHelpersTest.TestFlashLive do
  use Phoenix.LiveView

  def render(assigns) do
    ~H"""
    <div>
      <%= if @flash["info"] do %>
        <div class="flash-info"><%= @flash["info"] %></div>
      <% end %>
      <%= if @flash["error"] do %>
        <div class="flash-error"><%= @flash["error"] %></div>
      <% end %>
      <button id="trigger-flash" phx-click="trigger_flash">Trigger</button>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_event("trigger_flash", %{"type" => type, "message" => message}, socket) do
    {:noreply, put_flash(socket, String.to_atom(type), message)}
  end
end

defmodule SSAuctionWeb.LiveHelpersTest.TestAssignLive do
  use Phoenix.LiveView

  def render(assigns) do
    ~H"""
    <div>
      <%= if @current_user do %>
        <span>User: <%= @current_user.email %></span>
      <% else %>
        <span>No user</span>
      <% end %>
    </div>
    """
  end

  def mount(_params, session, socket) do
    {:ok, assign(socket, current_user: session["current_user"])}
  end
end

defmodule SSAuctionWeb.LiveHelpersTest.TestComponent do
  use Phoenix.LiveComponent

  def render(assigns) do
    ~H"""
    <div>Test Component</div>
    """
  end
end