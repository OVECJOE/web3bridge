const helpers = require("@nomicfoundation/hardhat-network-helpers");
import { ethers } from "hardhat";

const main = async () => {
    const USDCAddress = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";
    const WETHAddress = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";
    const UNIRouter = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D";

    // Impersonating someone with a lot of ETH (like Binance 8 or just generating an account and funding it)
    // Hardhat provides 10,000 ETH to default signers, we can just use the first default signer!
    const [signer] = await ethers.getSigners();

    const USDC = await ethers.getContractAt("IERC20", USDCAddress, signer);
    const ROUTER = await ethers.getContractAt("IUniswapV2Router", UNIRouter, signer);

    const amountOutMin = ethers.parseUnits("500", 6); // Min USDC to receive
    const amountETH = ethers.parseEther("0.5"); // Exact ETH to send
    const path = [WETHAddress, USDCAddress];
    const deadline = Math.floor(Date.now() / 1000) + 60 * 10;

    const usdcBalBefore = await USDC.balanceOf(signer.address);
    const ethBalBefore = await ethers.provider.getBalance(signer.address);

    console.log("=================Before Swap========================================");
    console.log("USDC Balance:", Number(usdcBalBefore));
    console.log("ETH Balance:", Number(ethBalBefore));

    const tx = await ROUTER.swapExactETHForTokens(
        amountOutMin,
        path,
        signer.address,
        deadline,
        { value: amountETH }
    );

    await tx.wait();

    const usdcBalAfter = await USDC.balanceOf(signer.address);
    const ethBalAfter = await ethers.provider.getBalance(signer.address);

    console.log("=================After Swap========================================");
    console.log("USDC Balance:", Number(usdcBalAfter));
    console.log("ETH Balance:", Number(ethBalAfter));
    console.log("Swap exact ETH for tokens successful!");
    console.log("=========================================================");
    console.log("ETH USED:", ethers.formatEther(ethBalBefore - ethBalAfter));
    console.log("USDC RECEIVED:", ethers.formatUnits(usdcBalAfter - usdcBalBefore, 6));
};

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
