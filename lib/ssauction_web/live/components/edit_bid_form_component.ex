defmodule SSAuctionWeb.EditBidFormComponent do
  use SSAuctionWeb, :live_component

  def mount(socket) do
     socket =
      socket
      |> assign(:changeset, Ecto.Changeset.cast({%{}, %{}}, %{}, []))

   {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      <.form let={f} for={@changeset} as={:changeset} id="edit-bid-form" phx-submit="submit-edited-bid" phx-change="validate-edited-bid"
          class="bg-slate-200 px-10 py-8 mb-6 shadow rounded-lg px-6 mt-8 mx-auto w-full max-w-md">

        <%= if @different_team do %>
          <div class="block mb-2 text-sm font-medium text-slate-700">
            <%= label f, :bid, "Bid"%>
          </div>
          <%= number_input f, :bid_amount, value: @bid_for_edit.bid_amount + 1 %>

          <div class="block mb-2 text-sm font-medium text-slate-700">
            <%= label f, :bid, "Hidden Max Bid"%>
          </div>
          <%= number_input f, :hidden_high_bid %>

          <div class="block mb-2 text-sm font-medium text-slate-700">
            <%= label f, :bid, "Keep Bidding Up To"%>
          </div>
          <%= number_input f, :keep_bidding_up_to%>
        <% else %>
          <div class="block mb-2 text-sm font-medium text-slate-700">
            <%= label f, :bid, "Bid"%>
          </div>
          <%= number_input f, :bid_amount, value: @bid_for_edit.bid_amount, disabled: true %>

          <div class="block mb-2 text-sm font-medium text-slate-700">
            <%= label f, :bid, "Hidden Max Bid"%>
          </div>
          <%= number_input f, :hidden_high_bid, value: @bid_for_edit.hidden_high_bid %>
        <% end %>

        <button form="edit-bid-form" type="submit"
          class="mt-2 w-full py-2 px-4 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 transition duration-150 ease-in-out
                  active:bg-indigo-700
                  hover:bg-indigo-500
                  focus:outline-none focus:border-indigo-700 focus:ring focus:ring-indigo-300">
          <%= if @different_team do %>
            Bid
          <% else %>
            Change
          <% end %>
        </button>
      </.form>
    </div>
    """
  end
end
