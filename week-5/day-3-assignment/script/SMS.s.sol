// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {SMS} from "../src/SMS.sol";

contract SMSScript is Script {
    SMS public sms;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        sms = new SMS();

        vm.stopBroadcast();
    }
}
