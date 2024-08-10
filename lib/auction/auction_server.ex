defmodule AuctionServer do
  use GenServer

  def start_link({auction_id, initial_bid}) do
    GenServer.start_link(__MODULE__, {auction_id, initial_bid},
      name: {:via, Registry, {Auction.Registry, auction_id}}
    )
  end

  def get_or_create_auction(auction_id, initial_bid \\ 1) do
    case Registry.lookup(Auction.Registry, auction_id) do
      [{pid, _value}] ->
        {:ok, pid}

      [] ->
        DynamicSupervisor.start_child(
          Auction.AuctionSupervisor,
          {__MODULE__, {auction_id, initial_bid}}
        )
    end
  end

  def start_auction(auction_id) do
    case Registry.lookup(Auction.Registry, auction_id) do
      [{pid, _value}] -> GenServer.call(pid, :start_auction)
      _ -> {:error, :auction_not_found}
    end
  end

  def place_bid(auction_id, {bid, user}) do
    case Registry.lookup(Auction.Registry, auction_id) do
      [{pid, _value}] ->
        GenServer.call(pid, {:place_bid, {bid, user}})

      [] ->
        {:error, :auction_not_found}
    end
  end

  def get_state(auction_id) do
    case Registry.lookup(Auction.Registry, auction_id) do
      [{pid, _value}] -> GenServer.call(pid, :get_state)
      [] -> {:error, :auction_not_found}
    end
  end

  def init({auction_id, initial_bid}) do
    Registry.register(Auction.Registry, auction_id, nil)

    state = %{
      auction_id: auction_id,
      bids: [],
      current_bid: 0,
      current_bidder: nil,
      next_bid: initial_bid,
      status: :pending,
      start_time: nil,
      end_time: nil,
      timer_ref: nil
    }

    {:ok, state}
  end

  def handle_call(:start_auction, _from, %{start_time: %DateTime{}}),
    do: {:error, :auction_already_started}

  def handle_call(:start_auction, _from, %{start_time: nil} = state) do
    start_time = DateTime.utc_now()
    end_time = DateTime.add(start_time, 30, :second)
    timer_ref = Process.send_after(self(), :end_auction, 30_000)

    new_state = %{
      state
      | start_time: start_time,
        end_time: end_time,
        timer_ref: timer_ref,
        status: :active
    }

    broadcast(:auction_started, new_state)
    {:reply, {:ok, new_state}, new_state}
  end

  def handle_call({:place_bid, {bid, user}}, _from, state) do
    if bid >= state.next_bid do
      updated_bids = [{user, bid} | state.bids]
      next_minimum_bid = Auction.Bid.calculate_next_minimum_bid(bid)

      new_state = %{
        state
        | bids: updated_bids,
          current_bid: bid,
          current_bidder: user,
          next_bid: next_minimum_bid
      }

      broadcast(:new_bid, new_state)
      {:reply, {:ok, new_state}, new_state}
    else
      {:reply, {:error, :invalid_bid}, state}
    end
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  def handle_info(:end_auction, state) do
    updated_state = %{
      state
      | status: :completed
    }

    broadcast(:auction_ended, updated_state)
    {:noreply, updated_state}
  end

  defp broadcast(event, state) do
    Phoenix.PubSub.broadcast(Auction.PubSub, "auction:#{state.auction_id}", {event, state})
  end
end
