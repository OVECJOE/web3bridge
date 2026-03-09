// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {EvictionVault} from "../src/EvictionVault.sol";

contract EvictionVaultScript is Script {
    EvictionVault public vault;

    function setUp() public {}

    function run() public {
        uint256 threshold = vm.envUint("THRESHOLD");
        address[] memory signers = vm.envAddress("SIGNERS", ",");

        vm.startBroadcast();

        vault = new EvictionVault(signers, threshold);

        vm.stopBroadcast();
    }
}
