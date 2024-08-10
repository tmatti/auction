defmodule AuctionWeb.AuctionLive do
  use AuctionWeb, :live_view

  alias AuctionServer

  def mount(%{"auction" => auction, "name" => user}, _session, socket) do
    {:ok, _pid} = AuctionServer.get_or_create_auction(auction)
    state = AuctionServer.get_state(auction)

    Phoenix.PubSub.subscribe(Auction.PubSub, "auction:#{auction}")

    {:ok, assign(socket, auction: state, user: user)}
  end

  def handle_event("place_bid", %{"bid" => bid}, socket) do
    bid = String.to_integer(bid)

    case AuctionServer.place_bid(socket.assigns.auction.auction_id, {bid, socket.assigns.user}) do
      {:ok, auction} ->
        {:noreply, assign(socket, auction: auction)}

      {:error, :auction_not_found} ->
        {:noreply, socket |> put_flash(:error, "Auction not found")}
    end
  end

  def handle_event("start_auction", _params, socket) do
    case AuctionServer.start_auction(socket.assigns.auction.auction_id) do
      {:ok, auction} ->
        {:noreply, assign(socket, auction: auction)}

      {:error, :auction_not_found} ->
        {:noreply, socket |> put_flash(:error, "Auction not found")}
    end
  end

  def handle_event("home", _params, socket) do
    {:noreply, push_navigate(socket, to: "/")}
  end

  def handle_info({:new_bid, auction}, socket) do
    {:noreply, assign(socket, auction: auction)}
  end

  def handle_info({:auction_started, auction}, socket) do
    {:noreply, assign(socket, auction: auction)}
  end

  def handle_info({:auction_ended, auction}, socket) do
    {:noreply, assign(socket, auction: auction)}
  end

  def render(assigns) do
    ~H"""
    <.flash_group flash={@flash} />
    <section class="flex flex-col items-center py-24">
      <h1 class="mb-4 font-sans text-3xl font-bold">Auction House</h1>
      <div class="flex flex-col w-full max-w-md gap-4 p-6 bg-white rounded-lg shadow-lg">
        <h2 class="text-xl font-semibold text-gray-800">User: <%= @user %></h2>
        <h2 class="text-xl font-semibold text-gray-800">Auction: <%= @auction.auction_id %></h2>
        <%= if @auction.status in [:active, :completed] do %>
          <ul>
            <li class="text-gray-800 text-md">Start: <%= @auction.start_time %></li>
            <li class="text-gray-800 text-md">End: <%= @auction.end_time %></li>
          </ul>

          <h2 class="text-xl font-semibold text-gray-800">
            <%= case @auction.status do
              :active -> "Current Bid: "
              :completed -> "Winning Bid: "
            end %> $<%= @auction.current_bid %> by <%= @auction.current_bidder %>
          </h2>
        <% end %>

        <div class="flex items-center space-x-4">
          <%= if @auction.status == :pending do %>
            <form phx-submit="start_auction" class="flex flex-col items-start gap-2">
              <button
                type="submit"
                class="px-4 py-2 font-bold text-white bg-blue-500 rounded hover:bg-blue-700"
              >
                Start Auction
              </button>
            </form>
          <% end %>
          <%= if @auction.status == :active do %>
            <form phx-submit="place_bid" class="flex flex-col items-start gap-2">
              <input type="hidden" name="auction" value={@auction.auction_id} />
              <input type="hidden" name="user" value={@user} />
              <div class="flex flex-col items-start">
                <label for="bid" class="mb-1 text-gray-700">Bid Amount:</label>
                <input
                  type="number"
                  id="bid"
                  name="bid"
                  value={@auction.next_bid}
                  #
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
          <% end %>
          <%= if @auction.status == :completed do %>
            <form phx-submit="home">
              <button
                type="submit"
                class="w-full px-4 py-2 font-bold text-white bg-blue-500 rounded hover:bg-blue-700"
              >
                Home
              </button>
            </form>
          <% end %>
        </div>
      </div>
    </section>
    """
  end
end
