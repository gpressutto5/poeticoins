defmodule PoeticoinsWeb.ProductLive do
  use PoeticoinsWeb, :live_view
  import PoeticoinsWeb.ProductHelpers

  def mount(%{"id" => product_id} = _params, _session, socket) do
    product = product_from_string(product_id)
    trade = Poeticoins.get_last_trade(product)
    init_trades = get_trade_history(product)
    trades = Enum.take(init_trades, -10)

    socket =
      assign(socket,
        product: product,
        product_id: product_id,
        trade: trade,
        trades: trades,
        init_trades: init_trades,
        page_title: page_title_from_trade(trade)
      )

    if socket.connected? do
      Poeticoins.subscribe_to_trades(product)
    end

    {:ok, socket, temporary_assigns: [trades: [], init_trades: []]}
  end

  def render(%{trade: trade} = assigns) when not is_nil(trade) do
    ~L"""
    <div class="row">
      <div class="column"
              phx-hook="StockChart"
              phx-update="ignore"
              id="product-chart"
              data-product-id="<%= to_string(@product) %>"
              data-product-name="<%= @product.exchange_name %> <%= @product.currency_pair %>"
              data-trade-timestamp="<%= DateTime.to_unix(@trade.traded_at, :millisecond) %>"
              data-trade-volume="<%= @trade.volume %>"
              data-trade-price="<%= @trade.price %>"
              data-init-trades="<%= trades_to_chart_data(@init_trades) %>"
        >
        <div id="stockchart-container"></div>
      </div>
      <div class="column">
        <table id="trade-history">
          <thead>
            <th>Time</th>
            <th>Price</th>
            <th>Volume</th>
          </thead>
          <tbody phx-update="prepend" phx-hook="TradeHistory" id="trade-history-rows">
            <%= for trade <- @trades do %>
              <tr id="trade-<%= timestamp(trade.traded_at) %>">
                <td><%= trade.traded_at %></td>
                <td><%= trade.price %></td>
                <td><%= trade.volume %></td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>
    </div>
    """
  end

  def render(assigns) do
    ~L"""
    <div>
    <h1>Waiting for a trade...</h1>
    </div>
    """
  end

  def handle_info({:new_trade, trade}, socket) do
    socket =
      socket
      |> assign(:trade, trade)
      |> assign(:page_title, page_title_from_trade(trade))
      |> update(:trades, &[trade | &1])

    {:noreply, socket}
  end

  defp page_title_from_trade(trade) do
    "#{fiat_character(trade.product)}#{trade.price}" <>
      " #{trade.product.currency_pair} #{trade.product.exchange_name}"
  end

  defp timestamp(dt) do
    DateTime.to_unix(dt, :millisecond)
  end

  defp get_trade_history(product) do
    Poeticoins.Historical.get_trades(product)
  end

  defp to_event(trade) do
    %{
      traded_at: DateTime.to_unix(trade.traded_at, :millisecond),
      price: trade.price,
      volume: trade.volume
    }
  end

  defp trades_to_chart_data(trades) do
    trades
    |> Enum.map(&to_event(&1))
    |> Jason.encode!()
  end
end
