// solhint-disable
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import {IAllowanceTransfer, IPermit2} from "./IPermit2.sol";

library SignatureVerification {
    /// @notice Thrown when the passed in signature is not a valid length
    error InvalidSignatureLength();

    /// @notice Thrown when the recovered signer is equal to the zero address
    error InvalidSignature();

    /// @notice Thrown when the recovered signer does not equal the claimedSigner
    error InvalidSigner();

    /// @notice Thrown when the recovered contract signature is incorrect
    error InvalidContractSignature();

    bytes32 constant UPPER_BIT_MASK = (
        0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
    );

    function verify(
        bytes calldata signature,
        bytes32 hash,
        address claimedSigner
    ) internal view {
        bytes32 r;
        bytes32 s;
        uint8 v;

        if (claimedSigner.code.length == 0) {
            if (signature.length == 65) {
                (r, s) = abi.decode(signature, (bytes32, bytes32));
                v = uint8(signature[64]);
            } else if (signature.length == 64) {
                // EIP-2098
                bytes32 vs;
                (r, vs) = abi.decode(signature, (bytes32, bytes32));
                s = vs & UPPER_BIT_MASK;
                v = uint8(uint256(vs >> 255)) + 27;
            } else {
                revert InvalidSignatureLength();
            }
            address signer = ecrecover(hash, v, r, s);
            if (signer == address(0)) revert InvalidSignature();
            if (signer != claimedSigner) revert InvalidSigner();
        } else {
            bytes4 magicValue = IPermit2(claimedSigner).isValidSignature(
                hash,
                signature
            );
            if (magicValue != IPermit2.isValidSignature.selector)
                revert InvalidContractSignature();
        }
    }
}

