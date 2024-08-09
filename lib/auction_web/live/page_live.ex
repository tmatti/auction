defmodule AuctionWeb.PageLive do
  use AuctionWeb, :live_view

  alias AuctionWeb.Router.Helpers, as: Routes

  def mount(_params, _session, socket) do
    {:ok, assign(socket, name: "", auction: "")}
  end

  def handle_event("join_auction", %{"name" => name, "auction" => auction}, socket) do
    {:noreply, push_navigate(socket, to: "/auction/#{auction}/#{name}")}
  end

  def render(assigns) do
    ~H"""
    <section class="flex flex-col items-center py-24">
      <h1 class="mb-4 font-sans text-3xl font-bold">Welcome to the Auction House</h1>
      <div class="w-full max-w-md p-6 bg-white rounded-lg shadow-lg">
        <form phx-submit="join_auction" class="flex flex-col items-center gap-4">
          <div class="flex flex-col items-start w-full">
            <label for="name" class="mb-1 text-gray-700">Your Name:</label>
            <input type="text" id="name" name="name" value={@name} required class="w-full p-2 border border-gray-300 rounded-md" />
          </div>
          <div class="flex flex-col items-start w-full">
            <label for="auction" class="mb-1 text-gray-700">Auction ID:</label>
            <input type="text" id="auction" name="auction" value={@auction} required class="w-full p-2 border border-gray-300 rounded-md" />
          </div>
          <button type="submit" class="w-full px-4 py-2 font-bold text-white bg-blue-500 rounded hover:bg-blue-700">
            Join Auction
          </button>
        </form>
      </div>
    </section>
    """
  end
end
