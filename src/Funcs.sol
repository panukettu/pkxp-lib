// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

function Revert(bytes memory d) pure {
    assembly {
        revert(add(32, d), mload(d))
    }
}
