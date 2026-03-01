const helpers = require("@nomicfoundation/hardhat-network-helpers");
import { ethers } from "hardhat";

const main = async () => {
    const USDCAddress = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";
    const DAIAddress = "0x6B175474E89094C44Da98b954EedeAC495271d0F";
    const UNIRouter = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D";
    const USDCHolder = "0xf584f8728b874a6a5c7a8d4d387c9aae9172d621";

    await helpers.impersonateAccount(USDCHolder);
    const impersonatedSigner = await ethers.getSigner(USDCHolder);

    const USDC = await ethers.getContractAt("IERC20", USDCAddress, impersonatedSigner);
    const DAI = await ethers.getContractAt("IERC20", DAIAddress, impersonatedSigner);
    const ROUTER = await ethers.getContractAt("IUniswapV2Router", UNIRouter, impersonatedSigner);

    const amountIn = ethers.parseUnits("1000", 6);
    // Get expected output
    const path = [USDCAddress, DAIAddress];
    const deadline = Math.floor(Date.now() / 1000) + 60 * 10;

    await USDC.approve(UNIRouter, amountIn);

    const usdcBalBefore = await USDC.balanceOf(impersonatedSigner.address);
    const daiBalBefore = await DAI.balanceOf(impersonatedSigner.address);

    console.log("=================Before Swap========================================");
    console.log("USDC Balance:", Number(usdcBalBefore));
    console.log("DAI Balance:", Number(daiBalBefore));

    const tx = await ROUTER.swapExactTokensForTokens(
        amountIn,
        0, // amountOutMin
        path,
        impersonatedSigner.address,
        deadline
    );

    await tx.wait();

    const usdcBalAfter = await USDC.balanceOf(impersonatedSigner.address);
    const daiBalAfter = await DAI.balanceOf(impersonatedSigner.address);

    console.log("=================After Swap========================================");
    console.log("USDC Balance:", Number(usdcBalAfter));
    console.log("DAI Balance:", Number(daiBalAfter));

    console.log("Swap exact tokens for tokens successful!");
    console.log("=========================================================");
    console.log("USDC USED:", ethers.formatUnits(usdcBalBefore - usdcBalAfter, 6));
    console.log("DAI RECEIVED:", ethers.formatUnits(daiBalAfter - daiBalBefore, 18));
};

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
