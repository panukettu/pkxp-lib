// solhint-disable
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {wm} from "./Wm.s.sol";
import {DEFAULT_MNEMONIC_ENV, DEFAULT_PK_ENV, DEFAULT_RPC_ENV} from "./Misc.sol";

contract Wallet {
    address payable internal sender;
    constructor() {
        wm.store().mEnv = DEFAULT_MNEMONIC_ENV;
        wm.store().pkEnv = DEFAULT_PK_ENV;
    }

    modifier mnemonic(string memory envKey) virtual {
        useMnemonic(envKey);
        _;
    }

    modifier mnemonicAt(string memory envKey, uint32 idx) virtual {
        useMnemonic(envKey, idx);
        _;
    }

    modifier wallets(string memory mEnvKey, string memory pkEnvKey) virtual {
        useWallets(mEnvKey, pkEnvKey);
        _;
    }

    modifier pk(string memory _env) virtual {
        usePk(_env);
        _;
    }

    function useMnemonic(
        string memory envKey
    ) internal virtual returns (address payable) {
        return useMnemonic(envKey, 0);
    }

    function useMnemonic(
        string memory envKey,
        uint32 idx
    ) internal virtual returns (address payable) {
        return sender = wm.getAddr(wm.store().mEnv = envKey, idx);
    }

    function useMnemonic() internal virtual returns (address payable) {
        return useMnemonic(wm.store().mEnv);
    }

    function useMnemonicAt(
        uint32 idx
    ) internal virtual returns (address payable) {
        return useMnemonic(wm.store().mEnv, idx);
    }

    function usePk(
        string memory envKey
    ) internal virtual returns (address payable) {
        return sender = wm.setPk(envKey);
    }

    function usePk() internal virtual returns (address payable) {
        return sender = wm.getAddrPk(wm.store().pkEnv);
    }

    function useAddr(
        address newSender
    ) internal virtual returns (address payable) {
        return sender = payable(newSender);
    }

    function useWallets(
        string memory mEnvKey,
        string memory pkEnvKey
    ) internal virtual returns (address payable maddr, address payable pkaddr) {
        maddr = useMnemonic(mEnvKey);
        pkaddr = usePk(pkEnvKey);
    }

    function getAddr(
        string memory ksId
    ) internal virtual returns (address payable) {
        return wm.getAddr(ksId);
    }

    function getAddr(uint32 idx) internal virtual returns (address payable) {
        return wm.getAddr(idx);
    }

    function getAddrPk(
        string memory pkEnvKey
    ) internal virtual returns (address payable) {
        return wm.getAddrPk(pkEnvKey);
    }

    function getAddrPk(uint256 raw) internal virtual returns (address payable) {
        return wm.getAddrPk(raw);
    }

    function msgSender() internal view virtual returns (address) {
        return wm.msgSender();
    }

    function getNextAddr() internal view virtual returns (address payable) {
        return getNextAddr(sender);
    }

    function getNextAddr(
        address d
    ) internal view virtual returns (address payable) {
        return wm.getNextAddr(d);
    }
}
