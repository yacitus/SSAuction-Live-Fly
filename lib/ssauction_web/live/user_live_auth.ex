defmodule SSAuctionWeb.UserLiveAuth do
  import Phoenix.LiveView

  alias SSAuction.Accounts

  def on_mount(:default, _params, %{"user_token" => user_token} = _session, socket) do
    socket =
      assign_new(socket, :current_user, fn ->
        Accounts.get_user_by_session_token(user_token)
      end)

    IO.inspect(socket.assigns.current_user)

    if socket.assigns.current_user.confirmed_at do
      {:cont, socket}
    else
      socket =
        put_flash(socket, :error, "Your email has not been confirmed.")

      {:halt, redirect(socket, to: "/users/log_in")}
    end
  end
end
