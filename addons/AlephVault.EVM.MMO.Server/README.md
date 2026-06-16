# AlephVault.EVM.MMO.Server

Server-side Multiplayer API nodes for EVM MMO-style projects.

This package exposes the global namespace `AlephVault__EVM__MMO__Server` and depends
on [AlephVault.EVM.MMO.Common](../AlephVault.EVM.MMO.Common/README.md).

Read the client package documentation for the mirrored client-side setup:
[AlephVault.EVM.MMO.Client](../AlephVault.EVM.MMO.Client/README.md).

## SIWE-Like Authentication Server

Use `AlephVault__EVM__MMO__Server.Authentication.Protocol` as the server-side
authentication protocol node. It extends the base MMO authentication server and
implements `_authenticate(connection_id, method, payload)`.

Configure:

```gdscript
var auth := AlephVault__EVM__MMO__Server.Authentication.Protocol.new()
auth.siwe_domain = "main.myawesomegame.play"
auth.chain_id = 31337
```

The protocol validates required fields, domain, address, chain id, nonce shape,
version, expiration timestamp, nonce replay, and the EIP-712 signature. Accepted
accounts use the normalized lowercase address as the account id.

Rejection reasons:

- `siwe:invalid_payload`
- `siwe:domain_mismatch`
- `siwe:invalid_address`
- `siwe:invalid_chain`
- `siwe:chain_mismatch`
- `siwe:invalid_nonce`
- `siwe:invalid_version`
- `siwe:expired`
- `siwe:signature_verification_failed`
- `siwe:address_mismatch`

Override `_check_address_allowance(connection_id, address)` to add allowlists,
bans, or account provisioning:

```gdscript
func _check_address_allowance(connection_id: int, address: String) -> Variant:
	if address in banned_addresses:
		return AlephVault__MMO__Common.Protocols.Authentication.LoginResult.reject({
			"reason": "address_banned",
		})
	return null
```

If the override returns a dictionary with `accepted == false`, `_authenticate`
returns it unchanged. Any other return value allows the generated success
response.
