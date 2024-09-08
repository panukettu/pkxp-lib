// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

bytes32 constant PROXIED_STORAGE_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

struct ProxiedStorage {
    address impl;
    mapping(address => bool) auth;
    address[] versions;
}

error Unauthorized(address);
error ZeroAddress();

interface IProxied {
    function setProxyAuth(address, bool) external;
    function setImplementation(address) external payable returns (address);
    function setImplementation(
        address,
        bytes calldata
    ) external payable returns (address);
    function setImplementation(uint256) external payable returns (address);
    function setImplementation(
        bytes calldata,
        bytes32
    ) external payable returns (address);
    function setImplementation(
        bytes calldata
    ) external payable returns (address);
    function setImplementation(
        bytes calldata,
        bytes calldata
    ) external payable returns (address);
    function setImplementation(
        bytes calldata,
        bytes calldata,
        bytes32
    ) external payable returns (address);
    function getProxyVersion() external returns (uint256);
    function getImplementation() external view returns (address);
    function peekImplementation(
        bytes calldata,
        bytes32
    ) external returns (address);
    function delegate(address, bytes calldata) external payable;
    function delegate(bytes[] calldata) external payable;
}
