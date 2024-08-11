defmodule Auction.Bid do
  def calculate_next_minimum_bid(current_bid) do
    power_of_ten = current_bid |> :math.log10() |> trunc()
    prev_power_of_ten = max(0, power_of_ten - 1)
    current_bid + trunc(:math.pow(10, prev_power_of_ten))
  end
end
