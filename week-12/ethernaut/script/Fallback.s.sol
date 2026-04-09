// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {Fallback} from "../src/Fallback.sol";

contract FallbackScript is Script {
    Fallback public fallback;

    function run() public {
        vm.startBroadcast();

        vm.createSelectFork()

        vm.stopBroadcast(vm.rpcUrl(""));
    }
}
