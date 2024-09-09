## pkxp forge library

Mainly forge script/test utilities and common vendor libraries. **USE AT YOUR OWN RISK**.

### Notes

- Use keystore accounts by name in scripts/tests, eg. `wm.sendFrom("my account")`. You can also use a gpg-encrypted password file by setting `ETH_PASSWORD_GPG`, otherwise `ETH_PASSWORD` is used.
- Pranks/broadcasts are recurrent and always wipe existing ones, so no need for `stopPrank` or `stopBroadcast`.

- To avoid clashes: `broadcast` is `sendFrom`
- Modifiers `pranked$` or `sendFrom$` restore the previous caller mode and account.

### Defaults

```solidity
string constant DEFAULT_RPC_ENV = "ETH_RPC_URL";
string constant DEFAULT_MNEMONIC_ENV = "MNEMONIC";
string constant DEFAULT_PK_ENV = "PRIVATE_KEY";
string constant DEFAULT_MNEMONIC = "error burger code";
string constant GPG_PASSWORD_ENV = "ETH_PASSWORD_GPG";
string constant BASE_FFI_DIR = "./lib/pkxp/src/";
```
