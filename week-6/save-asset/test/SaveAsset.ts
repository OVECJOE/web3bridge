import { expect } from "chai";
import hre from "hardhat";

describe("SaveAsset", function () {
    let ethers: any;
    let loadFixture: <T>(fn: () => Promise<T>) => Promise<T>;

    before(async function () {
        const { ethers: e, networkHelpers } = await hre.network.connect();
        ethers = e;
        loadFixture = networkHelpers.loadFixture;
    });

    async function deploySaveAssetFixture() {
        const [owner, alice, bob] = await ethers.getSigners();

        // Deploy mock ERC20 token
        const MockERC20 = await ethers.getContractFactory("MockERC20");
        const token = await MockERC20.deploy("MockToken", "MTK", ethers.parseEther("10000"));

        // Deploy SaveAsset contract
        const SaveAsset = await ethers.getContractFactory("SaveAsset");
        const saveAsset = await SaveAsset.deploy();

        // Distribute tokens to alice and bob
        await token.transfer(alice.address, ethers.parseEther("1000"));
        await token.transfer(bob.address, ethers.parseEther("1000"));

        return { saveAsset, token, owner, alice, bob };
    }

    describe("Deployment", function () {
        it("Should deploy successfully", async function () {
            const { saveAsset } = await loadFixture(deploySaveAssetFixture);
            expect(await saveAsset.getAddress()).to.be.properAddress;
        });

        it("Should start with zero contract balance", async function () {
            const { saveAsset } = await loadFixture(deploySaveAssetFixture);
            expect(await saveAsset.getContractBalance()).to.equal(0);
        });
    });

    describe("Ether Deposits", function () {
        it("Should allow a user to deposit ether", async function () {
            const { saveAsset, alice } = await loadFixture(deploySaveAssetFixture);
            const depositAmount = ethers.parseEther("1");

            await saveAsset.connect(alice).depositEther({ value: depositAmount });

            expect(await saveAsset.connect(alice).getEtherBalance()).to.equal(depositAmount);
        });

        it("Should update the contract balance after ether deposit", async function () {
            const { saveAsset, alice } = await loadFixture(deploySaveAssetFixture);
            const depositAmount = ethers.parseEther("2");

            await saveAsset.connect(alice).depositEther({ value: depositAmount });

            expect(await saveAsset.getContractBalance()).to.equal(depositAmount);
        });

        it("Should emit DepositSuccessful event on ether deposit", async function () {
            const { saveAsset, alice } = await loadFixture(deploySaveAssetFixture);
            const depositAmount = ethers.parseEther("1");

            await expect(saveAsset.connect(alice).depositEther({ value: depositAmount }))
                .to.emit(saveAsset, "DepositSuccessful")
                .withArgs(alice.address, depositAmount, "Ether");
        });

        it("Should reject zero-value ether deposits", async function () {
            const { saveAsset, alice } = await loadFixture(deploySaveAssetFixture);

            await expect(
                saveAsset.connect(alice).depositEther({ value: 0 })
            ).to.be.revertedWith("Can't deposit zero value");
        });

        it("Should track balances per user independently", async function () {
            const { saveAsset, alice, bob } = await loadFixture(deploySaveAssetFixture);

            await saveAsset.connect(alice).depositEther({ value: ethers.parseEther("1") });
            await saveAsset.connect(bob).depositEther({ value: ethers.parseEther("2") });

            expect(await saveAsset.connect(alice).getEtherBalance()).to.equal(ethers.parseEther("1"));
            expect(await saveAsset.connect(bob).getEtherBalance()).to.equal(ethers.parseEther("2"));
        });

        it("Should accumulate multiple ether deposits", async function () {
            const { saveAsset, alice } = await loadFixture(deploySaveAssetFixture);

            await saveAsset.connect(alice).depositEther({ value: ethers.parseEther("1") });
            await saveAsset.connect(alice).depositEther({ value: ethers.parseEther("2") });

            expect(await saveAsset.connect(alice).getEtherBalance()).to.equal(ethers.parseEther("3"));
        });
    });

    describe("Ether Withdrawals", function () {
        it("Should allow a user to withdraw their ether", async function () {
            const { saveAsset, alice } = await loadFixture(deploySaveAssetFixture);
            const depositAmount = ethers.parseEther("2");
            const withdrawAmount = ethers.parseEther("1");

            await saveAsset.connect(alice).depositEther({ value: depositAmount });
            await saveAsset.connect(alice).withdrawEther(withdrawAmount);

            expect(await saveAsset.connect(alice).getEtherBalance()).to.equal(ethers.parseEther("1"));
        });

        it("Should update contract balance after ether withdrawal", async function () {
            const { saveAsset, alice } = await loadFixture(deploySaveAssetFixture);
            const depositAmount = ethers.parseEther("2");
            const withdrawAmount = ethers.parseEther("1");

            await saveAsset.connect(alice).depositEther({ value: depositAmount });
            await saveAsset.connect(alice).withdrawEther(withdrawAmount);

            expect(await saveAsset.getContractBalance()).to.equal(ethers.parseEther("1"));
        });

        it("Should emit WithdrawalSuccessful event on ether withdrawal", async function () {
            const { saveAsset, alice } = await loadFixture(deploySaveAssetFixture);
            const depositAmount = ethers.parseEther("1");

            await saveAsset.connect(alice).depositEther({ value: depositAmount });

            await expect(saveAsset.connect(alice).withdrawEther(depositAmount))
                .to.emit(saveAsset, "WithdrawalSuccessful")
                .withArgs(alice.address, depositAmount, "Ether", "0x");
        });

        it("Should revert when withdrawing more than balance", async function () {
            const { saveAsset, alice } = await loadFixture(deploySaveAssetFixture);

            await saveAsset.connect(alice).depositEther({ value: ethers.parseEther("1") });

            await expect(
                saveAsset.connect(alice).withdrawEther(ethers.parseEther("2"))
            ).to.be.revertedWith("Insufficient funds");
        });

        it("Should revert when withdrawing with no balance", async function () {
            const { saveAsset, alice } = await loadFixture(deploySaveAssetFixture);

            await expect(
                saveAsset.connect(alice).withdrawEther(ethers.parseEther("1"))
            ).to.be.revertedWith("Insufficient funds");
        });

        it("Should allow full withdrawal of ether balance", async function () {
            const { saveAsset, alice } = await loadFixture(deploySaveAssetFixture);
            const depositAmount = ethers.parseEther("1");

            await saveAsset.connect(alice).depositEther({ value: depositAmount });
            await saveAsset.connect(alice).withdrawEther(depositAmount);

            expect(await saveAsset.connect(alice).getEtherBalance()).to.equal(0);
            expect(await saveAsset.getContractBalance()).to.equal(0);
        });

        it("Should transfer ether back to user's wallet", async function () {
            const { saveAsset, alice } = await loadFixture(deploySaveAssetFixture);
            const depositAmount = ethers.parseEther("1");

            await saveAsset.connect(alice).depositEther({ value: depositAmount });

            await expect(
                saveAsset.connect(alice).withdrawEther(depositAmount)
            ).to.changeEtherBalance(ethers, alice, depositAmount);
        });
    });

    describe("ERC20 Deposits", function () {
        it("Should allow a user to deposit ERC20 tokens", async function () {
            const { saveAsset, token, alice } = await loadFixture(deploySaveAssetFixture);
            const depositAmount = ethers.parseEther("100");

            await token.connect(alice).approve(await saveAsset.getAddress(), depositAmount);
            await saveAsset.connect(alice).depositERC20(await token.getAddress(), depositAmount);

            expect(
                await saveAsset.connect(alice).getERC20Balance(await token.getAddress())
            ).to.equal(depositAmount);
        });

        it("Should update contract token balance after ERC20 deposit", async function () {
            const { saveAsset, token, alice } = await loadFixture(deploySaveAssetFixture);
            const depositAmount = ethers.parseEther("100");

            await token.connect(alice).approve(await saveAsset.getAddress(), depositAmount);
            await saveAsset.connect(alice).depositERC20(await token.getAddress(), depositAmount);

            expect(await token.balanceOf(await saveAsset.getAddress())).to.equal(depositAmount);
        });

        it("Should emit DepositSuccessful event on ERC20 deposit", async function () {
            const { saveAsset, token, alice } = await loadFixture(deploySaveAssetFixture);
            const depositAmount = ethers.parseEther("100");

            await token.connect(alice).approve(await saveAsset.getAddress(), depositAmount);

            await expect(
                saveAsset.connect(alice).depositERC20(await token.getAddress(), depositAmount)
            )
                .to.emit(saveAsset, "DepositSuccessful")
                .withArgs(alice.address, depositAmount, "ERC20");
        });

        it("Should reject zero-value ERC20 deposits", async function () {
            const { saveAsset, token, alice } = await loadFixture(deploySaveAssetFixture);

            await expect(
                saveAsset.connect(alice).depositERC20(await token.getAddress(), 0)
            ).to.be.revertedWith("Can't deposit zero value");
        });

        it("Should revert ERC20 deposit if allowance is insufficient", async function () {
            const { saveAsset, token, alice } = await loadFixture(deploySaveAssetFixture);
            const depositAmount = ethers.parseEther("100");

            // No approval given
            await expect(
                saveAsset.connect(alice).depositERC20(await token.getAddress(), depositAmount)
            ).to.be.reverted;
        });

        it("Should track ERC20 balances per user independently", async function () {
            const { saveAsset, token, alice, bob } = await loadFixture(deploySaveAssetFixture);

            await token.connect(alice).approve(await saveAsset.getAddress(), ethers.parseEther("100"));
            await saveAsset.connect(alice).depositERC20(await token.getAddress(), ethers.parseEther("100"));

            await token.connect(bob).approve(await saveAsset.getAddress(), ethers.parseEther("200"));
            await saveAsset.connect(bob).depositERC20(await token.getAddress(), ethers.parseEther("200"));

            expect(
                await saveAsset.connect(alice).getERC20Balance(await token.getAddress())
            ).to.equal(ethers.parseEther("100"));
            expect(
                await saveAsset.connect(bob).getERC20Balance(await token.getAddress())
            ).to.equal(ethers.parseEther("200"));
        });

        it("Should accumulate multiple ERC20 deposits", async function () {
            const { saveAsset, token, alice } = await loadFixture(deploySaveAssetFixture);

            await token.connect(alice).approve(await saveAsset.getAddress(), ethers.parseEther("300"));
            await saveAsset.connect(alice).depositERC20(await token.getAddress(), ethers.parseEther("100"));
            await saveAsset.connect(alice).depositERC20(await token.getAddress(), ethers.parseEther("200"));

            expect(
                await saveAsset.connect(alice).getERC20Balance(await token.getAddress())
            ).to.equal(ethers.parseEther("300"));
        });
    });

    describe("ERC20 Withdrawals", function () {
        it("Should allow a user to withdraw their ERC20 tokens", async function () {
            const { saveAsset, token, alice } = await loadFixture(deploySaveAssetFixture);
            const depositAmount = ethers.parseEther("100");
            const withdrawAmount = ethers.parseEther("50");

            await token.connect(alice).approve(await saveAsset.getAddress(), depositAmount);
            await saveAsset.connect(alice).depositERC20(await token.getAddress(), depositAmount);
            await saveAsset.connect(alice).withdrawERC20(await token.getAddress(), withdrawAmount);

            expect(
                await saveAsset.connect(alice).getERC20Balance(await token.getAddress())
            ).to.equal(ethers.parseEther("50"));
        });

        it("Should transfer ERC20 tokens back to user's wallet", async function () {
            const { saveAsset, token, alice } = await loadFixture(deploySaveAssetFixture);
            const depositAmount = ethers.parseEther("100");

            await token.connect(alice).approve(await saveAsset.getAddress(), depositAmount);
            await saveAsset.connect(alice).depositERC20(await token.getAddress(), depositAmount);

            const balanceBefore = await token.balanceOf(alice.address);
            await saveAsset.connect(alice).withdrawERC20(await token.getAddress(), depositAmount);
            const balanceAfter = await token.balanceOf(alice.address);

            expect(balanceAfter - balanceBefore).to.equal(depositAmount);
        });

        it("Should emit WithdrawalSuccessful event on ERC20 withdrawal", async function () {
            const { saveAsset, token, alice } = await loadFixture(deploySaveAssetFixture);
            const depositAmount = ethers.parseEther("100");

            await token.connect(alice).approve(await saveAsset.getAddress(), depositAmount);
            await saveAsset.connect(alice).depositERC20(await token.getAddress(), depositAmount);

            await expect(
                saveAsset.connect(alice).withdrawERC20(await token.getAddress(), depositAmount)
            )
                .to.emit(saveAsset, "WithdrawalSuccessful")
                .withArgs(alice.address, depositAmount, "ERC20", "0x");
        });

        it("Should revert when withdrawing more ERC20 than deposited", async function () {
            const { saveAsset, token, alice } = await loadFixture(deploySaveAssetFixture);
            const depositAmount = ethers.parseEther("100");

            await token.connect(alice).approve(await saveAsset.getAddress(), depositAmount);
            await saveAsset.connect(alice).depositERC20(await token.getAddress(), depositAmount);

            await expect(
                saveAsset.connect(alice).withdrawERC20(await token.getAddress(), ethers.parseEther("200"))
            ).to.be.revertedWith("Insufficient funds");
        });

        it("Should revert when withdrawing ERC20 with no balance", async function () {
            const { saveAsset, token, alice } = await loadFixture(deploySaveAssetFixture);

            await expect(
                saveAsset.connect(alice).withdrawERC20(await token.getAddress(), ethers.parseEther("1"))
            ).to.be.revertedWith("Insufficient funds");
        });

        it("Should allow full withdrawal of ERC20 balance", async function () {
            const { saveAsset, token, alice } = await loadFixture(deploySaveAssetFixture);
            const depositAmount = ethers.parseEther("100");

            await token.connect(alice).approve(await saveAsset.getAddress(), depositAmount);
            await saveAsset.connect(alice).depositERC20(await token.getAddress(), depositAmount);
            await saveAsset.connect(alice).withdrawERC20(await token.getAddress(), depositAmount);

            expect(
                await saveAsset.connect(alice).getERC20Balance(await token.getAddress())
            ).to.equal(0);
            expect(await token.balanceOf(await saveAsset.getAddress())).to.equal(0);
        });
    });

    describe("Balance Queries", function () {
        it("Should return zero ether balance for new user", async function () {
            const { saveAsset, alice } = await loadFixture(deploySaveAssetFixture);
            expect(await saveAsset.connect(alice).getEtherBalance()).to.equal(0);
        });

        it("Should return zero ERC20 balance for new user", async function () {
            const { saveAsset, token, alice } = await loadFixture(deploySaveAssetFixture);
            expect(
                await saveAsset.connect(alice).getERC20Balance(await token.getAddress())
            ).to.equal(0);
        });

        it("Should return correct contract balance reflecting all user deposits", async function () {
            const { saveAsset, alice, bob } = await loadFixture(deploySaveAssetFixture);

            await saveAsset.connect(alice).depositEther({ value: ethers.parseEther("1") });
            await saveAsset.connect(bob).depositEther({ value: ethers.parseEther("3") });

            expect(await saveAsset.getContractBalance()).to.equal(ethers.parseEther("4"));
        });
    });

    describe("Receive and Fallback", function () {
        it("Should accept plain ether transfers via receive()", async function () {
            const { saveAsset, alice } = await loadFixture(deploySaveAssetFixture);
            const amount = ethers.parseEther("1");

            await alice.sendTransaction({
                to: await saveAsset.getAddress(),
                value: amount,
            });

            expect(await saveAsset.getContractBalance()).to.equal(amount);
        });

        it("Should accept calls with unknown data via fallback()", async function () {
            const { saveAsset, alice } = await loadFixture(deploySaveAssetFixture);

            await expect(
                alice.sendTransaction({
                    to: await saveAsset.getAddress(),
                    data: "0xdeadbeef",
                })
            ).to.not.be.reverted;
        });
    });
});
