// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {TwoBottles} from "../src/2bottles.sol";

contract TwoBottlesScript is Script {
    TwoBottles public twoBottles;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        twoBottles = new TwoBottles();

        vm.stopBroadcast();
    }
}