library PermitHash {
    bytes32 public constant _PERMIT_DETAILS_TYPEHASH =
        keccak256(
            "PermitDetails(address token,uint160 amount,uint48 expiration,uint48 nonce)"
        );

    bytes32 public constant _PERMIT_SINGLE_TYPEHASH =
        keccak256(
            "PermitSingle(PermitDetails details,address spender,uint256 sigDeadline)PermitDetails(address token,uint160 amount,uint48 expiration,uint48 nonce)"
        );

    bytes32 public constant _PERMIT_BATCH_TYPEHASH =
        keccak256(
            "PermitBatch(PermitDetails[] details,address spender,uint256 sigDeadline)PermitDetails(address token,uint160 amount,uint48 expiration,uint48 nonce)"
        );

    bytes32 public constant _TOKEN_PERMISSIONS_TYPEHASH =
        keccak256("TokenPermissions(address token,uint256 amount)");

    bytes32 public constant _PERMIT_TRANSFER_FROM_TYPEHASH =
        keccak256(
            "PermitTransferFrom(TokenPermissions permitted,address spender,uint256 nonce,uint256 deadline)TokenPermissions(address token,uint256 amount)"
        );

    bytes32 public constant _PERMIT_BATCH_TRANSFER_FROM_TYPEHASH =
        keccak256(
            "PermitBatchTransferFrom(TokenPermissions[] permitted,address spender,uint256 nonce,uint256 deadline)TokenPermissions(address token,uint256 amount)"
        );

    string public constant _TOKEN_PERMISSIONS_TYPESTRING =
        "TokenPermissions(address token,uint256 amount)";

    string public constant _PERMIT_TRANSFER_FROM_WITNESS_TYPEHASH_STUB =
        "PermitWitnessTransferFrom(TokenPermissions permitted,address spender,uint256 nonce,uint256 deadline,";

    string public constant _PERMIT_BATCH_WITNESS_TRANSFER_FROM_TYPEHASH_STUB =
        "PermitBatchWitnessTransferFrom(TokenPermissions[] permitted,address spender,uint256 nonce,uint256 deadline,";

    function hash(
        IAllowanceTransfer.PermitSingle memory permitSingle
    ) internal pure returns (bytes32) {
        bytes32 permitHash = _hashPermitDetails(permitSingle.details);
        return
            keccak256(
                abi.encode(
                    _PERMIT_SINGLE_TYPEHASH,
                    permitHash,
                    permitSingle.spender,
                    permitSingle.sigDeadline
                )
            );
    }

    function hash(
        IAllowanceTransfer.PermitBatch memory permitBatch
    ) internal pure returns (bytes32) {
        uint256 numPermits = permitBatch.details.length;
        bytes32[] memory permitHashes = new bytes32[](numPermits);
        for (uint256 i = 0; i < numPermits; ++i) {
            permitHashes[i] = _hashPermitDetails(permitBatch.details[i]);
        }
        return
            keccak256(
                abi.encode(
                    _PERMIT_BATCH_TYPEHASH,
                    keccak256(abi.encodePacked(permitHashes)),
                    permitBatch.spender,
                    permitBatch.sigDeadline
                )
            );
    }

    function hash(
        IPermit2.PermitTransferFrom memory permit
    ) internal view returns (bytes32) {
        bytes32 tokenPermissionsHash = _hashTokenPermissions(permit.permitted);
        return
            keccak256(
                abi.encode(
                    _PERMIT_TRANSFER_FROM_TYPEHASH,
                    tokenPermissionsHash,
                    msg.sender,
                    permit.nonce,
                    permit.deadline
                )
            );
    }

    function hash(
        IPermit2.PermitBatchTransferFrom memory permit
    ) internal view returns (bytes32) {
        uint256 numPermitted = permit.permitted.length;
        bytes32[] memory tokenPermissionHashes = new bytes32[](numPermitted);

        for (uint256 i = 0; i < numPermitted; ++i) {
            tokenPermissionHashes[i] = _hashTokenPermissions(
                permit.permitted[i]
            );
        }

        return
            keccak256(
                abi.encode(
                    _PERMIT_BATCH_TRANSFER_FROM_TYPEHASH,
                    keccak256(abi.encodePacked(tokenPermissionHashes)),
                    msg.sender,
                    permit.nonce,
                    permit.deadline
                )
            );
    }

    function hashWithWitness(
        IPermit2.PermitTransferFrom memory permit,
        bytes32 witness,
        string calldata witnessTypeString
    ) internal view returns (bytes32) {
        bytes32 typeHash = keccak256(
            abi.encodePacked(
                _PERMIT_TRANSFER_FROM_WITNESS_TYPEHASH_STUB,
                witnessTypeString
            )
        );

        bytes32 tokenPermissionsHash = _hashTokenPermissions(permit.permitted);
        return
            keccak256(
                abi.encode(
                    typeHash,
                    tokenPermissionsHash,
                    msg.sender,
                    permit.nonce,
                    permit.deadline,
                    witness
                )
            );
    }

    function hashWithWitness(
        IPermit2.PermitBatchTransferFrom memory permit,
        bytes32 witness,
        string calldata witnessTypeString
    ) internal view returns (bytes32) {
        bytes32 typeHash = keccak256(
            abi.encodePacked(
                _PERMIT_BATCH_WITNESS_TRANSFER_FROM_TYPEHASH_STUB,
                witnessTypeString
            )
        );

        uint256 numPermitted = permit.permitted.length;
        bytes32[] memory tokenPermissionHashes = new bytes32[](numPermitted);

        for (uint256 i = 0; i < numPermitted; ++i) {
            tokenPermissionHashes[i] = _hashTokenPermissions(
                permit.permitted[i]
            );
        }

        return
            keccak256(
                abi.encode(
                    typeHash,
                    keccak256(abi.encodePacked(tokenPermissionHashes)),
                    msg.sender,
                    permit.nonce,
                    permit.deadline,
                    witness
                )
            );
    }

    function _hashPermitDetails(
        IAllowanceTransfer.PermitDetails memory details
    ) private pure returns (bytes32) {
        return keccak256(abi.encode(_PERMIT_DETAILS_TYPEHASH, details));
    }

    function _hashTokenPermissions(
        IPermit2.TokenPermissions memory permitted
    ) private pure returns (bytes32) {
        return keccak256(abi.encode(_TOKEN_PERMISSIONS_TYPEHASH, permitted));
    }
}

abstract contract Permit2 is IPermit2 {
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    bytes32 constant _HASHED_NAME = keccak256("Permit2");
    bytes32 constant _TYPE_HASH =
        keccak256(
            "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
        );
}
