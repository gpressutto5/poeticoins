defmodule Poeticoins.Exchanges.CoinbaseClient do
  alias Poeticoins.{Trade, Product, Exchanges}
  alias Poeticoins.Exchanges.Client
  require Client

  Client.defclient(
    exchange_name: "coinbase",
    host: 'ws-feed.pro.coinbase.com',
    port: 443,
    currency_pairs: ["BTC-USD", "ETH-USD", "LTC-USD", "BTC-EUR", "ETH-EUR", "LTC-EUR"]
  )

  @impl true
  def handle_ws_message(%{"type" => "ticker"} = msg, state) do
    {:ok, trade} = message_to_trade(msg)
    Exchanges.broadcast(trade)
    {:noreply, state}
  end

  def handle_ws_message(msg, state) do
    IO.inspect(msg, label: "unhandled message")
    {:noreply, state}
  end

  def subscription_frames(currency_pairs) do
    msg =
      %{
        type: "subscribe",
        product_ids: currency_pairs,
        channels: ["ticker"]
      }
      |> Jason.encode!()

    [{:text, msg}]
  end

  @spec message_to_trade(map) :: {:error, any()} | {:ok, Trade.t()}
  def message_to_trade(msg) do
    with :ok <- validate_required(msg, ["product_id", "price", "last_size", "time"]),
         {:ok, traded_at, _} <- DateTime.from_iso8601(msg["time"]) do
      {:ok,
       Trade.new(
         product: Product.new(exchange_name(), msg["product_id"]),
         price: msg["price"],
         volume: msg["last_size"],
         traded_at: traded_at
       )}
    else
      {:error, _reason} = error -> error
    end
  end
end
