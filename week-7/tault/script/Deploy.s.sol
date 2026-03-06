// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {TaultFactory} from "../src/TaultFactory.sol";

contract Deploy is Script {
    function run() external {
        vm.startBroadcast();

        TaultFactory factory = new TaultFactory();

        console.log("TaultFactory deployed at:", address(factory));
        console.log("TaultNFT deployed at: ", address(factory.nft()));

        vm.stopBroadcast();
    }
}
