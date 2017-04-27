defmodule ExPlayStore.PurchaseVerification do
  use Injector

  alias ExPlayStore.PurchaseReceipt

  inject ExPlayStore.OAuthToken
  inject Tesla

  @url [
    base: "https://www.googleapis.com/androidpublisher/v2/applications/",
    package_name: "",
    mid: "/purchases/products/",
    product_id: "",
    last: "/tokens/",
    token: ""
  ]

  def fetch_receipt(package_name, product_id, token) do
    auth_token = OAuthToken.get()
    headers = %{"Authorization" => "Bearer " <> auth_token.access_token}

    response = @url
    |> Keyword.update(:package_name, nil, fn(_) -> package_name end)
    |> Keyword.update(:product_id, nil, fn(_) -> product_id end)
    |> Keyword.update(:token, nil, fn(_) -> token end)
    |> Keyword.values
    |> Enum.join("")
    |> Tesla.get([headers: headers])

    case response.status do
      200 ->
        receipt = response.body
                  |> Poison.decode!
                  |> as_struct()
        {:ok, receipt}
      err_code ->
        {:error, err_code, response.body}
    end
  end

  defp as_struct(%{
      "consumptionState" => consumption_state,
      "developerPayload" => developer_payload,
      "kind" => kind,
      "purchaseState" => purchase_state,
      "purchaseTimeMillis" => purchase_time_millis,
    }) do
    %PurchaseReceipt{
      consumption_state: consumption_state,
      developer_payload: developer_payload,
      kind: kind,
      purchase_state: purchase_state,
      purchase_time_millis: purchase_time_millis
    }
  end
end
