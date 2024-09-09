// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Wallet, wm} from "./Wallet.s.sol";
import {IMVM} from "./IMVM.sol";
import {File, Files} from "./Files.s.sol";
import {Account} from "./Misc.sol";

abstract contract WmBase is Wallet {
    function connect(string memory network) internal virtual returns (uint256) {
        return connect(network, 0);
    }

    function connect(
        string memory network,
        uint256 bnr
    ) internal virtual returns (uint256) {
        return wm.fork(network, bnr);
    }

    function connect(
        string memory mEnvKey,
        string memory network,
        uint256 bnr
    ) internal virtual returns (uint256) {
        useMnemonic(mEnvKey);
        return connect(network, bnr);
    }

    function connect(
        string memory mEnvKey,
        string memory network
    ) internal virtual returns (uint256) {
        return connect(mEnvKey, network, 0);
    }

    function fileAt(string memory loc) internal pure returns (File memory) {
        return File(loc);
    }

    function write(bytes memory d) internal virtual returns (File memory) {
        return Files.write(d);
    }

    function write(
        string memory to,
        bytes memory d
    ) internal virtual returns (File memory) {
        return Files.write(to, d);
    }

    modifier fork(string memory id) virtual {
        wm.fork(id);
        _;
    }

    modifier forkAt(string memory id, uint256 b) virtual {
        wm.fork(id, b);
        _;
    }

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
        returns (IMVM.CallerMode, address, address)
    {
        return wm.clearCallers();
    }

    function makePayable(string memory lbl) internal returns (address payable) {
        return wm.makeAddr(lbl);
    }

    function makeAcc(string memory lbl) internal returns (Account memory) {
        return wm.makeAccount(lbl);
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
        return wm.sendFrom(useAddr(who));
    }

    function sendFrom(uint32 idx) internal virtual {
        sendFrom(getAddr(idx));
    }

    function sendFrom(string memory ksId) internal virtual {
        sendFrom(getAddr(ksId));
    }

    function sendFromKey(uint256 pk) internal virtual {
        sendFrom(usePk(pk));
    }

    function sendFromKey(string memory envKey) internal virtual {
        sendFrom(usePk(envKey));
    }
}
