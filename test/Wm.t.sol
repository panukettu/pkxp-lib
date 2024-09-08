// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Wallet} from "../src/Wallet.s.sol";
import {File, Files} from "../src/Files.s.sol";
import {wm} from "../src/Wm.s.sol";
import {Help} from "../src/Help.s.sol";

contract WalletTest is Test, Wallet {
    using Help for *;

    address internal constant addrPkTest =
        0x47A7b6e16722De8808d619c707dd7cbc176e0E01;

    function testGetRPC() public view {
        assertEq(wm.getRPC("RPC_ABC"), "https://asdf.io");
    }

    function testNextAddr() public {
        assertEq(
            getNextAddr(address(this)),
            address(new TestContract()),
            "next-addr"
        );
    }

    function testKeyStore() public pure {
        string("true").eq("false", "todo:testKeyStore");
        // assertEq(getAddr("acc1"), address(0));
        // assertEq(getAddr("acc2"), address(0));
    }

    function testPkAddr() public wallets("MNEMONIC", "PK_TEST") {
        assertEq(getAddrPk("PK_TEST"), addrPkTest);
        _testInnerPk();
    }

    function testMAddr() public {
        assertNotEq(getAddr(0), address(0));
    }

    function testMnemonic() public {
        assertEq(sender, address(0));
        assertNotEq(getAddr(0), address(0));
        assertNotEq(getAddr(1010), address(0));
    }

    function testMnemonicAt() public mnemonicAt("MNEMONIC", 1) {
        assertEq(sender, getAddr(1));
        _testInnerMnemonic();
    }

    function testWallets() public wallets("MNEMONIC", "PK_TEST") {
        _testWallets();
    }

    function _testWallets() internal {
        assertEq(sender, addrPkTest, "1");
        vm.prank(sender);
        assertEq(msgSender(), addrPkTest, "2");

        assertNotEq(getAddr(0), address(0), "3");
        assertNotEq(getAddr(0), addrPkTest, "4");
    }

    function _testInnerMnemonic() internal mnemonicAt("MNEMONIC", 2) {
        assertEq(sender, getAddr(2));
    }
    function _testInnerPk() internal pk("PK_TEST") {
        assertEq(sender, getAddrPk("PK_TEST"));
    }

    function _testWalletsInner() internal wallets("MNEMONIC", "PK_TEST") {
        _testWallets();
    }
}

contract TestContract {}

contract FilesTest is Test {
    function testFiles() public {
        File memory file1 = Files.write("temp/hello.txt", abi.encode(444));
        File memory file2 = Files.write(abi.encode(444));

        assertEq(abi.decode(file1.flush(), (uint256)), 444, "read");

        (uint256 a, uint8 b) = abi.decode(
            file2.append(abi.encode(uint8(2))).read(),
            (uint256, uint8)
        );

        assertEq(a, 444, "read2");
        assertEq(b, 2, "read2append");

        Files.clear();
    }
}
