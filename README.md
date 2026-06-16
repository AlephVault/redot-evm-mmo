# redot-evm-mmo
A Redot/Godot add-on to make EVM-powered multiplayer massive online games via a particular authentication
protocol behaving SIWE-like (there will be few differences with the original specification, but it shares
the same purpose of official SIWE).

## Installation

This package might be available in the Redot/Godot Asset Library. However, it can also be installed
right from this repository, provided the contents of the `addons/` directory are added into the
project's `addons/` directory.

BindRose depends on AlephVault MMO and WindRose packages. They are not part of this repository; install them
from their respective repositories before using BindRose:

- `addons/AlephVault.MMO.Common` from `https://github.com/AlephVault/redot-mmo`
- `addons/AlephVault.MMO.Client` from `https://github.com/AlephVault/redot-mmo`
- `addons/AlephVault.MMO.Server` from `https://github.com/AlephVault/redot-mmo`
- `addons/AlephVault.MMO.Storage` from `https://github.com/AlephVault/redot-mmo`
- `addons/AlephVault.EVM` from `https://github.com/AlephVault/redot-evm`

## Documentation

- [AlephVault.BindRose.Common](addons/AlephVault.BindRose.Common/README.md)
- [AlephVault.BindRose.Server](addons/AlephVault.BindRose.Server/README.md)
- [AlephVault.BindRose.Client](addons/AlephVault.BindRose.Client/README.md)
