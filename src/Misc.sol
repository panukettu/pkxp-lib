// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Help} from "./Help.s.sol";

using Help for Account global;

struct Account {
    string label;
    address payable addr;
    uint256 pk;
}

interface I20 {
    function nonces(address) external view returns (uint256);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

error Nope(string);
error Overflow(uint256, uint256);

address constant clgAddr = 0x000000000000000000636F6e736F6c652e6c6f67;
address constant vmAddr = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D;

string constant DEFAULT_RPC_ENV = "ETH_RPC_URL";
string constant DEFAULT_MNEMONIC_ENV = "MNEMONIC";
string constant DEFAULT_PK_ENV = "PRIVATE_KEY";
string constant DEFAULT_MNEMONIC = "error burger code";
