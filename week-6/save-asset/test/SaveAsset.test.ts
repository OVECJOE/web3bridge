import hre from "hardhat";
import { expect } from "chai";
// import { HardhatEthers } from "@nomicfoundation/hardhat-ethers/types";

describe("SaveAsset", () => {
    let ethers: any;
    let loadFixture: <T>(fn: () => Promise<T>) => Promise<T>;

    before(async () => {
        const { ethers: e, networkHelpers } = await hre.network.connect();
        ethers = e;
        loadFixture = networkHelpers.loadFixture;
    });

    // Setup fixture
    async function saveAssetFixture() {
        // Generate some accounts
        const [alice, bob] = await ethers.getSigners();

        // Deploy the contracts
        const MockERC20 = await ethers.getContractFactory("MockERC20");
        const mockERC20 = await MockERC20.deploy("MockERC20", "MCK", 18);
        const tokenAddress = mockERC20.getAddress();

        const SaveAsset = await ethers.getContractFactory("SaveAsset");
        const saveAsset = await SaveAsset.deploy();
        const owner = saveAsset.getAddress();

        // Mint tokens to users
        await mockERC20.mint(alice.address, 1000);
        await mockERC20.connect(alice).approve(owner, 1000);
        
        await mockERC20.mint(bob.address, 1000);
        await mockERC20.connect(bob).approve(owner, 1000);

        return { tokenAddress, saveAsset, owner, alice, bob };
    }

    describe("depositERC20", async () => {
        it("Should allow the user to deposit erc20 token", async () => {
            const { tokenAddress, saveAsset, alice } = await loadFixture(saveAssetFixture);

            await saveAsset.connect(alice).depositERC20(tokenAddress, 10);
            const aliceBalance = await saveAsset.connect(alice).getERC20Balance(tokenAddress);
            expect(aliceBalance).to.be.equal(10);
        })

        it("Should revert if amount is zero", async () => {
            const { saveAsset, tokenAddress, alice } = await loadFixture(saveAssetFixture);

            await expect(
                saveAsset.connect(alice).depositERC20(tokenAddress, 0)
            ).to.be.revertedWith("Can't deposit zero value");
        });
    });
});
