// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Signer} from "../src/Signer.s.sol";
import {Help} from "../src/Help.s.sol";
import {Proxied, ProxiedStorage, PROXIED_STORAGE_SLOT} from "../src/util/Proxied.sol";

contract ProxiedTest is Test, Signer {
    using Help for *;

    address internal constant owner =
        0x47A7b6e16722De8808d619c707dd7cbc176e0E01;

    Mock internal impl = new Mock();
    address payable internal implAddr = payable(address(impl));

    Proxied internal proxy = new Proxied(implAddr, "", owner);
    address payable internal proxyAddr = payable(proxy);

    Mock internal mock = Mock(proxyAddr);

    function testProxy() public {
        proxy.getImplementation().eq(implAddr, "impl-1");
        mock.setFoo(address(100));
        mock.getFoo().eq(address(100), "foo-1");
        impl.getFoo().eq(address(0), "foo-2");

        mock.setImplementation(address(101));
        mock.getFoo().eq(address(101), "foo-3");

        proxy.getImplementation().eq(implAddr, "impl-2");

        (, address payable newImpl) = _createImpl();

        prank(owner);
        proxy.setImplementation(newImpl);
        clearCallers();

        proxy.getImplementation().eq(newImpl, "impl-3");

        mock.getFoo().eq(address(101), "foo-4");

        (, address payable newImpl2) = _createImpl();

        prank(owner);
        proxy.setImplementation(
            newImpl2,
            abi.encode(address(0), abi.encodeCall(mock.setFoo, (address(102))))
        );
        mock.getFoo().eq(address(102), "foo-5");
        proxy.getProxyVersion().eq(3, "version-1");

        address nextImpl = proxy.peekImplementation(type(Mock).creationCode, 0);

        proxy
            .setImplementation(
                type(Mock).creationCode,
                abi.encode(
                    address(0),
                    abi.encodeCall(mock.setFoo, (address(103)))
                )
            )
            .eq(nextImpl, "impl-4");
        proxy.getProxyVersion().eq(4, "version-2");
        mock.getFoo().eq(address(103), "foo-5");

        proxy.setImplementation(1).eq(implAddr, "impl-5");
        proxy.getProxyVersion().eq(1, "version-3");
    }

    function testProxyOwner() external pranked(owner) {
        mock.getImplementation().eq(implAddr, "impl-2");

        (, address newImpl) = _createImpl();
        newImpl.notEq(implAddr, "impl-3");

        mock.setImplementation(newImpl);

        proxy.getImplementation().eq(newImpl, "impl-4");
        mock.getImplementation().eq(newImpl, "impl-5");

        proxy.setProxyAuth(owner, false);

        mock.getFoo().eq(address(0), "foo-1");
        mock.setImplementation(implAddr);
        mock.getFoo().eq(implAddr, "foo-2");

        proxy.getImplementation().notEq(implAddr, "impl-6");
        mock.getImplementation().notEq(implAddr, "impl-7");
    }

    function testPeekImplementation() external pranked(owner) {
        address nosaltImpl = proxy.peekImplementation(
            type(Mock).creationCode,
            0
        );
        nosaltImpl.eq(getNextAddr(address(proxy)), "impl-1");

        proxy.setImplementation(type(Mock).creationCode, 0);
        proxy.getImplementation().eq(nosaltImpl, "impl-2");

        bytes32 salt = "salt-1";

        address saltImpl = proxy.peekImplementation(
            type(Mock).creationCode,
            salt
        );
        saltImpl.notEq(nosaltImpl, "impl-3");

        proxy.setImplementation(type(Mock).creationCode, salt);
        proxy.getImplementation().eq(saltImpl, "impl-4");
    }

    function testProxyAuth() external {
        bytes memory setImplCall = abi.encodeWithSignature(
            "setImplementation(bytes,bytes,bytes32)",
            type(Mock).creationCode,
            "",
            bytes32("salt-1")
        );

        bytes[] memory calls = new bytes[](1);
        calls[0] = abi.encode(implAddr, setImplCall);

        bytes memory err = bytes("nope");

        vm.expectRevert(err);
        proxy.setProxyAuth(owner, false);

        vm.expectRevert(err);
        proxy.setImplementation(implAddr, "");

        vm.expectRevert(err);
        proxy.setImplementation(1);

        vm.expectRevert(err);
        proxy.setImplementation(type(Mock).creationCode);

        vm.expectRevert(err);
        proxy.setImplementation(type(Mock).creationCode, 0);

        vm.expectRevert(err);
        proxy.setImplementation(type(Mock).creationCode, bytes32("salt-1"));

        vm.expectRevert(err);
        proxy.setImplementation(type(Mock).creationCode, "", "salt-1");

        vm.expectRevert(err);
        proxy.delegate(implAddr, setImplCall);

        vm.expectRevert(err);
        proxy.delegate(calls);

        vm.expectRevert(err);
        proxy.getProxyVersion();

        vm.expectRevert(err);
        proxy.peekImplementation("", bytes32("salt-1"));
    }

    function _createImpl() internal returns (Mock m, address payable) {
        return (m = new Mock(), payable(address(m)));
    }
}

contract Mock {
    address public foo;

    function setImplementation(address addr) external virtual {
        setFoo(addr);
    }

    function getImplementation() external view returns (address) {
        return _s().impl;
    }

    function _s() internal pure returns (ProxiedStorage storage s) {
        bytes32 slot = PROXIED_STORAGE_SLOT;
        assembly {
            s.slot := slot
        }
    }

    function setFoo(address _foo) public {
        foo = _foo;
    }

    function getFoo() public view returns (address) {
        return foo;
    }

    fallback() external payable {
        revert("nope");
    }

    receive() external payable {}
}
