// solhint-disable
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {wm} from "./Wm.s.sol";
import {Help} from "./Help.s.sol";

library LibAnvil {
    using Help for *;
    function setStorage(address account, bytes32 slot, bytes32 value) internal {
        wm.rpc(
            "anvil_setStorageAt",
            string.concat(account.txt(), '","', slot.txt(), '","', value.txt())
        );
        mine();
    }

    function mine() internal {
        uint256 blockNr = block.number;

        wm.rpc("evm_mine", "");
        wm.fork("localhost", blockNr + 1);
    }

    function syncTime(uint256 time) internal {
        uint256 current = time != 0 ? time : wm.getTime();
        wm.rpc("evm_setNextBlockTimestamp", current.str());
        mine();
    }
}
