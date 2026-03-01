const helpers = require("@nomicfoundation/hardhat-network-helpers");
import { ethers } from "hardhat";

const main = async () => {
    const USDCAddress = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";
    const DAIAddress = "0x6B175474E89094C44Da98b954EedeAC495271d0F";
    const UNIRouter = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D";
    const UNIFACTORY = "0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f"; // Uniswap V2 Factory
    const USDCHolder = "0xf584f8728b874a6a5c7a8d4d387c9aae9172d621";

    await helpers.impersonateAccount(USDCHolder);
    const impersonatedSigner = await ethers.getSigner(USDCHolder);

    const amountUSDC = ethers.parseUnits("1000", 6);
    const amountDAI = ethers.parseUnits("1000", 18);
    const deadline = Math.floor(Date.now() / 1000) + 60 * 10;

    const USDC = await ethers.getContractAt("IERC20", USDCAddress, impersonatedSigner);
    const DAI = await ethers.getContractAt("IERC20", DAIAddress, impersonatedSigner);
    const ROUTER = await ethers.getContractAt("IUniswapV2Router", UNIRouter, impersonatedSigner);

    // 1. Add Liquidity First to get LP tokens
    await USDC.approve(UNIRouter, amountUSDC);
    await DAI.approve(UNIRouter, amountDAI);

    console.log("Adding liquidity to get LP tokens...");
    await ROUTER.addLiquidity(
        USDCAddress,
        DAIAddress,
        amountUSDC,
        amountDAI,
        0,
        0,
        impersonatedSigner.address,
        deadline
    );

    // Get Pair Address
    const factory = await ethers.getContractAt("IERC20", UNIFACTORY, impersonatedSigner);
    // Actually we need the view function getPair, it's easier to just compute or fetch it
    // But wait, the Pair contract IS an ERC20. I can just impersonate a known LP token holder or fetch pair address.
    // The pair address for USDC/DAI is 0xAE461cA67B15dc8dc81CE7615e0320dA1A9AB8D5
    const pairAddress = "0xAE461cA67B15dc8dc81CE7615e0320dA1A9AB8D5";
    const pairContract = await ethers.getContractAt("IERC20", pairAddress, impersonatedSigner);

    const lpBalance = await pairContract.balanceOf(impersonatedSigner.address);
    console.log("LP Token Balance after adding:", ethers.formatUnits(lpBalance, 18));

    // 2. Remove Liquidity
    console.log("Removing liquidity...");
    await pairContract.approve(UNIRouter, lpBalance);

    const usdcBalBefore = await USDC.balanceOf(impersonatedSigner.address);
    const daiBalBefore = await DAI.balanceOf(impersonatedSigner.address);
    console.log("=================Before Removal========================================");
    console.log("USDC Balance:", ethers.formatUnits(usdcBalBefore, 6));
    console.log("DAI Balance:", ethers.formatUnits(daiBalBefore, 18));

    const tx = await ROUTER.removeLiquidity(
        USDCAddress,
        DAIAddress,
        lpBalance,
        0,
        0,
        impersonatedSigner.address,
        deadline
    );

    await tx.wait();

    const usdcBalAfter = await USDC.balanceOf(impersonatedSigner.address);
    const daiBalAfter = await DAI.balanceOf(impersonatedSigner.address);
    const lpBalanceAfter = await pairContract.balanceOf(impersonatedSigner.address);

    console.log("=================After Removal========================================");
    console.log("USDC Balance:", ethers.formatUnits(usdcBalAfter, 6));
    console.log("DAI Balance:", ethers.formatUnits(daiBalAfter, 18));
    console.log("LP Token Balance:", ethers.formatUnits(lpBalanceAfter, 18));
    console.log("Liquidity removed successfully!");
};

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
