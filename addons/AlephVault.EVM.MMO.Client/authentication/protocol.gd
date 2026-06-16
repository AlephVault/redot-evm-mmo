extends AlephVault__MMO__Client.Protocols.Authentication.Protocol

const Siwe = AlephVault__EVM__MMO__Common.Authentication.Siwe

## Game domain/id expected by the server.
var siwe_domain := ""

## Expected EVM chain id.
var chain_id := 0

## Seconds added to Time.get_unix_time_from_system() when building a login.
var expiration_seconds := 120

## Wallet/provider object. It must expose request(method, params).
var wallet = null

## Returns the wallet/provider object used by login_siwe().
##
## Override this when the wallet is owned elsewhere in the scene tree.
func _get_wallet() -> Variant:
	return wallet

## Builds, signs, and sends the SIWE-like login request.
func login_siwe(address: String = "") -> bool:
	var login_payload := await make_signed_siwe_payload(address)
	if login_payload.is_empty():
		return false
	return login(Siwe.METHOD, login_payload)

## Builds and signs the SIWE-like payload without sending it.
func make_signed_siwe_payload(address: String = "") -> Dictionary:
	var signer := _get_wallet()
	if signer == null:
		return {}

	var account := address
	if account.is_empty():
		var accounts_response: Dictionary
		if signer.has_method("get_accounts"):
			accounts_response = await signer.get_accounts()
		else:
			accounts_response = await signer.request("eth_accounts", [])
		if not bool(accounts_response.get("ok", false)):
			return {}
		var accounts: Array = accounts_response.get("value", [])
		if accounts.is_empty():
			return {}
		account = str(accounts[0])

	var expiration_time := int(Time.get_unix_time_from_system()) + max(1, expiration_seconds)
	var payload := Siwe.make_payload(siwe_domain, account, chain_id, expiration_time)
	var typed_data := Siwe.make_typed_data(payload)
	var sign_response: Dictionary
	if signer.has_method("eth_sign_typed_data"):
		sign_response = await signer.eth_sign_typed_data(typed_data, account)
	else:
		sign_response = await signer.request("eth_signTypedData_v4", [account, typed_data])
	if not bool(sign_response.get("ok", false)):
		return {}
	payload["signature"] = str(sign_response.get("value", ""))
	return payload
