defmodule PoeticoinsWeb.CryptoDashboardLive do
  use PoeticoinsWeb, :live_view
  import PoeticoinsWeb.ProductHelpers
  alias Poeticoins.Product
  alias PoeticoinsWeb.Router.Helpers, as: Routes

  def mount(_params, _session, socket) do
    socket =
      assign(socket,
        products: [],
        timezone: get_timezone_from_connection(socket)
      )

    {:ok, socket}
  end

  def handle_info({:new_trade, trade}, socket) do
    send_update(PoeticoinsWeb.ProductComponent, id: trade.product, trade: trade)

    socket =
      socket
      |> maybe_update_title_with_trade(trade)

    {:noreply, socket}
  end

  def handle_params(%{"products" => product_ids}, _uri, socket) do
    new_products = Enum.map(product_ids, &product_from_string/1)
    diff = List.myers_difference(socket.assigns.products, new_products)
    products_to_remove = diff |> Keyword.get_values(:del) |> List.flatten()
    products_to_insert = diff |> Keyword.get_values(:ins) |> List.flatten()

    socket = Enum.reduce(products_to_remove, socket, &remove_product(&2, &1))

    socket = Enum.reduce(products_to_insert, socket, &insert_product(&2, &1))

    {:noreply, socket}
  end

  def handle_params(_params, _uri, socket), do: {:noreply, socket}

  def handle_event("add-product", %{"product_id" => product_id} = _params, socket) do
    product_ids =
      socket.assigns.products
      |> Enum.map(&to_string/1)
      |> Kernel.++([product_id])
      |> Enum.uniq()

    socket = push_patch(socket, to: Routes.live_path(socket, __MODULE__, products: product_ids))
    {:noreply, socket}
  end

  def handle_event("add-product", _, socket) do
    {:noreply, socket}
  end

  def handle_event("remove-product", %{"product-id" => product_id} = _params, socket) do
    product_ids =
      socket.assigns.products
      |> Enum.map(&to_string/1)
      |> Kernel.--([product_id])
      |> Enum.uniq()

    socket = push_patch(socket, to: Routes.live_path(socket, __MODULE__, products: product_ids))
    {:noreply, socket}
  end

  def add_product(socket, product) do
    Poeticoins.subscribe_to_trades(product)

    socket
    |> update(:products, &(&1 ++ [product]))
  end

  defp grouped_products_by_exchange_name do
    Poeticoins.available_products()
    |> Enum.group_by(& &1.exchange_name)
  end

  defp get_timezone_from_connection(socket) do
    case get_connect_params(socket) do
      %{"timezone" => tz} when not is_nil(tz) -> tz
      _ -> "UTC"
    end
  end

  defp maybe_update_title_with_trade(
         %{assigns: %{selected_product: product}} = socket,
         %{product: product} = trade
       ) do
    assign(socket, :page_title, "#{trade.price} - #{product.currency_pair}")
  end

  defp maybe_update_title_with_trade(socket, _trade) do
    socket
  end

  defp add_products_from_params(socket, _params), do: socket

  defp remove_product(socket, product) do
    Poeticoins.unsubscribe_from_trades(product)

    socket
    |> update(:products, &(&1 -- [product]))
  end

  defp insert_product(socket, product) do
    Poeticoins.subscribe_to_trades(product)

    socket
    |> update(:products, &(&1 ++ [product]))
  end
end
