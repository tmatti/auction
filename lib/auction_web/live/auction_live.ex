defmodule AuctionWeb.AuctionLive do
  use AuctionWeb, :live_view

  alias AuctionServer

  def mount(%{"auction" => auction, "name" => user}, _session, socket) do
    {:ok, _pid} = AuctionServer.start_auction(auction)
    %{current_bid: bid, current_bidder: current_bidder} = AuctionServer.get_state(auction)

    Phoenix.PubSub.subscribe(Auction.PubSub, "auction:#{auction}")

    {:ok, assign(socket, auction: auction, current_bid: bid, current_bidder: current_bidder, user: user)}
  end

  def handle_event("place_bid", %{"bid" => bid}, socket) do
    bid = String.to_integer(bid)

    case AuctionServer.place_bid(socket.assigns.auction, {bid, socket.assigns.user}) do
      :ok ->
        %{current_bid: bid, current_bidder: current_bidder} = AuctionServer.get_state(socket.assigns.auction)
        {:noreply, assign(socket, current_bid: bid, current_bidder: current_bidder)}

      {:error, :auction_not_found} ->
        {:noreply, socket |> put_flash(:error, "Auction not found")}
    end
  end

  def handle_info({:new_bid, state}, socket) do
    {:noreply, assign(socket, current_bid: state.current_bid, current_bidder: state.current_bidder)}
  end

  def render(assigns) do
    ~H"""
    <.flash_group flash={@flash} />
    <section class="flex flex-col items-center py-24">
      <h1 class="mb-4 font-sans text-3xl font-bold">Auction House</h1>
      <div class="w-full max-w-md p-6 bg-white rounded-lg shadow-lg">
        <h2 class="mb-4 text-xl font-semibold text-gray-800">Auction: <%= @auction %></h2>
        <h2 class="mb-4 text-xl font-semibold text-gray-800">User: <%= @user %></h2>
        <h2 class="mb-4 text-xl font-semibold text-gray-800">Current Bid: $<%= @current_bid %> by <%= @current_bidder %></h2>

        <div class="flex items-center space-x-4">
          <form phx-submit="place_bid" class="flex flex-col items-center gap-2">
            <input type="hidden" name="auction" value={@auction} />
            <input type="hidden" name="user" value={@user} />
            <div class="flex flex-col items-start">
              <label for="bid" class="mb-1 text-gray-700">Bid Amount:</label>
              <input
                type="number"
                id="bid"
                name="bid"
                min={@current_bid + 1}
                value={@current_bid + 1}
                class="p-2 border border-gray-300 rounded-md"
              />
            </div>
            <button
              type="submit"
              class="px-4 py-2 font-bold text-white bg-blue-500 rounded hover:bg-blue-700"
            >
              Bid
            </button>
          </form>
        </div>
      </div>
    </section>
    """
  end
end
