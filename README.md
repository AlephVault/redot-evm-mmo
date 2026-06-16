# redot-evm-mmo
A Redot/Godot add-on to make EVM-powered multiplayer massive online games via a particular authentication
protocol behaving SIWE-like (there will be few differences with the original specification, but it shares
the same purpose of official SIWE).

## Installation

This package might be available in the Redot/Godot Asset Library. However, it can also be installed
right from this repository, provided the contents of the `addons/` directory are added into the
project's `addons/` directory.

This add-on depends on AlephVault MMO and AlephVault EVM packages. They are not
part of this repository; install them from their respective repositories before
using this add-on:

- `addons/AlephVault.MMO.Common` from `https://github.com/AlephVault/redot-mmo`
- `addons/AlephVault.MMO.Client` from `https://github.com/AlephVault/redot-mmo`
- `addons/AlephVault.MMO.Server` from `https://github.com/AlephVault/redot-mmo`
- `addons/AlephVault.MMO.Storage` from `https://github.com/AlephVault/redot-mmo`
- `addons/AlephVault.EVM` from `https://github.com/AlephVault/redot-evm`

## Documentation

- [AlephVault.EVM.MMO.Common](addons/AlephVault.EVM.MMO.Common/README.md)
- [AlephVault.EVM.MMO.Server](addons/AlephVault.EVM.MMO.Server/README.md)
- [AlephVault.EVM.MMO.Client](addons/AlephVault.EVM.MMO.Client/README.md)

## Samples

The fake TIME protocol sample is under
`addons/AlephVault.EVM.MMO.Samples/scenes/time/`. Start `time-server.tscn`,
then open `time-client.tscn`. The client creates an `AlephVault__EVM.Web3Client`,
opens `AlephVault__EVM.UI.WalletModal` for native wallets, and injects the ready
wallet into the SIWE-like auth protocol before connecting. After authentication,
the server replies with:

```text
Hello 0x..., the current time is yyyy-mm-dd HH:MM:SS
```
