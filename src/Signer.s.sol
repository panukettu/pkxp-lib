// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Wallet, wm} from "./Wallet.s.sol";
import {IMVM} from "./IMVM.sol";

abstract contract Signer is Wallet {
    modifier sendFromAddr(address who) {
        sendFrom(who);
        _;
        wm.clearCallers();
    }

    modifier sendFromPk(string memory envKey) {
        sendFromKey(envKey);
        _;
        wm.clearCallers();
    }

    modifier sendFromKs(string memory ksId) {
        sendFrom(ksId);
        _;
        wm.clearCallers();
    }

    modifier sendFromIdx(uint32 idx) {
        sendFrom(idx);
        _;
        wm.clearCallers();
    }

    modifier sendFrom$(address who) {
        (IMVM.CallerMode m, address s, address o) = sendFrom(who);
        _;
        wm.restore(m, s, o);
    }

    modifier pranked(address who) {
        prank(who);
        _;
        wm.clearCallers();
    }

    modifier prankedKs(string memory ksId) {
        prank(ksId);
        _;
        wm.clearCallers();
    }

    modifier prankedIdx(uint32 idx) {
        prank(idx);
        _;
        wm.clearCallers();
    }

    modifier prankedKey(string memory envKey) {
        prankKey(envKey);
        _;
        wm.clearCallers();
    }

    modifier pranked$(address who) {
        (IMVM.CallerMode m, address s, address o) = prank(who);
        _;
        wm.restore(m, s, o);
    }

    function clearCallers()
        internal
        returns (IMVM.CallerMode m, address s, address o)
    {
        return wm.clearCallers();
    }

    function prank(
        address who
    ) internal virtual returns (IMVM.CallerMode, address, address) {
        return wm.pranked(useAddr(who), who);
    }

    function prank(uint32 idx) internal virtual {
        prank(getAddr(idx));
    }

    function prank(string memory ksId) internal virtual {
        prank(getAddr(ksId));
    }

    function prankKey(string memory envKey) internal virtual {
        prank(getAddrPk(envKey));
    }

    function sendFrom(
        address who
    ) internal virtual returns (IMVM.CallerMode, address, address) {
        return wm.signer(useAddr(who));
    }

    function sendFrom(uint32 idx) internal virtual {
        sendFrom(getAddr(idx));
    }

    function sendFrom(string memory ksId) internal virtual {
        sendFrom(getAddr(ksId));
    }

    function sendFromKey(uint256 pk) internal virtual {
        sendFrom(getAddrPk(pk));
    }

    function sendFromKey(string memory envKey) internal virtual {
        sendFrom(getAddrPk(envKey));
    }
}
