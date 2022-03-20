# from pragstudio-liveview-pro-code/final_app_v0.16/lib/live_view_studio_web/live/components/modal_component.ex
defmodule SSAuctionWeb.ModalComponent do
  use SSAuctionWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full">
    <div class="relative top-40 mx-auto p-5 border w-1/2 shadow-lg rounded-md bg-white"
         phx-window-keydown="close"
         phx-key="escape"
         phx-capture-click="close"
         phx-target={@myself}>
      <div class="flex justify-end p-2">
        <span>
          <h2 class="w-full text-blue-700 text-2xl font-bold text-left">
            <%= @title %>
          </h2>
        </span>

        <button phx-click="close" type="button" class="text-gray-400 bg-transparent hover:bg-gray-200 hover:text-gray-900 rounded-lg text-sm p-1.5 ml-auto inline-flex items-center dark:hover:bg-gray-800 dark:hover:text-white">
            <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg"><path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd"></path></svg>  
        </button>
      </div>

      <p class="alert alert-danger" role="alert"
        phx-click="lv:clear-flash"
        phx-value-key="error"><%= live_flash(@flash, :validation) %></p>

      <%= live_component @component, @opts %>
    </div>
    </div>
    """
  end

  @impl true
  def handle_event("close", _, socket) do
    {:noreply, push_patch(socket, to: socket.assigns.return_to)}
  end
end
