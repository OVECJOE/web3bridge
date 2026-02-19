import { network } from "hardhat";
import { parseUnits } from "ethers";

const { ethers } = await network.connect({
  network: "coreDaoTestnet",
  chainType: "l1",
});

const [deployer] = await ethers.getSigners();
console.log("Deploying with account:", deployer.address);

const balance = await ethers.provider.getBalance(deployer.address);
console.log("Account balance:", balance.toString());

const AttendanceRegistry = await ethers.getContractFactory("AttendanceRegistry");

// Core DAO testnet requires a minimum maxPriorityFeePerGas of 60 gwei
const feeData = await ethers.provider.getFeeData();
const maxPriorityFeePerGas = parseUnits("60", "gwei");
const maxFeePerGas = (feeData.maxFeePerGas ?? parseUnits("100", "gwei")) + maxPriorityFeePerGas;

console.log("Deploying AttendanceRegistry...");
const registry = await AttendanceRegistry.deploy({
  maxPriorityFeePerGas,
  maxFeePerGas,
});

await registry.waitForDeployment();

const address = await registry.getAddress();
console.log("AttendanceRegistry deployed to:", address);
