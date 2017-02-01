defmodule Shopify.ShopTest do
  use ExUnit.Case
  alias Shopify.Shop

  setup do
    bypass = Bypass.open
    Application.put_env(:shopify, :oauth_site, endpoint_url(bypass.port))
    {:ok, bypass: bypass}
  end

  test "Shop.find returns a shop", %{bypass: bypass} do
    resource_module = Shop
    resource_map = %{"name" => "1337 Repairs", "customer_email" => "john@doe.com"}
    token = %OAuth2.AccessToken{access_token: "abc123"}
    client = %OAuth2.Client{site: endpoint_url(bypass.port), token: token}
    response_map = %{} |> Map.put(resource_module.singular_resource, resource_map)
    resource_json_string = json_string(response_map)

    Bypass.expect bypass, fn conn ->
      assert "/#{resource_module.singular_resource}.json" == conn.request_path
      assert "GET" == conn.method
      conn
      |> Plug.Conn.send_resp(200, resource_json_string)
    end

    { :ok, shop } = client |> resource_module.find

    assert shop == resource_map
  end

  def endpoint_url(port), do: "http://localhost:#{port}"

  def json_string(json_map) do
    case Poison.encode(json_map, []) do
      {:ok, json_bitstring} -> json_bitstring |> to_string
      _ -> {:error, "oops"}
    end
  end
end
