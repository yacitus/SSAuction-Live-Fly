defmodule SSAuctionWeb.CutPlayerFormComponent do
  use SSAuctionWeb, :live_component

  def mount(socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      <form id="cut-player-form" phx-submit="submit-cut-player"
        class="bg-slate-200 px-10 py-8 mb-6 shadow rounded-lg px-6 mt-8 mx-auto w-full max-w-md">

        <div class="block mb-2 text-lg font-medium text-slate-700">
          <p>Current cost: <b>$<%= @player_to_cut.cost %></b></p>
          <p>Cost after cutting: <b>$<%= @cost %></b></p>
        </div>

        <button form="cut-player-form" type="submit"
          class="mt-2 w-full py-2 px-4 border border-transparent text-sm font-medium rounded-md text-white bg-red-600 transition duration-150 ease-in-out
                  active:bg-red-700
                  hover:bg-red-500
                  focus:outline-none focus:border-red-700 focus:ring focus:ring-red-300">
          Cut
        </button>

        <button form="cut-player-form" type="button" phx-click="close"
          class="mt-2 w-full py-2 px-4 border border-transparent text-sm font-medium rounded-md text-white bg-gray-600 transition duration-150 ease-in-out
                  active:bg-gray-700
                  hover:bg-gray-500
                  focus:outline-none focus:border-gray-700 focus:ring focus:ring-gray-300">
          Don't Cut
        </button>
      </form>
    </div>
    """
  end
end
