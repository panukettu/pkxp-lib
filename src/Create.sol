// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {Solady} from "./vendor/Solady.sol";

library Create {
    using Solady for bytes32;
    function create(bytes memory ccode) internal returns (address location) {
        return create(ccode, msg.value);
    }

    function create(
        bytes memory ccode,
        uint256 value
    ) internal returns (address location) {
        assembly {
            location := create(value, add(ccode, 0x20), mload(ccode))
            if iszero(extcodesize(location)) {
                revert(0, 0)
            }
        }
    }

    function create2(
        bytes32 salt,
        bytes memory ccode
    ) internal returns (address location) {
        return create2(salt, ccode, msg.value);
    }

    function create2(
        bytes32 salt,
        bytes memory ccode,
        uint256 value
    ) internal returns (address location) {
        uint256 _salt = uint256(salt);
        assembly {
            location := create2(value, add(ccode, 0x20), mload(ccode), _salt)
            if iszero(extcodesize(location)) {
                revert(0, 0)
            }
        }
    }

    function create3(
        bytes32 salt,
        bytes memory ccode,
        uint256 value
    ) internal returns (address location) {
        return Solady.create3(salt, ccode, value);
    }

    function create3(
        bytes32 salt,
        bytes memory ccode
    ) internal returns (address location) {
        return create3(salt, ccode, msg.value);
    }

    function peek2(
        bytes32 salt,
        address _c2caller,
        bytes memory ccode
    ) internal pure returns (address) {
        return
            address(
                uint160(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                bytes1(0xff),
                                _c2caller,
                                salt,
                                keccak256(ccode)
                            )
                        )
                    )
                )
            );
    }

    function peek3(bytes32 salt) internal view returns (address) {
        return Solady.peek3(salt);
    }

    function deploy(
        bytes memory ccode,
        bytes32 salt
    ) internal returns (address loc) {
        return deploy(ccode, salt, msg.value);
    }

    function deploy(
        bytes memory ccode,
        bytes32 salt,
        uint256 value
    ) internal returns (address loc) {
        if (salt == 0) return create(ccode, value);
        return create3(salt, ccode, value);
    }
}
