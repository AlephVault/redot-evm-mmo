extends AlephVault__MMO__Server.Protocols.Authentication.Protocol

const Siwe = AlephVault__EVM__MMO__Common.Authentication.Siwe

## Game domain/id accepted by this server.
var siwe_domain := ""

## Expected EVM chain id.
var chain_id := 0

## Keeps accepted nonces until their expiration time to reduce replay attempts.
var _accepted_nonces: Dictionary = {}

## Optional verifier object. Defaults to a native AlephVaultEvmNativeWallet
## instance when that GDExtension class is available.
var verifier = null

func _authenticate(connection_id: int, method: String, payload: Variant) -> Dictionary:
	if method != Siwe.METHOD:
		return Siwe.reject("siwe:invalid_method", {"method": method})
	if not payload is Dictionary:
		return Siwe.reject("siwe:invalid_payload")

	var data := payload as Dictionary
	for key in ["domain", "address", "chainId", "nonce", "version", "expirationTime", "signature"]:
		if not data.has(key):
			return Siwe.reject("siwe:invalid_payload", {"missing": key})

	var domain := str(data["domain"])
	var address := str(data["address"])
	var nonce := str(data["nonce"])
	var signature := str(data["signature"])
	var request_chain_id := int(data["chainId"])
	var version := int(data["version"])
	var expiration_time := int(data["expirationTime"])

	if domain != siwe_domain:
		return Siwe.reject("siwe:domain_mismatch")
	if not Siwe.is_valid_address(address):
		return Siwe.reject("siwe:invalid_address")
	if request_chain_id == 0:
		return Siwe.reject("siwe:invalid_chain")
	if request_chain_id != chain_id:
		return Siwe.reject("siwe:chain_mismatch")
	if not Siwe.is_valid_nonce(nonce):
		return Siwe.reject("siwe:invalid_nonce")
	if version != Siwe.VERSION:
		return Siwe.reject("siwe:invalid_version")
	if int(Time.get_unix_time_from_system()) > expiration_time:
		return Siwe.reject("siwe:expired")
	if _is_nonce_replayed(nonce):
		return Siwe.reject("siwe:invalid_nonce")

	var signed_payload := {
		"domain": domain,
		"address": address,
		"chainId": request_chain_id,
		"nonce": nonce,
		"version": version,
		"expirationTime": expiration_time,
	}
	var typed_data_json := Siwe.make_typed_data_json(signed_payload)
	var recovered_address := _recover_address(typed_data_json, signature)
	if recovered_address == null:
		return Siwe.reject("siwe:signature_verification_failed")
	if str(recovered_address).is_empty():
		return Siwe.reject("siwe:invalid_payload")
	if Siwe.normalize_address(str(recovered_address)) != Siwe.normalize_address(address):
		return Siwe.reject("siwe:address_mismatch")

	var allowance: Variant = await _check_address_allowance(connection_id, Siwe.normalize_address(address))
	if allowance is Dictionary and not bool((allowance as Dictionary).get("accepted", true)):
		return allowance

	_accepted_nonces[nonce.to_lower()] = expiration_time
	var normalized_address := Siwe.normalize_address(address)
	return AlephVault__MMO__Common.Protocols.Authentication.LoginResult.accept(
		{"address": normalized_address},
		normalized_address
	)

## Override to reject or enrich address admission.
##
## Return null to allow by default. Return LoginResult.reject(...) to deny.
func _check_address_allowance(connection_id: int, address: String) -> Variant:
	return null

func _find_account(account_id: Variant) -> Variant:
	return {"address": str(account_id)}

func _recover_address(typed_data_json: String, signature: String) -> Variant:
	var active_verifier: Variant = _get_verifier()
	if active_verifier == null or not active_verifier.has_method("recover_eth_sign_typed_data"):
		return null
	var response: Dictionary = active_verifier.recover_eth_sign_typed_data(typed_data_json, signature)
	if not bool(response.get("ok", false)):
		if str(response.get("error", "")) == "invalid_typed_data":
			return ""
		return null
	return str(response.get("value", ""))

func _get_verifier() -> Variant:
	if verifier != null:
		return verifier
	if ClassDB.class_exists("AlephVaultEvmNativeWallet"):
		verifier = ClassDB.instantiate("AlephVaultEvmNativeWallet")
	return verifier

func _is_nonce_replayed(nonce: String) -> bool:
	var now := int(Time.get_unix_time_from_system())
	for cached_nonce in _accepted_nonces.keys():
		if int(_accepted_nonces[cached_nonce]) < now:
			_accepted_nonces.erase(cached_nonce)
	var key := nonce.to_lower()
	return _accepted_nonces.has(key)
