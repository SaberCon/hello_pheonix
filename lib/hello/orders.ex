defmodule Hello.Orders do
  @moduledoc """
  The Orders context.
  """

  import Ecto.Query, warn: false
  alias Hello.Repo

  alias Hello.Orders.{Order, LineItem}
  alias Hello.ShoppingCart

  @doc """
  Gets a single order.

  Raises `Ecto.NoResultsError` if the Order does not exist.

  ## Examples

      iex> get_order!(123)
      %Order{}

      iex> get_order!(456)
      ** (Ecto.NoResultsError)

  """
  def get_order!(user_uuid, id) do
    Order
    |> Repo.get_by!(id: id, user_uuid: user_uuid)
    |> Repo.preload(line_items: [:product])
  end

  def complete_order(%ShoppingCart.Cart{} = cart) do
    line_items =
      Enum.map(cart.items, fn item ->
        %{product_id: item.product_id, price: item.product.price, quantity: item.quantity}
      end)

    order =
      Ecto.Changeset.change(%Order{},
        user_uuid: cart.user_uuid,
        total_price: ShoppingCart.total_cart_price(cart),
        line_items: line_items
      )

    Ecto.Multi.new()
    |> Ecto.Multi.insert(:order, order)
    |> Ecto.Multi.run(:prune_cart, fn _repo, _changes ->
      ShoppingCart.prune_cart_items(cart)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{order: order}} -> {:ok, order}
      {:error, name, value, _changes_so_far} -> {:error, {name, value}}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking order changes.

  ## Examples

      iex> change_order(order)
      %Ecto.Changeset{data: %Order{}}

  """
  def change_order(%Order{} = order, attrs \\ %{}) do
    Order.changeset(order, attrs)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking line_item changes.

  ## Examples

      iex> change_line_item(line_item)
      %Ecto.Changeset{data: %LineItem{}}

  """
  def change_line_item(%LineItem{} = line_item, attrs \\ %{}) do
    LineItem.changeset(line_item, attrs)
  end
end
