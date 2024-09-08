// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Solady} from "./vendor/Solady.sol";

using Solady for bytes32;

function create(bytes memory _code, bytes32 salt) returns (address loc) {
    if (salt == 0) return create(_code);
    return create(salt, _code);
}

function create(bytes memory _code) returns (address loc) {
    assembly {
        loc := create(0, add(_code, 0x20), mload(_code))
    }
}

function create(bytes32 salt, bytes memory ccode) returns (address) {
    return salt.create3(ccode, msg.value);
}

function Revert(bytes memory d) pure {
    assembly {
        revert(add(32, d), mload(d))
    }
}
