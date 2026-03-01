const helpers = require("@nomicfoundation/hardhat-network-helpers");
import { ethers } from "hardhat";

const main = async () => {
    const USDCAddress = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";
    const UNIRouter = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D";
    const UNIFACTORY = "0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f";
    const WETHAddress = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";
    const USDCHolder = "0xf584f8728b874a6a5c7a8d4d387c9aae9172d621";

    await helpers.impersonateAccount(USDCHolder);
    const impersonatedSigner = await ethers.getSigner(USDCHolder);

    const amountUSDC = ethers.parseUnits("1000", 6);
    const amountETH = ethers.parseEther("1");
    const deadline = Math.floor(Date.now() / 1000) + 60 * 10;

    const USDC = await ethers.getContractAt("IERC20", USDCAddress, impersonatedSigner);
    const ROUTER = await ethers.getContractAt("IUniswapV2Router", UNIRouter, impersonatedSigner);

    // 1. Add Liquidity ETH First to get LP tokens
    await USDC.approve(UNIRouter, amountUSDC);

    console.log("Adding liquidity ETH to get LP tokens...");
    await ROUTER.addLiquidityETH(
        USDCAddress,
        amountUSDC,
        0,
        0,
        impersonatedSigner.address,
        deadline,
        { value: amountETH }
    );

    // Get Pair Address (WETH-USDC pair)
    // IUniswapV2Factory interface has getPair
    const factoryABI = ["function getPair(address tokenA, address tokenB) external view returns (address pair)"];
    const factory = await ethers.getContractAt(factoryABI, UNIFACTORY, impersonatedSigner);
    const pairAddress = await factory.getPair(WETHAddress, USDCAddress);

    const pairContract = await ethers.getContractAt("IERC20", pairAddress, impersonatedSigner);

    const lpBalance = await pairContract.balanceOf(impersonatedSigner.address);
    console.log("LP Token Balance after adding:", ethers.formatUnits(lpBalance, 18));

    // 2. Remove Liquidity ETH
    console.log("Removing liquidity ETH...");
    await pairContract.approve(UNIRouter, lpBalance);

    const usdcBalBefore = await USDC.balanceOf(impersonatedSigner.address);
    const ethBalBefore = await ethers.provider.getBalance(impersonatedSigner.address);
    console.log("=================Before Removal========================================");
    console.log("USDC Balance:", ethers.formatUnits(usdcBalBefore, 6));
    console.log("ETH Balance:", ethers.formatEther(ethBalBefore));

    const tx = await ROUTER.removeLiquidityETH(
        USDCAddress,
        lpBalance,
        0,
        0,
        impersonatedSigner.address,
        deadline
    );

    await tx.wait();

    const usdcBalAfter = await USDC.balanceOf(impersonatedSigner.address);
    const ethBalAfter = await ethers.provider.getBalance(impersonatedSigner.address);
    const lpBalanceAfter = await pairContract.balanceOf(impersonatedSigner.address);

    console.log("=================After Removal========================================");
    console.log("USDC Balance:", ethers.formatUnits(usdcBalAfter, 6));
    console.log("ETH Balance:", ethers.formatEther(ethBalAfter));
    console.log("LP Token Balance:", ethers.formatUnits(lpBalanceAfter, 18));
    console.log("Liquidity over ETH removed successfully!");
};

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
