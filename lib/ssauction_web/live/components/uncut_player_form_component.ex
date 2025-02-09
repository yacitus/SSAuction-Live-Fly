defmodule SSAuctionWeb.UncutPlayerFormComponent do
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
      <.form let={_f} for={@changeset} as={:changeset} id="cut-player-form" phx-submit="submit-uncut-player" phx-change="validate-uncut-player"
          class="bg-slate-200 px-10 py-8 mb-6 shadow rounded-lg px-6 mt-8 mx-auto w-full max-w-md">

        <div class="block mb-2 text-lg font-medium text-slate-700">
          <p>Team to re-roster: <b><%= @player_to_uncut.team.name %> (<%= @player_to_uncut.team.id %>)</b></p>
          <p>Cost: <b>$<%= @player_to_uncut.cost %></b></p>
        </div>

        <button form="cut-player-form" type="submit"
          class="mt-2 w-full py-2 px-4 border border-transparent text-sm font-medium rounded-md text-white bg-red-600 transition duration-150 ease-in-out
                  active:bg-red-700
                  hover:bg-red-500
                  focus:outline-none focus:border-red-700 focus:ring focus:ring-red-300">
          Un-cut
        </button>

        <button form="cut-player-form" type="button" phx-click="close"
          class="mt-2 w-full py-2 px-4 border border-transparent text-sm font-medium rounded-md text-white bg-gray-600 transition duration-150 ease-in-out
                  active:bg-gray-700
                  hover:bg-gray-500
                  focus:outline-none focus:border-gray-700 focus:ring focus:ring-gray-300">
          Don't Un-cut
        </button>
      </.form>
    </div>
    """
  end
end
