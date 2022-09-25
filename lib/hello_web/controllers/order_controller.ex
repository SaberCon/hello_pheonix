defmodule HelloWeb.OrderController do
  use HelloWeb, :controller

  alias Hello.Orders

  def create(conn, _) do
    case Orders.complete_order(conn.assigns.cart) do
      {:ok, order} ->
        conn
        |> put_flash(:info, "Order created successfully.")
        |> redirect(to: Routes.order_path(conn, :show, order))

      {:error, _reason} ->
        conn
        |> put_flash(:error, "There was an error processing your order")
        |> redirect(to: Routes.cart_path(conn, :show))
    end
  end

  def show(conn, %{"id" => id}) do
    order = Orders.get_order!(conn.assigns.current_uuid, id)
    render(conn, "show.html", order: order)
  end
end
