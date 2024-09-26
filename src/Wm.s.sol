// solhint-disable
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IMVM} from "./IMVM.sol";
import {clgAddr, DEFAULT_MNEMONIC_ENV, getFFIPath, GPG_PASSWORD_ENV, DEFAULT_PK_ENV, DEFAULT_RPC_ENV, vmAddr, Account} from "./Misc.sol";

import {Revert} from "./Funcs.sol";
import {Permit} from "./vendor/Permit.sol";
import {Time, Times} from "./Time.sol";

Wm constant wm = Wm.wrap(vmAddr);

type Wm is address;
using LibWm for Wm global;

library LibWm {
    struct Store {
        bytes4 lastId;
        string[] files;
        string mEnv;
        string pkEnv;
    }

    function ffi(Wm w, string memory cmd) internal returns (bytes memory) {
        return w.ffi(w.vm().split(cmd, " "));
    }

    function ffi(Wm w, string[] memory args) internal returns (bytes memory) {
        IMVM.FFIResult memory res = w.vm().tryFfi(args);
        if (res.exitCode != 0) {
            if (res.stderr.length != 0) Revert(res.stderr);
            else Revert(res.stdout);
        }
        return res.stdout;
    }

    function getEnv(
        Wm w,
        string memory envKey,
        string memory envKeyFallback
    ) internal view returns (string memory r) {
        r = w.vm().envOr(envKey, "");
        if (bytes(r).length == 0) return w.vm().envString(envKeyFallback);
    }

    function vm(Wm w) internal pure returns (IMVM) {
        return IMVM(Wm.unwrap(w));
    }

    function readPk(
        Wm w,
        string memory pkEnvKey
    ) private view returns (uint256) {
        return w.vm().parseUint(w.getEnv(pkEnvKey, DEFAULT_PK_ENV));
    }

    function readPkAt(
        Wm w,
        string memory mEnvKey,
        uint32 idx
    ) private view returns (uint256) {
        return w.vm().deriveKey(w.getEnv(mEnvKey, DEFAULT_MNEMONIC_ENV), idx);
    }

    function readPkAt(Wm w, uint32 idx) private view returns (uint256) {
        return readPkAt(w, w.store().mEnv, idx);
    }

    function getAddr(
        Wm w,
        string memory mEnvKey,
        uint32 idx
    ) internal returns (address payable) {
        return w.usePk(readPkAt(w, mEnvKey, idx));
    }

    function getAddr(Wm w, uint32 idx) internal returns (address payable) {
        return w.getAddr(w.store().mEnv, idx);
    }

    function getAddr(
        Wm w,
        string memory ksId
    ) internal returns (address payable) {
        return w.usePk(getPk(w, ksId));
    }

    function getPk(Wm w, string memory ksId) internal returns (uint256) {
        string[] memory cmd = new string[](3);
        cmd[0] = getFFIPath("ks-key.ffi.sh");
        cmd[1] = ksId;
        cmd[2] = w.vm().envOr(GPG_PASSWORD_ENV, "");
        return uint256(bytes32(wm.ffi(cmd)));
    }

    function usePk(Wm w, uint256 pk) internal returns (address payable) {
        return payable(w.vm().rememberKey(pk));
    }

    function usePk(
        Wm w,
        string memory pkEnvKey
    ) internal returns (address payable) {
        return w.usePk(readPk(w, pkEnvKey));
    }

    function getTime(Wm w) internal view returns (uint256) {
        return w.vm().unixTime() / 1000;
    }

    function getApproxDate(Wm w) internal view returns (Time memory) {
        return Times.toApproxDate(w.getTime());
    }

    function getRelativeTime(
        Wm w,
        Time memory past
    ) internal view returns (Time memory) {
        return Times.getRelativeTime(past, w.getApproxDate());
    }

    function syncTime(Wm w) internal returns (Wm) {
        w.vm().warp(w.getTime());
        return w;
    }

    function fileId(Wm w) internal returns (bytes4 b) {
        w.store().lastId = (b = bytes4(w.id()));
    }

    function id(Wm w) internal view returns (bytes32) {
        return bytes32(w.vm().randomUint());
    }

    function getRPC(
        Wm w,
        string memory idOrURL
    ) internal view returns (string memory url) {
        try w.vm().rpcUrl(idOrURL) returns (string memory res) {
            return res;
        } catch {
            return w.getEnv(idOrURL, DEFAULT_RPC_ENV);
        }
    }

    function rpc(
        Wm w,
        string memory m,
        string memory p
    ) internal returns (bytes memory) {
        return w.vm().rpc(m, string.concat("[", p, "]"));
    }

    function getNextAddr(
        Wm w,
        address deployer
    ) internal view returns (address payable) {
        return
            payable(
                w.vm().computeCreateAddress(deployer, w.vm().getNonce(deployer))
            );
    }

    function fork(Wm w, string memory idOrURL) internal view returns (uint256) {
        return w.fork(idOrURL, 0);
    }

    function fork(
        Wm w,
        string memory idOrURL,
        uint256 bnr
    ) internal view returns (uint256) {
        string memory _rpc = w.getRPC(idOrURL);
        if (bnr == 0) return w.vm().createSelectFork(_rpc);
        return w.vm().createSelectFork(_rpc, bnr);
    }

    function makeAccount(
        Wm w,
        string memory lbl
    ) internal returns (Account memory r) {
        r.pk = uint256(keccak256(abi.encodePacked(lbl)));
        w.vm().label((r.addr = w.usePk(r.pk)), (r.label = lbl));
    }

    function makeAddr(
        Wm w,
        string memory lbl
    ) internal returns (address payable) {
        return makeAccount(w, lbl).addr;
    }

    function pranked(
        Wm w,
        string memory mEnvKey,
        uint32 idx
    ) internal returns (IMVM.CallerMode, address, address) {
        return w.pranked(w.getAddr(mEnvKey, idx));
    }

    function pranked(
        Wm w,
        address s
    ) internal returns (IMVM.CallerMode, address, address) {
        return w.pranked(s, s);
    }

    function pranked(
        Wm w,
        address s,
        address o
    ) internal returns (IMVM.CallerMode m_, address s_, address o_) {
        (m_, s_, o_) = w.clearCallers();
        w.vm().startPrank(s, o);
    }

    function sendFrom(
        Wm w,
        address s
    ) internal returns (IMVM.CallerMode m_, address s_, address o_) {
        (m_, s_, o_) = w.clearCallers();
        w.vm().startBroadcast(s);
    }

    function sign(
        Wm w,
        string memory ksId,
        bytes32 d
    ) internal returns (uint8, bytes32, bytes32) {
        return w.vm().sign(getPk(w, ksId), d);
    }

    function sign(
        Wm w,
        uint32 idx,
        bytes32 d
    ) internal returns (uint8, bytes32, bytes32) {
        return w.vm().sign(getAddr(w, idx), d);
    }

    function msgSender(Wm w) internal view returns (address sender) {
        (, sender, ) = w.vm().readCallers();
    }

    function clearCallers(
        Wm w
    ) internal returns (IMVM.CallerMode m_, address s_, address o_) {
        (m_, s_, o_) = w.vm().readCallers();

        if (
            m_ == IMVM.CallerMode.Prank || m_ == IMVM.CallerMode.RecurrentPrank
        ) {
            w.vm().stopPrank();
        }

        if (
            m_ == IMVM.CallerMode.Broadcast ||
            m_ == IMVM.CallerMode.RecurrentBroadcast
        ) {
            w.vm().stopBroadcast();
        }
    }

    function restore(
        Wm w,
        IMVM.CallerMode _m,
        address _ss,
        address _so
    ) internal returns (Wm) {
        w.clearCallers();

        if (_m == IMVM.CallerMode.Broadcast) w.vm().broadcast(_ss);

        if (_m == IMVM.CallerMode.RecurrentBroadcast)
            w.vm().startBroadcast(_ss);

        if (_m == IMVM.CallerMode.Prank) {
            _ss == _so ? w.vm().prank(_ss, _so) : w.vm().prank(_ss);
        }

        if (_m == IMVM.CallerMode.RecurrentPrank) {
            _ss == _so ? w.vm().startPrank(_ss, _so) : w.vm().startPrank(_ss);
        }

        return w;
    }

    function vcall(
        Wm t,
        bytes4 s,
        bytes memory d
    ) internal returns (bytes memory) {
        return t.vcall(Wm.unwrap(t), s, d);
    }

    function vcall(
        Wm t,
        bytes memory d,
        bytes4 s
    ) internal pure returns (bytes memory) {
        return _purify(_staticcall)(t, Wm.unwrap(t), s, d);
    }

    function vcall(
        Wm,
        address t,
        bytes4 s,
        bytes memory d
    ) internal returns (bytes memory) {
        (bool success, bytes memory retData) = t.call(abi.encodePacked(s, d));

        if (success) return retData;

        Revert(retData);
    }

    /* ------------------------------------ . ----------------------------------- */

    function clg(Wm, string memory _s) internal pure returns (Wm) {
        return clg(abi.encodeWithSelector(0x41304fac, _s));
    }

    function blg(Wm, bytes memory _b) internal pure returns (Wm) {
        return clg(abi.encodeWithSelector(0x0be77f56, _b));
    }

    function nl(Wm, string memory s) internal pure returns (string memory) {
        return string.concat("\n    ", s);
    }

    function hasVM(Wm w) internal pure returns (bool) {
        return _purify(_hasVM)(w);
    }

    function store(Wm w) internal pure returns (Store storage s) {
        onlyVm(w);
        assembly {
            s.slot := 0x35b9089429a720996a27ffd842a4c293f759fc6856f1c672c8e2b5040a1eddfe
        }
    }

    function setMnemonic(
        Wm w,
        string memory envKey
    ) internal returns (address payable) {
        return w.getAddr(w.store().mEnv = envKey, 0);
    }

    function setPk(
        Wm w,
        string memory envKey
    ) internal returns (address payable) {
        return w.usePk(w.store().pkEnv = envKey);
    }

    function setWallets(
        Wm w,
        string memory mEnvKey,
        string memory pkEnvKey
    ) internal returns (address payable, address payable) {
        return (w.setMnemonic(mEnvKey), w.setPk(pkEnvKey));
    }

    /* ------------------------------------ . ----------------------------------- */

    function _staticcall(
        Wm,
        address t,
        bytes4 sel,
        bytes memory data
    ) private view returns (bytes memory) {
        (bool success, bytes memory retData) = t.staticcall(
            abi.encodePacked(sel, data)
        );

        if (success) return retData;

        Revert(retData);
    }

    function clg(bytes memory _p) private pure returns (Wm) {
        _purify(_clg)(_p);
        return wm;
    }

    function _clg(bytes memory _b) private view {
        uint256 len = _b.length;
        /// @solidity memory-safe-assembly
        assembly {
            let start := add(_b, 32)
            let r := staticcall(gas(), clgAddr, start, len, 0, 0)
        }
    }

    function onlyVm(Wm w) private pure {
        if (!hasVM(w)) revert("no hevm");
    }

    function _hasVM(Wm w) private view returns (bool) {
        address t = Wm.unwrap(w);
        uint256 len = 0;
        assembly {
            len := extcodesize(t)
        }
        return len > 0;
    }

    function _purify(
        function(bytes memory) fn
    ) private pure returns (function(bytes memory) pure out) {
        assembly {
            out := fn
        }
    }

    function _purify(
        function(Wm) returns (bool) fn
    ) private pure returns (function(Wm) pure returns (bool) out) {
        assembly {
            out := fn
        }
    }

    function _purify(
        function(Wm, address, bytes4, bytes memory) returns (bytes memory) fn
    )
        private
        pure
        returns (
            function(Wm, address, bytes4, bytes memory)
                pure
                returns (bytes memory) out
        )
    {
        assembly {
            out := fn
        }
    }
}
