// solhint-disable reason-string
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {wm, Wm} from "./Wm.s.sol";
import {Account, Overflow, I20, map} from "./Misc.sol";
import {Revert} from "./Funcs.sol";
import {File, Files} from "./Files.s.sol";
import {Permit} from "./vendor/Permit.sol";

library Help {
    using Help for *;

    function toDec(
        uint256 v,
        uint8 _from,
        uint8 _to
    ) internal pure returns (uint256) {
        if (v == 0 || _from == _to) return v;

        if (_from < _to) {
            return v * (10 ** (_to - _from));
        }
        return v / (10 ** (_from - _to));
    }

    function toDec(
        uint256 amt,
        address from,
        address to
    ) internal view returns (uint256) {
        return amt.toDec(I20(from).decimals(), I20(to).decimals());
    }

    function toWad(uint256 v, uint8 _dec) internal pure returns (uint256) {
        return toDec(v, _dec, 18);
    }

    function toWad(uint256 v, address tAddr) internal view returns (uint256) {
        return v.toWad(I20(tAddr).decimals());
    }

    function fromWad(uint256 v, uint8 _dec) internal pure returns (uint256) {
        return v.toDec(18, _dec);
    }

    function fromWad(uint256 v, address tAddr) internal view returns (uint256) {
        return v.fromWad(I20(tAddr).decimals());
    }

    function one(address tAddr) internal view returns (uint256) {
        return toDec(1, 0, I20(tAddr).decimals());
    }

    function txt(address v) internal pure returns (string memory) {
        return wm.vm().toString(v);
    }

    function txt(bytes32 v) internal pure returns (string memory) {
        return wm.vm().toString(v);
    }

    function txt(uint256 v) internal pure returns (string memory) {
        return wm.vm().toString(v);
    }

    function txt(int256 v) internal pure returns (string memory) {
        return wm.vm().toString(v);
    }

    function txt(bytes memory v) internal pure returns (string memory) {
        return wm.vm().toString(v);
    }

    function str(uint256 v) internal pure returns (string memory s) {
        unchecked {
            if (v == 0) return "0";
            else {
                uint256 c1 = itoa32(v % 1e32);
                v /= 1e32;
                if (v == 0) s = string(abi.encode(c1));
                else {
                    uint256 c2 = itoa32(v % 1e32);
                    v /= 1e32;
                    if (v == 0) {
                        s = string(abi.encode(c2, c1));
                        c1 = c2;
                    } else {
                        uint256 c3 = itoa32(v);
                        s = string(abi.encode(c3, c2, c1));
                        c1 = c3;
                    }
                }
                uint256 z = 0;
                if (c1 >> 128 == 0x30303030303030303030303030303030) {
                    c1 <<= 128;
                    z += 16;
                }
                if (c1 >> 192 == 0x3030303030303030) {
                    c1 <<= 64;
                    z += 8;
                }
                if (c1 >> 224 == 0x30303030) {
                    c1 <<= 32;
                    z += 4;
                }
                if (c1 >> 240 == 0x3030) {
                    c1 <<= 16;
                    z += 2;
                }
                if (c1 >> 248 == 0x30) {
                    z += 1;
                }
                assembly {
                    let l := mload(s)
                    s := add(s, z)
                    mstore(s, sub(l, z))
                }
            }
        }
    }

    function str(bytes32 v) internal pure returns (string memory) {
        return v.bts().str();
    }

    function str(bytes memory v) internal pure returns (string memory res) {
        for (uint256 i; i < v.length; i++) {
            if (v[i] != 0) res = string.concat(res, string(bytes.concat(v[i])));
        }
    }

    function txt(bytes32 v, uint256 len) internal pure returns (string memory) {
        return txt(bytes.concat(v), len);
    }

    function txt(
        bytes memory v,
        uint256 len
    ) internal pure returns (string memory) {
        bytes memory p0;
        assembly {
            p0 := v
            mstore(p0, len)
        }
        return p0.txt();
    }

    function bts(bytes32 v) internal pure returns (bytes memory) {
        return bytes.concat(v);
    }

    function toAddr(bytes32 b) internal pure returns (address) {
        return address(uint160(uint256(b)));
    }

    function bts(string memory s) internal pure returns (bytes memory) {
        return wm.vm().parseBytes(s);
    }

    function dstr(uint256 v) internal pure returns (string memory) {
        return dstr(v, 18);
    }

    function dstr(
        uint256 v,
        uint256 dec
    ) internal pure returns (string memory) {
        uint256 ds = 10 ** dec;

        bytes memory d = bytes(str(v % ds));
        (d = bytes.concat(bytes(str(10 ** (dec - d.length))), d))[0] = 0;

        for (uint256 i = d.length; --i > 2; d[i] = 0) if (d[i] != "0") break;

        return string.concat(str(v / ds), ".", str(d));
    }

    function split(
        string memory s,
        string memory d
    ) internal pure returns (string[] memory) {
        return wm.vm().split(s, d);
    }

    function split(string memory s) internal pure returns (string[] memory) {
        return s.split(" ");
    }

    function split(
        string memory s,
        uint256 idx
    ) internal pure returns (string[2] memory) {
        bytes memory b = bytes(s);
        return [string(b.slice(0, idx)), string(b.slice(idx))];
    }

    function join(string[] memory s) internal pure returns (string memory) {
        return join(s, "");
    }

    function join(
        string[] memory s,
        string memory d
    ) internal pure returns (string memory res) {
        for (uint256 i; i < s.length; i++) {
            res = string.concat(res, s[i], d);
        }
    }

    function indexOf(
        string memory s,
        string memory d
    ) internal pure returns (uint256) {
        return wm.vm().indexOf(s, d);
    }

    function cut(
        string memory s,
        string memory d
    ) internal pure returns (string[2] memory) {
        return s.split(s.indexOf(d));
    }

    function slice(
        string[] memory s,
        uint256 f,
        uint256 t
    ) internal pure returns (string[] memory res) {
        res = new string[](t - f);
        while (f < t) res[f++] = s[f];
    }

    function slice(
        string[] memory s,
        uint256 f
    ) internal pure returns (string[] memory res) {
        return slice(s, f, s.length);
    }

    function slice(
        bytes memory b,
        uint256 f
    ) internal pure returns (bytes memory) {
        return slice(b, f, b.length - f);
    }

    function slice(
        bytes memory v,
        uint256 f,
        uint256 t
    ) internal pure returns (bytes memory res) {
        if (v.length < f + t) revert Overflow(v.length, f + t);
        assembly {
            switch iszero(t)
            case 0 {
                res := mload(0x40)
                let lengthmod := and(t, 31)
                let mc := add(add(res, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, t)
                for {
                    let _c := add(
                        add(add(v, lengthmod), mul(0x20, iszero(lengthmod))),
                        f
                    )
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    _c := add(_c, 0x20)
                } {
                    mstore(mc, mload(_c))
                }

                mstore(res, t)

                mstore(0x40, and(add(mc, 31), not(31)))
            }
            default {
                res := mload(0x40)
                mstore(res, 0)

                mstore(0x40, add(res, 0x20))
            }
        }
    }

    function padLeft(
        string memory val,
        uint256 len,
        string memory char
    ) internal pure returns (string memory result) {
        result = val;

        uint256 strLen = bytes(val).length;
        if (strLen >= len) return result;

        for (uint256 i = strLen; i < len; i++) {
            result = char.concat(result);
        }
    }

    function padRight(
        string memory val,
        uint256 len,
        string memory char
    ) internal pure returns (string memory result) {
        result = val;

        uint256 strLen = bytes(val).length;
        if (strLen >= len) return result;

        for (uint256 i = strLen; i < len; i++) {
            result = result.concat(char);
        }
    }

    function equals(
        string memory a,
        string memory b
    ) internal pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    function exists(string memory a) internal pure returns (bool) {
        return bytes(a).length != 0;
    }

    function space(
        string memory a,
        string memory b
    ) internal pure returns (string memory) {
        return string.concat(a, " ", b);
    }

    function concat(
        string memory a,
        string memory b
    ) internal pure returns (string memory) {
        return string.concat(a, b);
    }

    function concat(
        bytes memory a,
        bytes memory b
    ) internal pure returns (bytes memory) {
        return bytes.concat(a, b);
    }

    function split(
        bytes32 val,
        uint256 bit
    ) internal pure returns (bytes memory res) {
        assembly {
            mstore(res, 64)
            mstore(add(res, 32), shr(sub(256, bit), val))
            mstore(add(res, 64), shr(bit, shl(bit, val)))
        }
    }

    uint256 internal constant PCT_F = 1e4;
    uint256 internal constant HALF_PCT_F = 0.5e4;

    function pmul(uint256 v, uint256 p) internal pure returns (uint256 result) {
        assembly {
            if iszero(
                or(iszero(p), iszero(gt(v, div(sub(not(0), HALF_PCT_F), p))))
            ) {
                revert(0, 0)
            }

            result := div(add(mul(v, p), HALF_PCT_F), PCT_F)
        }
    }

    function pdiv(uint256 v, uint256 p) internal pure returns (uint256 result) {
        assembly {
            if or(
                iszero(p),
                iszero(iszero(gt(v, div(sub(not(0), div(p, 2)), PCT_F))))
            ) {
                revert(0, 0)
            }

            result := div(add(mul(v, PCT_F), div(p, 2)), p)
        }
    }

    uint256 internal constant WAD = 1e18;
    uint256 internal constant HALF_WAD = 0.5e18;

    function wmul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        assembly {
            if iszero(
                or(iszero(b), iszero(gt(a, div(sub(not(0), HALF_WAD), b))))
            ) {
                revert(0, 0)
            }

            c := div(add(mul(a, b), HALF_WAD), WAD)
        }
    }

    function wdiv(uint256 a, uint256 b) internal pure returns (uint256 c) {
        assembly {
            if or(
                iszero(b),
                iszero(iszero(gt(a, div(sub(not(0), div(b, 2)), WAD))))
            ) {
                revert(0, 0)
            }

            c := div(add(mul(a, WAD), div(b, 2)), b)
        }
    }

    function abs(int256 x) internal pure returns (uint256) {
        return uint256(x > 0 ? x : -x);
    }

    function neg(int256 x) internal pure returns (int256) {
        return x * (-1);
    }

    function neg(uint256 x) internal pure returns (int256) {
        return toInt(x) * (-1);
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256) {
        return (x > y ? x : y);
    }

    function max(int256 x, int256 y) internal pure returns (int256) {
        return (x > y ? x : y);
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256) {
        return (x < y ? x : y);
    }

    function min(int256 x, int256 y) internal pure returns (int256) {
        return (x < y ? x : y);
    }

    function toInt(uint256 x) internal pure returns (int256) {
        assert(x <= uint256(type(int256).max));
        return int256(x);
    }

    // @author Uniswap
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function save(Account memory a) internal returns (File memory) {
        return Files.write(abi.encode(a), a.addr.txt());
    }

    function load(address a) internal returns (Account memory) {
        return abi.decode(File(Files.defaultPath(a.txt())).read(), (Account));
    }

    /* ------------------------------------ . ----------------------------------- */

    function eq(
        bytes memory a,
        bytes memory b,
        string memory lbl
    ) internal pure returns (Wm) {
        wm.vcall(abi.encode(a, b, lbl), IS_EQ_B);
        return wm;
    }
    function eq(
        bytes32 a,
        bytes32 b,
        string memory lbl
    ) internal pure returns (Wm) {
        wm.vcall(abi.encode(bytes.concat(a), bytes.concat(b), lbl), IS_EQ_B);
        return wm;
    }

    function eq(
        string memory a,
        string memory b,
        string memory lbl
    ) internal pure returns (Wm) {
        wm.vcall(abi.encode(a, b, lbl), IS_EQ_STR);
        return wm;
    }

    function eq(
        address a,
        address b,
        string memory lbl
    ) internal pure returns (Wm) {
        return eq(txt(a), txt(b), lbl);
    }

    function eq(
        uint256 a,
        uint256 b,
        string memory lbl
    ) internal pure returns (Wm) {
        return eq(str(a), str(b), lbl);
    }

    function eq(
        int256 a,
        int256 b,
        string memory lbl
    ) internal pure returns (Wm) {
        return eq(txt(a), txt(b), lbl);
    }

    function notEq(
        address a,
        address b,
        string memory lbl
    ) internal pure returns (Wm) {
        return notEq(txt(a), txt(b), lbl);
    }

    function notEq(
        uint256 a,
        uint256 b,
        string memory lbl
    ) internal pure returns (Wm) {
        return notEq(txt(a), txt(b), lbl);
    }

    function notEq(
        int256 a,
        int256 b,
        string memory lbl
    ) internal pure returns (Wm) {
        return notEq(txt(a), txt(b), lbl);
    }

    function notEq(
        bytes memory a,
        bytes memory b,
        string memory lbl
    ) internal pure returns (Wm) {
        wm.vcall(abi.encode(a, b, lbl), NOT_EQ_B);
        return wm;
    }

    function notEq(
        string memory a,
        string memory b,
        string memory lbl
    ) internal pure returns (Wm) {
        wm.vcall(abi.encode(a, b, lbl), NOT_EQ_STR);
        return wm;
    }

    /* ------------------------------------ . ----------------------------------- */

    function clg(string memory v) internal pure returns (Wm) {
        return wm.clg(v);
    }

    function blg(bytes memory v) internal pure returns (Wm) {
        return wm.blg(v);
    }

    function clg(
        string memory v,
        string memory lbl
    ) internal pure returns (Wm) {
        return clg(v.space(lbl));
    }

    function clg(address v, string memory lbl) internal pure returns (Wm) {
        return clg(txt(v), lbl);
    }

    function clg(uint256 v, string memory lbl) internal pure returns (Wm) {
        return clg(txt(v), lbl);
    }

    function blg(bytes32 v, string memory lbl) internal pure returns (Wm) {
        return blg(v.bts(), lbl);
    }

    function blg(bytes memory v, string memory lbl) internal pure returns (Wm) {
        return clg(txt(v), lbl);
    }

    function dlg(uint256 v, string memory lbl) internal pure {
        dlg(v, lbl, 18);
    }

    function dlg(uint256 v, string memory lbl, uint256 d) internal pure {
        clg(lbl, v.dstr(d));
    }

    function sr(Wm) internal pure returns (Wm) {
        return
            clg(string("**************************************************"));
    }

    function clg(File[] memory files) internal returns (File[] memory) {
        map(files, Files.clg);
        return files;
    }

    function explorer() internal pure returns (string memory) {
        return _purify(_explorer)();
    }

    function href(address addr) internal pure returns (string memory) {
        return explorer().concat("/address/").concat(addr.txt());
    }

    function href(bytes32 txHash) internal pure returns (string memory) {
        return explorer().concat("/tx/").concat(txHash.str());
    }

    function href(uint256 bnr) internal pure returns (string memory) {
        return explorer().concat("/block/").concat(bnr.str());
    }

    function href20(address addr) internal pure returns (string memory) {
        return string.concat(explorer(), "/token/", addr.txt());
    }

    function dcall(
        address to,
        bytes memory data
    ) internal returns (bytes memory) {
        (bool success, bytes memory ret) = to.delegatecall(data);
        if (!success) Revert(ret);

        return ret;
    }

    function scall(
        address to,
        bytes memory data
    ) internal view returns (bytes memory) {
        (bool success, bytes memory ret) = to.staticcall(data);
        if (!success) Revert(ret);

        return ret;
    }

    function fcall(
        address to,
        bytes memory data
    ) internal returns (bytes memory) {
        (bool success, bytes memory ret) = to.call(data);
        if (!success) Revert(ret);

        return ret;
    }

    /* ------------------------------------ . ----------------------------------- */

    function _explorer() private view returns (string memory res) {
        res = "arbiscan.io";
        if (block.chainid == 1) res = "etherscan.io";
        if (block.chainid == 11155111) res = "sepolia.etherscan.io";
        if (block.chainid == 137) res = "polygonscan.com";
        if (block.chainid == 1101) res = "zkevm.polygonscan.com";
        if (block.chainid == 1284) res = "moonscan.io";
        if (block.chainid == 56) res = "bscscan.com";
        if (block.chainid == 204) res = "opbnb.bscscan.com";
        if (block.chainid == 8453) res = "basescan.org";
        if (block.chainid == 43114) res = "snowtrace.io";
        if (block.chainid == 250) res = "ftmscan.com";
        if (block.chainid == 10) res = "optimistic.etherscan.io";
        if (block.chainid == 100) res = "gnosisscan.io";
        return string.concat("https://", res);
    }

    function trim(bytes memory s) internal pure returns (string memory) {
        return trim(s.txt());
    }

    function trim(string memory s) internal pure returns (string memory) {
        return wm.vm().trim(s);
    }

    function _purify(
        function() view returns (string memory) fn
    ) private pure returns (function() pure returns (string memory) out) {
        assembly {
            out := fn
        }
    }

    bytes4 private constant IS_EQ_STR = 0x36f656d8;
    bytes4 private constant IS_EQ_B = 0xe24fed00;
    bytes4 private constant NOT_EQ_STR = 0x78bdcea7;
    bytes4 private constant NOT_EQ_B = 0x9507540e;
    bytes4 private constant IS_TRUE = 0xe24fed00;

    function itoa32(uint256 x) private pure returns (uint256 y) {
        unchecked {
            require(x < 1e32);
            y = 0x3030303030303030303030303030303030303030303030303030303030303030;
            y += x % 10;
            x /= 10;
            y += x % 10 << 8;
            x /= 10;
            y += x % 10 << 16;
            x /= 10;
            y += x % 10 << 24;
            x /= 10;
            y += x % 10 << 32;
            x /= 10;
            y += x % 10 << 40;
            x /= 10;
            y += x % 10 << 48;
            x /= 10;
            y += x % 10 << 56;
            x /= 10;
            y += x % 10 << 64;
            x /= 10;
            y += x % 10 << 72;
            x /= 10;
            y += x % 10 << 80;
            x /= 10;
            y += x % 10 << 88;
            x /= 10;
            y += x % 10 << 96;
            x /= 10;
            y += x % 10 << 104;
            x /= 10;
            y += x % 10 << 112;
            x /= 10;
            y += x % 10 << 120;
            x /= 10;
            y += x % 10 << 128;
            x /= 10;
            y += x % 10 << 136;
            x /= 10;
            y += x % 10 << 144;
            x /= 10;
            y += x % 10 << 152;
            x /= 10;
            y += x % 10 << 160;
            x /= 10;
            y += x % 10 << 168;
            x /= 10;
            y += x % 10 << 176;
            x /= 10;
            y += x % 10 << 184;
            x /= 10;
            y += x % 10 << 192;
            x /= 10;
            y += x % 10 << 200;
            x /= 10;
            y += x % 10 << 208;
            x /= 10;
            y += x % 10 << 216;
            x /= 10;
            y += x % 10 << 224;
            x /= 10;
            y += x % 10 << 232;
            x /= 10;
            y += x % 10 << 240;
            x /= 10;
            y += x % 10 << 248;
        }
    }

    /* ------------------------------------ . ----------------------------------- */

    function getPermit(
        address token,
        string memory ksId,
        address spender,
        uint256 amount,
        uint256 deadline
    ) internal returns (uint8, bytes32, bytes32) {
        return
            wm.sign(
                ksId,
                Permit.getPermitHash(
                    token,
                    wm.getAddr(ksId),
                    spender,
                    amount,
                    deadline
                )
            );
    }

    function getPermit(
        address token,
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline
    ) internal view returns (uint8, bytes32, bytes32) {
        return
            wm.vm().sign(
                owner,
                Permit.getPermitHash(token, owner, spender, amount, deadline)
            );
    }
}
