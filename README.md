# Auction

Imagine a real-time auction system, where users can submit bids on the same item at the same time. The auction lasts for 30 seconds, the starting bid is $1, bids are only in whole-dollar amounts, and the highest bidder when the auction closes wins.
- The auctioneer can hit a button to open bidding and begin the timer.
- Users can hit a button to bid on the item. Hitting the button should place a new bid for that user at the current winning bid plus the current minimum increment.
- The minimum increment is the previous power of ten. Example: if the current bid is $90, the next minimum bid is $91. If the current bid is $100, the next minimum bid is $110.
- Users see their bids confirmed in real-time.
- Users can see the current winning bid, whether that bid is theirs, and the countdown of how much time is left.
- When the auction closes, users should be able to see the winning bid amount and if they won. 

To start your Phoenix server:

  * Run `mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

