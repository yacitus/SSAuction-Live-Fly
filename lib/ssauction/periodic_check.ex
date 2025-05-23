defmodule SSAuction.PeriodicCheck do
  use GenServer

  alias SSAuction.Auctions
  alias SSAuction.Auctions.Auction

  def start_link(default) when is_list(default) do
    GenServer.start_link(__MODULE__, default)
  end

  @impl true
  def init(state) do
    schedule_work() # Schedule work to be performed at some point
    {:ok, state}
  end

  @impl true
  def handle_info(:work, state) do
    Auctions.check_for_expired_bids()
    Auctions.check_for_new_nominations()
    Auctions.check_for_expired_nominations()

    schedule_work() # Reschedule once more
    {:noreply, state}
  end

  @impl true
  # also handle updating the auction_rostered_players cache here
  def handle_info({:roster_change, auction = %Auction{}}, state) do
    {:ok, true} = Cachex.put(:auction_rostered_players, auction.id,
      Auctions.get_rostered_players_with_rostered_at_no_cache(auction))
    {:noreply, state}
  end

  defp schedule_work() do
    Process.send_after(self(), :work, 60000)
  end
end
