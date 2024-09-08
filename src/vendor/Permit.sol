// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {I20} from "../Misc.sol";

library Permit {
    bytes32 internal constant PERMIT_TYPEHASH =
        keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );

    function getPermitHash(
        address token,
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline
    ) internal view returns (bytes32) {
        return
            getPermitHash(
                owner,
                spender,
                amount,
                I20(token).nonces(owner),
                deadline,
                I20(token).DOMAIN_SEPARATOR()
            );
    }

    function getPermitHash(
        address owner,
        address spender,
        uint256 value,
        uint256 nonce,
        uint256 deadline,
        bytes32 domainSeparator
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    domainSeparator,
                    keccak256(
                        abi.encode(
                            PERMIT_TYPEHASH,
                            owner,
                            spender,
                            value,
                            nonce,
                            deadline
                        )
                    )
                )
            );
    }
}
