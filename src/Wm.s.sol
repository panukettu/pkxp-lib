// solhint-disable
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IMVM} from "./IMVM.sol";
import {clgAddr, DEFAULT_MNEMONIC_ENV, DEFAULT_PK_ENV, DEFAULT_RPC_ENV, vmAddr, Account} from "./Misc.sol";

import {Revert} from "./Funcs.sol";

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

    function vm(Wm w) internal pure returns (IMVM) {
        return IMVM(Wm.unwrap(w));
    }

    function getTime(Wm w) internal view returns (uint256) {
        return w.vm().unixTime() / 1000;
    }

    function syncTime(Wm w) internal {
        return w.vm().warp(w.getTime());
    }

    function id4(Wm w) internal returns (bytes4 b) {
        w.store().lastId = (b = bytes4(w.id()));
    }

    function id(Wm w) internal view returns (bytes32) {
        return bytes32(w.vm().randomUint());
    }

    function getPk(
        Wm w,
        string memory pkEnvKey
    ) internal view returns (uint256) {
        return w.vm().parseUint(w.getEnv(pkEnvKey, DEFAULT_PK_ENV));
    }

    function getPkAt(
        Wm w,
        string memory mEnvKey,
        uint32 idx
    ) internal view returns (uint256) {
        return w.vm().deriveKey(w.getEnv(mEnvKey, DEFAULT_MNEMONIC_ENV), idx);
    }

    function getPkAt(Wm w, uint32 idx) internal view returns (uint256) {
        return w.getPkAt(w.store().mEnv, idx);
    }

    function getAddr(
        Wm w,
        string memory mEnvKey,
        uint32 idx
    ) internal returns (address payable) {
        return w.getAddrPk(w.getPkAt(mEnvKey, idx));
    }

    function getAddr(Wm w, uint32 idx) internal returns (address payable) {
        return w.getAddr(w.store().mEnv, idx);
    }

    function getAddr(
        Wm w,
        string memory ksId
    ) internal returns (address payable) {
        // todo;
    }

    function getAddrPk(Wm w, uint256 pk) internal returns (address payable) {
        return payable(w.vm().rememberKey(pk));
    }

    function getAddrPk(
        Wm w,
        string memory pkEnvKey
    ) internal returns (address payable) {
        return w.getAddrPk(w.getPk(pkEnvKey));
    }

    function getEnv(
        Wm w,
        string memory _envKey,
        string memory _envKeyFallback
    ) internal view returns (string memory r) {
        r = w.vm().envOr(_envKey, "");
        if (bytes(r).length == 0) {
            r = w.vm().envOr(_envKeyFallback, "");
        }
        if (bytes(r).length == 0) {
            revert("no env");
        }
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
        return w.vm().createSelectFork(w.getRPC(idOrURL), bnr);
    }

    function makeAccount(
        Wm w,
        string memory lbl
    ) internal returns (Account memory r) {
        r.pk = uint256(keccak256(abi.encodePacked(lbl)));
        w.vm().label((r.addr = w.getAddrPk(r.pk)), (r.label = lbl));
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

    function signer(
        Wm w,
        address s
    ) internal returns (IMVM.CallerMode m_, address s_, address o_) {
        (m_, s_, o_) = w.clearCallers();
        w.vm().startBroadcast(s);
    }

    function msgSender(Wm w) internal view returns (address s_) {
        (, s_, ) = w.vm().readCallers();
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
    ) internal returns (IMVM.CallerMode) {
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

        return _m;
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

    function clg(Wm, string memory _s) internal pure {
        clg(abi.encodeWithSelector(0x41304fac, _s));
    }

    function blg(Wm, bytes memory _b) internal pure {
        clg(abi.encodeWithSelector(0x0be77f56, _b));
    }

    function nl(Wm, string memory _s) internal pure returns (string memory) {
        return string.concat("\n    ", _s);
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
        return w.getAddrPk(w.store().pkEnv = envKey);
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

    function clg(bytes memory _p) private pure {
        _purify(_clg)(_p);
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
