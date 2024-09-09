// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Wallet} from "../src/Wallet.s.sol";
import {File, Files} from "../src/Files.s.sol";
import {wm} from "../src/Wm.s.sol";
import {Help} from "../src/Help.s.sol";
import {WmBase} from "../src/WmBase.s.sol";
import {Revert} from "../src/Funcs.sol";

// solhint-disable

contract WalletTest is Test, Wallet {
    using Help for *;

    address internal constant addrPkTest =
        0x47A7b6e16722De8808d619c707dd7cbc176e0E01;
    address internal constant addrKsTest =
        0xeB9E44277322a993dE1f062902188E0A77f110c8;

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

    function testKeyStore() public wallet("test acc") {
        assertEq(addrKsTest, sender, "ks-1");
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

contract SignerTest is Test, WmBase {
    using Help for *;

    TestContract2 internal c2;

    function setUp() public {
        useMnemonic("MNEMONIC");
        c2 = new TestContract2();
    }

    function testBroadcasts() public {
        address first = getAddr(0);
        address second = getAddr(1);
        address third = getAddr(2);
        vm.startBroadcast(first);
        msgSender().eq(first, "1");

        sendFrom(second);
        msgSender().eq(second, "2");

        sendFrom(first);
        _broadcastRestored().eq(second, "3");

        msgSender().eq(first, "4");
        c2.addr().eq(second, "5");

        sendFrom(third);

        msgSender().eq(third, "6");
        vm.stopBroadcast();

        sendFrom("test acc");
        msgSender().eq(getAddr("test acc"), "7");

        address thatguy = getAddr("thatguy");
        deal(thatguy, 1 ether);

        sendFrom("thatguy");
        sender.eq(thatguy, "8");
        payable(getAddr("test acc")).transfer(1 wei);

        getAddr("test acc").clg("test-acc");
        vm.rememberKey(wm.getPk("test acc"));

        wm.sign("test acc", "foo");
    }

    function _broadcastRestored()
        internal
        sendFrom$(getAddr(1))
        returns (address)
    {
        c2.save();
        return msgSender();
    }

    function testPranks() public {
        address first = getAddr(0);
        address second = getAddr(1);
        address third = getAddr(2);
        vm.startPrank(first);
        msgSender().eq(first, "1");

        prank(second);
        msgSender().eq(second, "2");

        prank(first);
        _prankRestored().eq(second, "3");
        msgSender().eq(first, "4");
        c2.addr().eq(second, "5");

        prank(third);
        msgSender().eq(third, "6");

        prank("thatguy");
        msgSender().eq(getAddr("thatguy"), "7");
    }
    function _prankRestored() internal pranked$(getAddr(1)) returns (address) {
        c2.save();
        return msgSender();
    }
}

contract TypesTest is Test, WmBase {
    using Help for *;
    function testStrings() public view {
        address(this).clg("addr");
        bytes32 val = "foo";
        bytes(val.txt()).length.eq(66, "str");
        bytes(val.str()).length.eq(3, "txt");

        10.1 ether.dstr().eq("10.10", "dec-0");
        2524e8.dstr(8).eq("2524.00", "dec-2");
        12.5e8.dstr(8).eq("12.50", "dec-1");
        5000.01e8.dstr(8).eq("5000.01", "dec-3");

        0.0005e8.dstr(8).eq("0.0005", "dec-4");
        0.1e2.dstr(2).eq("0.10", "dec-5");
        1 ether.dstr(18).eq("1.00", "dec-6");

        100.10101 ether.dstr().eq("100.10101", "dec-7");
        10101010.10101010 ether.dstr(18).eq("10101010.1010101", "dec-8");

        10101010.1 ether.dstr(18).eq("10101010.10", "dec-9");
        10101010.01 ether.dstr(18).eq("10101010.01", "dec-10");
        10101010.000 ether.dstr(18).eq("10101010.00", "dec-11");
        10101010.0001 ether.dstr(18).eq("10101010.0001", "dec-12");

        "s2".clg("s3");
        string memory r;
        bytes(r).length.clg("empty-len");
        this.testStrings.selector.txt(4).eq(
            bytes4(keccak256("testStrings()")).txt(
                this.testStrings.selector.length
            ),
            "sel"
        );

        this.testStrings.selector.txt(4).clg("sel-2");
    }

    function testDecimals() public pure {
        uint256 wad = 1e18;
        uint256 ray = 1e27;

        wad.toDec(18, 27).eq(ray, "wad-ray");
        ray.toDec(27, 18).eq(wad, "ray-wad");

        1.29e18.toDec(18, 1).eq(12, "a-b");
    }
    struct Foo {
        string foo;
        uint256 bar;
    }

    function testBytes() public pure {
        bytes32 val = bytes32(abi.encodePacked(uint192(192), uint64(64)));
        (uint192 a, uint64 b) = abi.decode(val.split(192), (uint192, uint64));
        a.eq(192, "val");
        b.eq(64, "b");

        bytes memory callData = abi.encodeWithSignature(
            "func(string,uint256)",
            string("hello"),
            1 ether
        );

        callData.slice(0, 4).eq(hex"555fe6d1", "slice-0");

        (string memory foo, uint256 bar) = abi.decode(
            callData.slice(4),
            (string, uint256)
        );
        foo.eq("hello", "decode-foo");
        bar.eq(1 ether, "decode-bar");
        abi.decode(callData.slice(36, 32), (uint256)).eq(1 ether, "decode-bar");
        string(callData.slice(100, uint256(bytes32(callData.slice(68, 32)))))
            .eq("hello", "str-parts");
    }
}

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

contract TestContract {}
contract TestContract2 {
    using Help for *;
    address public addr;

    TestContract3 public c3;

    constructor() {
        c3 = new TestContract3();
    }

    function save() public {
        addr = msg.sender;
    }

    function func() public pure {
        wm.clg("TestContract");
        uint256[] memory nums = new uint256[](3);

        nums[0] = 1 ether;
        nums[1] = 100 ether;
        nums[2] = 0 ether;
    }

    function nope() public view {
        (, bytes memory data) = address(c3).staticcall(
            abi.encodeWithSelector(c3.nope.selector)
        );
        Revert(data);
    }
}

contract TestContract3 {
    struct Structy {
        string mesg;
        uint256 val;
    }
    error TestError(string mesg, uint256 val, Structy _struct);

    function nope() public pure {
        revert TestError("nope", 1 ether, Structy("hello", 1 ether));
    }
}
