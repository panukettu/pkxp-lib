// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Proxy} from "../vendor/Proxy.sol";
import {IProxied, ProxiedStorage, ZeroAddress, PROXIED_STORAGE_SLOT} from "./IProxied.sol";
import {Solady} from "../vendor/Solady.sol";
import {Revert, create} from "../Funcs.sol";

contract Proxied is IProxied, Proxy {
    using Solady for bytes32;

    modifier nonZero(address addr) virtual {
        if (addr == address(0)) revert ZeroAddress();
        _;
    }

    modifier proxyAuth() virtual {
        if (!_isProxyAuthorized(msg.sender)) _fallback();
        else _;
    }

    constructor(address impl, bytes memory call, address owner) {
        _setProxyAuth(owner, true);
        _version(_s().impl = impl);
        _delegate(call);
    }

    function getImplementation() external view virtual returns (address) {
        return _implementation();
    }

    function setImplementation(
        address impl
    ) public payable virtual returns (address) {
        return _setImplementation(impl);
    }

    function setImplementation(
        address impl,
        bytes calldata call
    ) public payable virtual returns (address addr) {
        addr = setImplementation(impl);
        _delegate(call);
    }

    function setImplementation(
        bytes calldata impl,
        bytes32 salt
    ) public payable virtual returns (address) {
        return setImplementation(create(impl, salt));
    }

    function setImplementation(
        bytes calldata impl
    ) external payable virtual returns (address) {
        return setImplementation(impl, 0);
    }

    function setImplementation(
        bytes calldata impl,
        bytes calldata call,
        bytes32 salt
    ) public payable virtual returns (address) {
        return setImplementation(create(impl, salt), call);
    }

    function setImplementation(
        bytes calldata impl,
        bytes calldata call
    ) external payable virtual returns (address) {
        return setImplementation(impl, call, 0);
    }

    function setImplementation(
        uint256 version
    ) external payable virtual returns (address) {
        return _setImplementation(_s().versions[version - 1]);
    }

    function delegate(
        bytes[] calldata calls
    ) external payable virtual proxyAuth {
        for (uint256 i; i < calls.length; ) _delegate(calls[i++]);
    }

    function delegate(
        address to,
        bytes calldata data
    ) external payable virtual proxyAuth {
        _delegate(to, data);
    }

    function getProxyVersion() external virtual proxyAuth returns (uint256) {
        return _version(_implementation());
    }

    function peekImplementation(
        bytes calldata ccode,
        bytes32 salt
    ) external virtual returns (address) {
        if (msg.sender != address(this)) return _peekImplementation();
        Revert(abi.encode(create(ccode, salt)));
    }

    function setProxyAuth(
        address who,
        bool isAuthorized
    ) external virtual proxyAuth {
        _setProxyAuth(who, isAuthorized);
    }

    receive() external payable virtual {}

    function _setImplementation(
        address addr
    ) internal virtual proxyAuth returns (address) {
        _version(_s().impl = addr);
        return addr;
    }

    function _implementation()
        internal
        view
        virtual
        override
        returns (address)
    {
        return _s().impl;
    }

    function _peekImplementation() internal virtual returns (address) {
        if (_isProxyAuthorized(msg.sender)) {
            (, bytes memory data) = address(this).call(msg.data);
            return abi.decode(data, (address));
        }

        _fallback();
    }

    function _setProxyAuth(
        address who,
        bool isAuthorized
    ) internal virtual nonZero(who) {
        _s().auth[who] = isAuthorized;
    }

    function _isProxyAuthorized(
        address who
    ) internal view virtual returns (bool) {
        return _s().auth[who];
    }

    function _delegate(
        bytes memory call
    ) internal virtual returns (bytes memory r) {
        if (call.length == 0) return r;

        (address to, bytes memory data) = abi.decode(call, (address, bytes));
        return _delegate(to, data);
    }

    function _delegate(
        address to,
        bytes memory data
    ) internal virtual returns (bytes memory) {
        if (to == address(0)) to = _implementation();

        (bool success, bytes memory retData) = to.delegatecall(data);

        if (!success) Revert(retData);

        return retData;
    }

    function _s() internal pure virtual returns (ProxiedStorage storage s) {
        bytes32 slot = PROXIED_STORAGE_SLOT;
        assembly {
            s.slot := slot
        }
    }

    function _version(
        address impl
    ) private nonZero(impl) returns (uint256 version) {
        address[] storage versions = _s().versions;
        for (uint256 i; i < versions.length; i++) {
            if (versions[i] == impl) return i + 1;
        }
        versions.push(impl);
    }
}
