# AlephVault.EVM.MMO.Client

Client-side Multiplayer API nodes for EVM MMO-style projects.

This package exposes the global namespace `AlephVault__EVM__MMO__Client` and depends
on [AlephVault.EVM.MMO.Common](../AlephVault.EVM.MMO.Common/README.md).

Read the server package documentation for the mirrored server-side setup:
[AlephVault.EVM.MMO.Server](../AlephVault.EVM.MMO.Server/README.md).

## SIWE-Like Authentication Client

Use `AlephVault__EVM__MMO__Client.Authentication.Protocol` as the client-side
authentication protocol node. It extends the base MMO authentication client and
sends `login("siwe", payload)`.

Configure:

```gdscript
var auth := AlephVault__EVM__MMO__Client.Authentication.Protocol.new()
auth.siwe_domain = "main.myawesomegame.play"
auth.chain_id = 31337
auth.wallet = unlocked_wallet
```

`wallet` must expose `request(method, params)`, matching
`AlephVault__EVM.Web3Client`. Calling `await auth.login_siwe()` builds the
payload, generates a 32-byte nonce, signs the EIP-712 typed data via
`eth_signTypedData_v4`, and sends the login request.

Override `_get_wallet()` if your wallet is owned elsewhere in the scene tree.
Use `make_signed_siwe_payload(address = "")` when you need to inspect or send
the payload manually.

For native clients, initialize the `Web3Client` through the wallet modal before
calling `login_siwe()`:

```gdscript
var web3 := AlephVault__EVM.Web3Client.new()
var modal := AlephVault__EVM.UI.WalletModal.new()
modal.client = web3
modal.chain_rpc_url = "http://127.0.0.1:8545"
modal.started.connect(func(_lock: Callable):
	auth.wallet = web3
	await auth.login_siwe()
)
add_child(modal)
modal.show_from_scratch()
```

HTML5 clients can initialize the same `Web3Client` directly with
`await web3.initialize()` and then assign it to `auth.wallet`.
