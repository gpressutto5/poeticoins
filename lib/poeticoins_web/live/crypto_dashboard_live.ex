defmodule PoeticoinsWeb.CryptoDashboardLive do
  use PoeticoinsWeb, :live_view

  def mount(_params, _session, socket) do
    products = Poeticoins.available_products()
    trades =
      products
      |> Poeticoins.get_last_trades()
      |> Enum.reject(&is_nil(&1))
      |> Enum.map(& {&1.product, &1})
      |> Enum.into(%{})

    if connected?(socket) do
      Enum.each(products, &Poeticoins.subscribe_to_trades(&1))
    end

    {:ok, assign(socket, trades: trades, products: products)}
  end

  @spec handle_info({:new_trade, any}, Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_info({:new_trade, trade}, socket) do
    socket = update(socket, :trades, &Map.put(&1, trade.product, trade))
    {:noreply, socket}
  end

  def render(assigns) do
    ~L"""
    <table>
    <thead>
        <th>Traded At</th>
        <th>Exchange</th>
        <th>Currency</th>
        <th>Price</th>
        <th>Volume</th>
    </thead>
    <tbody>
        <%= for product <- @products, trade = @trades[product], not is_nil(trade) do %>
        <tr>
        <td><%= trade.traded_at %></td>
        <td><%= trade.product.exchange_name %></td>
        <td><%= trade.product.currency_pair %></td>
        <td><%= trade.price %></td>
        <td><%= trade.volume %></td>
        </tr>
        <% end %>
    </tbody>
    </table>
    """
  end
end
