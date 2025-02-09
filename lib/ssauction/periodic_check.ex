defmodule SSAuction.PeriodicCheck do
  use GenServer

  alias SSAuction.Auctions

  def start_link(default) when is_list(default) do
    GenServer.start_link(__MODULE__, default)
  end

  @impl true
  def init(state) do
    # Schedule work to be performed at some point
    schedule_work()
    {:ok, state}
  end

  @impl true
  def handle_info(:work, state) do
    Auctions.check_for_expired_bids()
    Auctions.check_for_new_nominations()
    Auctions.check_for_expired_nominations()

    # Reschedule once more
    schedule_work()
    {:noreply, state}
  end

  defp schedule_work() do
    Process.send_after(self(), :work, 10000)
  end
end
