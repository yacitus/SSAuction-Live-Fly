defmodule SSAuctionWeb.NominateFormComponent do
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
      <.form let={f} for={@changeset} as={:changeset} id="nominate-form" phx-submit="submit-nominatation" phx-change="validate-nominatation"
          class="bg-slate-200 px-10 py-8 mb-6 shadow rounded-lg px-6 mt-8 mx-auto w-full max-w-md">

        <div class="block mb-2 text-sm font-medium text-slate-700">
          <%= label f, :bid, "Bid"%>
        </div>
        <%= number_input f, :bid_amount, value: 1 %>

        <div class="block mb-2 text-sm font-medium text-slate-700">
          <%= label f, :bid, "Hidden Max Bid"%>
        </div>
        <%= number_input f, :hidden_high_bid%>

        <button form="nominate-form" type="submit"
          class="mt-2 w-full py-2 px-4 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 transition duration-150 ease-in-out
                  active:bg-indigo-700
                  hover:bg-indigo-500
                  focus:outline-none focus:border-indigo-700 focus:ring focus:ring-indigo-300">
          Nominate
        </button>
      </.form>
    </div>
    """
  end
end
