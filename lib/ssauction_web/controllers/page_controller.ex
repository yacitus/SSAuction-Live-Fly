defmodule SSAuctionWeb.PageController do
  use SSAuctionWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
