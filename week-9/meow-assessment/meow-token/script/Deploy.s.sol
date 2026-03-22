// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {MeowelotNFT} from "../src/MeowelotNFT.sol";
import {MeowelotToken} from "../src/MeowelotToken.sol";

contract DeployMeowelot is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        address treasury = vm.envOr("TREASURY_ADDRESS", deployer);

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy NFT contract first
        MeowelotNFT nft = new MeowelotNFT(deployer);
        console.log("MeowelotNFT deployed at:", address(nft));

        // 2. Deploy Token contract
        MeowelotToken token = new MeowelotToken(deployer, treasury, address(nft));
        console.log("MeowelotToken deployed at:", address(token));

        // 3. Set token contract as the authorized minter on NFT
        nft.setTokenContract(address(token));
        console.log("Minter set to token contract");

        console.log("Treasury:", treasury);
        console.log("Deployer:", deployer);

        vm.stopBroadcast();
    }
}