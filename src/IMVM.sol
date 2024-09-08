// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @notice workaround
/// @notice tldr: big project + forge-std + solcjs (in vscode extension) = :[[
interface IMVM {
    function rememberKey(uint256) external returns (address);
    function deriveKey(string calldata, uint32) external pure returns (uint256);
    function envOr(
        string calldata,
        string calldata
    ) external view returns (string memory);
    function envOr(string calldata, uint256) external view returns (uint256);
    function envOr(string calldata, address) external view returns (address);
    function envString(string calldata n) external view returns (string memory);
    function envUint(string calldata n) external view returns (uint256);
    function envAddress(string calldata n) external view returns (address);
    function randomUint() external view returns (uint256);
    function writeFile(string calldata, string calldata) external;
    function exists(string calldata) external returns (bool);
    function createDir(string calldata, bool) external;
    function removeDir(string calldata, bool) external;
    function removeFile(string calldata) external;
    function unixTime() external view returns (uint256);
    function warp(uint256) external;
    function parseBytes(string calldata) external pure returns (bytes memory);
    function trim(string calldata) external pure returns (string memory);
    function readFile(string memory) external returns (string memory);
    function tryFfi(string[] memory) external returns (FFIResult memory);
    function toString(address) external pure returns (string memory);
    function toString(bytes32) external pure returns (string memory);
    function toString(bytes memory) external pure returns (string memory);
    function toString(bool) external pure returns (string memory);
    function toString(uint256) external pure returns (string memory);
    function toString(int256) external pure returns (string memory);
    function rpcUrl(string memory) external view returns (string memory);
    function createSelectFork(string memory) external view returns (uint256);
    function createSelectFork(
        string memory,
        uint256
    ) external view returns (uint256);
    function computeCreateAddress(
        address,
        uint256
    ) external pure returns (address);
    function getNonce(address) external view returns (uint256);
    function addr(uint256) external view returns (address);
    function label(address, string memory) external;
    enum CallerMode {
        None,
        Broadcast,
        RecurrentBroadcast,
        Prank,
        RecurrentPrank
    }
    function startPrank(address, address) external;
    function changePrank(address) external;
    function startPrank(address) external;
    function prank(address) external;
    function prank(address, address) external;
    function startBroadcast(address) external;
    function broadcast(address) external;
    function stopBroadcast() external;
    function stopPrank() external;
    function readCallers() external view returns (CallerMode, address, address);

    function parseUint(string calldata) external pure returns (uint256);
    function rpc(string calldata m, string calldata p) external;
    function sign(
        address,
        bytes32
    ) external view returns (uint8 v, bytes32 r, bytes32 s);
    struct FFIResult {
        int32 exitCode;
        bytes stdout;
        bytes stderr;
    }
}
