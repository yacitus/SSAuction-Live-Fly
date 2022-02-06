defmodule SSAuctionWeb.FormattedTimeComponent do
  use SSAuctionWeb, :live_component

  alias SSAuction.Cldr

  def render(assigns) do
    ~H"""
      <%= cond do
            is_nil(@utc_datetime) ->
              ""
            connected?(@socket) ->
              Cldr.format_time(@utc_datetime,
                               locale: @locale,
                               timezone: @timezone)
            true ->
              Cldr.format_time(@utc_datetime)
          end
      %>
    """
  end
end
