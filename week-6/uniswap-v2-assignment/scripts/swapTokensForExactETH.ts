const helpers = require("@nomicfoundation/hardhat-network-helpers");
import { ethers } from "hardhat";

const main = async () => {
    const USDCAddress = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";
    const WETHAddress = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";
    const UNIRouter = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D";
    const USDCHolder = "0xf584f8728b874a6a5c7a8d4d387c9aae9172d621";

    await helpers.impersonateAccount(USDCHolder);
    const impersonatedSigner = await ethers.getSigner(USDCHolder);

    const USDC = await ethers.getContractAt("IERC20", USDCAddress, impersonatedSigner);
    const ROUTER = await ethers.getContractAt("IUniswapV2Router", UNIRouter, impersonatedSigner);

    const amountOut = ethers.parseEther("0.5"); // Exact ETH to receive
    const amountInMax = ethers.parseUnits("2000", 6); // Max USDC to spend
    const path = [USDCAddress, WETHAddress];
    const deadline = Math.floor(Date.now() / 1000) + 60 * 10;

    await USDC.approve(UNIRouter, amountInMax);

    const usdcBalBefore = await USDC.balanceOf(impersonatedSigner.address);
    const ethBalBefore = await ethers.provider.getBalance(impersonatedSigner.address);

    console.log("=================Before Swap========================================");
    console.log("USDC Balance:", Number(usdcBalBefore));
    console.log("ETH Balance:", Number(ethBalBefore));

    const tx = await ROUTER.swapTokensForExactETH(
        amountOut,
        amountInMax,
        path,
        impersonatedSigner.address,
        deadline
    );

    await tx.wait();

    const usdcBalAfter = await USDC.balanceOf(impersonatedSigner.address);
    const ethBalAfter = await ethers.provider.getBalance(impersonatedSigner.address);

    console.log("=================After Swap========================================");
    console.log("USDC Balance:", Number(usdcBalAfter));
    console.log("ETH Balance:", Number(ethBalAfter));
    console.log("Swap tokens for exact ETH successful!");
    console.log("=========================================================");
    console.log("USDC USED:", ethers.formatUnits(usdcBalBefore - usdcBalAfter, 6));
    console.log("ETH RECEIVED:", ethers.formatEther(ethBalAfter - ethBalBefore));
};

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
