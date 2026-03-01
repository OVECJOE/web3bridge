const helpers = require("@nomicfoundation/hardhat-network-helpers");
import { ethers } from "hardhat";

const main = async () => {
    const USDCAddress = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";
    const UNIRouter = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D";
    const USDCHolder = "0xf584f8728b874a6a5c7a8d4d387c9aae9172d621";

    await helpers.impersonateAccount(USDCHolder);
    const impersonatedSigner = await ethers.getSigner(USDCHolder);

    const amountUSDC = ethers.parseUnits("1000", 6);
    const amountETH = ethers.parseEther("1");
    const amountUSDCMin = ethers.parseUnits("900", 6);
    const amountETHMin = ethers.parseEther("0.9");
    const deadline = Math.floor(Date.now() / 1000) + 60 * 10;

    const USDC = await ethers.getContractAt("IERC20", USDCAddress, impersonatedSigner);
    const ROUTER = await ethers.getContractAt("IUniswapV2Router", UNIRouter, impersonatedSigner);

    await USDC.approve(UNIRouter, amountUSDC);

    const usdcBalBefore = await USDC.balanceOf(impersonatedSigner.address);
    const ethBalBefore = await ethers.provider.getBalance(impersonatedSigner.address);

    console.log("=================Before========================================");
    console.log("USDC Balance before adding liquidity:", ethers.formatUnits(usdcBalBefore, 6));
    console.log("ETH Balance before adding liquidity:", ethers.formatEther(ethBalBefore));

    const tx = await ROUTER.addLiquidityETH(
        USDCAddress,
        amountUSDC,
        amountUSDCMin,
        amountETHMin,
        impersonatedSigner.address,
        deadline,
        { value: amountETH }
    );

    await tx.wait();

    const usdcBalAfter = await USDC.balanceOf(impersonatedSigner.address);
    const ethBalAfter = await ethers.provider.getBalance(impersonatedSigner.address);

    console.log("=================After========================================");
    console.log("USDC Balance after adding liquidity:", ethers.formatUnits(usdcBalAfter, 6));
    console.log("ETH Balance after adding liquidity:", ethers.formatEther(ethBalAfter));

    console.log("Liquidity added successfully!");
    console.log("=========================================================");
    const usdcUsed = usdcBalBefore - usdcBalAfter;
    const ethUsed = ethBalBefore - ethBalAfter;

    console.log("USDC USED:", ethers.formatUnits(usdcUsed, 6));
    console.log("ETH USED:", ethers.formatEther(ethUsed));
};

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
