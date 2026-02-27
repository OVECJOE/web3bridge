import { expect } from "chai";
import { network } from "hardhat";

type Network = Awaited<ReturnType<typeof network.connect>>;

describe("MultisigWallet", function () {
  let ethers: Network["ethers"];
  let networkHelpers: Network["networkHelpers"];

  before(async () => {
    ({ ethers, networkHelpers } = await network.connect());
  });

  async function deal(address: string, amountInEth: string) {
    const amount = ethers.parseEther(amountInEth);
    await ethers.provider.send("hardhat_setBalance", [
      address,
      `0x${amount.toString(16)}`,
    ]);
  }

  async function deployMultisigWalletFixture() {
    const [alice, bob, charlie, dave] = await ethers.getSigners();

    await deal(alice.address, "100");
    await deal(bob.address, "100");
    await deal(charlie.address, "100");

    const MultiSigWallet = await ethers.getContractFactory("MultiSigWallet");
    const multisig = await MultiSigWallet.deploy();
    await multisig.waitForDeployment();

    // OZ v5 Initializable stores its state at this slot.
    // _disableInitializers() sets it to type(uint64).max; zeroing it
    // lets us call initialize() as a proxy would.
    const INITIALIZABLE_SLOT =
      "0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00";
    await ethers.provider.send("hardhat_setStorageAt", [
      await multisig.getAddress(),
      INITIALIZABLE_SLOT,
      "0x0000000000000000000000000000000000000000000000000000000000000000",
    ]);

    await multisig.initialize([alice.address, bob.address], 2n);

    await deal(await multisig.getAddress(), "1000");

    return { multisig, alice, bob, charlie, dave };
  }

  describe("getOwnersCount", async () => {
    it("Should return the number of owners", async () => {
      const { multisig, alice } = await networkHelpers.loadFixture(deployMultisigWalletFixture);
      const count = await multisig.connect(alice).getOwnersCount();
      expect(count).to.equal(2n);
    });

    it("Should allow anyone to see the owners count", async () => {
      const { multisig } = await networkHelpers.loadFixture(deployMultisigWalletFixture);
      const count = await multisig.getOwnersCount();
      expect(count).to.equal(2n);
    });
  });

  describe("getOwners", async () => {
    it("Should return the list of owners", async () => {
      const { multisig, alice, bob } = await networkHelpers.loadFixture(deployMultisigWalletFixture);
      const owners = await multisig.connect(alice).getOwners();
      expect(owners).to.have.members([alice.address, bob.address]);
    });

    it("Should not allow non-owners to see the list of owners", async () => {
      const { multisig, dave } = await networkHelpers.loadFixture(deployMultisigWalletFixture);
      await expect(multisig.connect(dave).getOwners()).to.be.revertedWithCustomError(multisig, "NotOwner");
    });
  });

  describe("addOwner", async () => {
    it("Should add an owner", async () => {
      const { multisig, alice, charlie } = await networkHelpers.loadFixture(deployMultisigWalletFixture);
      await multisig.connect(alice).addOwner(charlie.address);
      const owners = await multisig.connect(alice).getOwners();
      expect(owners).to.contain(charlie.address);
      expect(owners.length).to.be.equal(3);
    });

    it("Should not allow non-contract-owner to add an owner", async () => {
      const { multisig, bob, charlie } = await networkHelpers.loadFixture(deployMultisigWalletFixture);
      await expect(multisig.connect(bob).addOwner(charlie.address)).to.be.revertedWithCustomError(multisig, "NotContractOwner");
    });

    it("Should not allow adding an owner if the owner already exists", async () => {
      const { multisig, alice, bob } = await networkHelpers.loadFixture(deployMultisigWalletFixture);
      await expect(multisig.connect(alice).addOwner(bob.address)).to.be.revertedWithCustomError(multisig, "AlreadyOwner");
    });

    it("Should not allow adding a zero address owner", async () => {
      const { multisig, alice } = await networkHelpers.loadFixture(deployMultisigWalletFixture);
      await expect(
        multisig.connect(alice).addOwner("0x0000000000000000000000000000000000000000")
      ).to.be.revertedWithCustomError(multisig, "InvalidOwner");
    });

    it("Should not allow adding an owner if the wallet has reached MAX_OWNERS (5)", async () => {
      const [, , , , eve, frank, grace] = await ethers.getSigners();
      const { multisig, alice } = await networkHelpers.loadFixture(deployMultisigWalletFixture);
      await multisig.connect(alice).addOwner(eve.address);
      await multisig.connect(alice).addOwner(frank.address);
      await multisig.connect(alice).addOwner(grace.address);
      const fresh = ethers.Wallet.createRandom();
      await expect(multisig.connect(alice).addOwner(fresh.address)).to.be.revertedWithCustomError(multisig, "MaxOwnersCountReached");
    });
  });

  describe("removeOwner", async () => {
    it("Should remove an owner", async () => {
      const { multisig, alice, charlie } = await networkHelpers.loadFixture(deployMultisigWalletFixture);
      await multisig.connect(alice).addOwner(charlie.address);
      await multisig.connect(alice).removeOwner(charlie.address);
      const owners = await multisig.connect(alice).getOwners();
      expect(owners).to.not.contain(charlie.address);
      expect(owners.length).to.be.equal(2);
    });

    it("Should not allow a non-contract-owner to remove an owner", async () => {
      const { multisig, bob, charlie } = await networkHelpers.loadFixture(deployMultisigWalletFixture);
      await expect(multisig.connect(bob).removeOwner(charlie.address)).to.be.revertedWithCustomError(multisig, "NotContractOwner");
    });

    it("Should not allow removing the first owner (index 0)", async () => {
      const { multisig, alice, charlie } = await networkHelpers.loadFixture(deployMultisigWalletFixture);
      await multisig.connect(alice).addOwner(charlie.address);
      await expect(multisig.connect(alice).removeOwner(alice.address)).to.be.revertedWithCustomError(multisig, "OperationUnauthorized");
    });

    it("Should not allow removing down to zero owners", async () => {
      const { multisig, alice, bob } = await networkHelpers.loadFixture(deployMultisigWalletFixture);
      await multisig.connect(alice).removeOwner(bob.address);
      const owners = await multisig.connect(alice).getOwners();
      expect(owners.length).to.equal(1);
    });

    it("Should emit OwnerRemoved event", async () => {
      const { multisig, alice, charlie } = await networkHelpers.loadFixture(deployMultisigWalletFixture);
      await multisig.connect(alice).addOwner(charlie.address);
      await expect(multisig.connect(alice).removeOwner(charlie.address))
        .to.emit(multisig, "OwnerRemoved")
        .withArgs(charlie.address);
    });
  });

  describe("replaceOwner", async () => {
    it("Should replace an owner", async () => {
      const { multisig, alice, bob, charlie } = await networkHelpers.loadFixture(deployMultisigWalletFixture);
      await multisig.connect(alice).replaceOwner(bob.address, charlie.address);
      const owners = await multisig.connect(alice).getOwners();
      expect(owners).to.contain(charlie.address);
      expect(owners).to.not.contain(bob.address);
      expect(owners.length).to.be.equal(2);
    });

    it("Should not replace with an existing owner", async () => {
      const { multisig, alice, bob } = await networkHelpers.loadFixture(deployMultisigWalletFixture);
      await expect(multisig.connect(alice).replaceOwner(bob.address, alice.address)).to.be.revertedWithCustomError(multisig, "AlreadyOwner");
    });

    it("Should not replace with a zero address", async () => {
      const { multisig, alice, bob } = await networkHelpers.loadFixture(deployMultisigWalletFixture);
      await expect(
        multisig.connect(alice).replaceOwner(bob.address, "0x0000000000000000000000000000000000000000")
      ).to.be.revertedWithCustomError(multisig, "InvalidOwner");
    });

    it("Should fail when old owner is not an owner", async () => {
      const { multisig, alice, bob, charlie } = await networkHelpers.loadFixture(deployMultisigWalletFixture);
      await expect(multisig.connect(alice).replaceOwner(charlie.address, bob.address)).to.be.revertedWithCustomError(multisig, "NotOwner");
    });

    it("Should emit OwnerRemoved and OwnerAdded events", async () => {
      const { multisig, alice, bob, charlie } = await networkHelpers.loadFixture(deployMultisigWalletFixture);
      await expect(multisig.connect(alice).replaceOwner(bob.address, charlie.address))
        .to.emit(multisig, "OwnerRemoved").withArgs(bob.address)
        .to.emit(multisig, "OwnerAdded").withArgs(charlie.address);
    });
  });

  describe("initiateTransaction", async () => {
    it("Should allow an owner to initiate a transaction", async () => {
      const { multisig, alice, bob } = await networkHelpers.loadFixture(deployMultisigWalletFixture);
      await multisig.connect(alice).initiateTransaction(bob.address, 1n, "0x");
      expect(await multisig.getTxCount()).to.be.equal(1n);
      const tx = await multisig.connect(alice).getTransaction(0n);
      expect(tx.to).to.equal(bob.address);
      expect(tx.creator).to.equal(alice.address);
      expect(tx.value).to.equal(1n);
    });

    it("Should ensure recipient is not a zero address", async () => {
      const { multisig, alice } = await networkHelpers.loadFixture(deployMultisigWalletFixture);
      await expect(
        multisig.connect(alice).initiateTransaction("0x0000000000000000000000000000000000000000", 1n, "0x")
      ).to.be.revertedWithCustomError(multisig, "InvalidAddress");
    });

    it("Should not allow non-owner to initiate a transaction", async () => {
      const { multisig, alice, dave } = await networkHelpers.loadFixture(deployMultisigWalletFixture);
      await expect(multisig.connect(dave).initiateTransaction(alice.address, 1n, "0x")).to.be.revertedWithCustomError(multisig, "NotOwner");
    });

    it("Should emit the TransactionSubmitted event", async () => {
      const { multisig, alice, bob } = await networkHelpers.loadFixture(deployMultisigWalletFixture);
      const timestamp = (await networkHelpers.time.increase(1772062166)) + 1;
      await expect(multisig.connect(alice).initiateTransaction(bob.address, 1n, "0x"))
        .to.emit(multisig, "TransactionSubmitted").withArgs(alice.address, 0n, timestamp);
    });
  });

  describe("signTransaction", async () => {
    it("Should allow an owner to sign (approve) a transaction", async () => {
      const { multisig, alice, bob } = await networkHelpers.loadFixture(deployMultisigWalletFixture);
      await multisig.connect(alice).initiateTransaction(bob.address, 1n, "0x");
      await multisig.connect(bob).signTransaction(0n);
      const tx = await multisig.connect(alice).getTransaction(0n);
      expect(tx.approvals).to.be.equal(1);
      expect(tx.approvers[0]).to.be.equal(bob.address);
    });

    it("Should not allow non-owner to sign a transaction", async () => {
      const { multisig, alice, bob, dave } = await networkHelpers.loadFixture(deployMultisigWalletFixture);
      await multisig.connect(alice).initiateTransaction(bob.address, 1n, "0x");
      await expect(multisig.connect(dave).signTransaction(0n)).to.be.revertedWithCustomError(multisig, "NotOwner");
    });

    it("Should not allow the creator to sign their own transaction", async () => {
      const { multisig, alice, bob } = await networkHelpers.loadFixture(deployMultisigWalletFixture);
      await multisig.connect(alice).initiateTransaction(bob.address, 1n, "0x");
      await expect(multisig.connect(alice).signTransaction(0n)).to.be.revertedWithCustomError(multisig, "OperationUnauthorized");
    });

    it("Should mark transaction APPROVED when threshold is reached", async () => {
      const { multisig, alice, bob, charlie } = await networkHelpers.loadFixture(deployMultisigWalletFixture);
      await multisig.connect(alice).addOwner(charlie.address);
      await multisig.connect(alice).initiateTransaction(bob.address, 1n, "0x");
      await multisig.connect(bob).signTransaction(0n);
      await multisig.connect(charlie).signTransaction(0n);
      const tx = await multisig.connect(alice).getTransaction(0n);
      expect(tx.status).to.equal(1n);
    });

    it("Should not sign an already APPROVED transaction", async () => {
      const { multisig, alice, bob, charlie } = await networkHelpers.loadFixture(deployMultisigWalletFixture);
      await multisig.connect(alice).addOwner(charlie.address);
      await multisig.connect(alice).initiateTransaction(bob.address, 1n, "0x");
      await multisig.connect(bob).signTransaction(0n);
      await multisig.connect(charlie).signTransaction(0n);
      await expect(multisig.connect(alice).signTransaction(0n)).to.be.revertedWithCustomError(multisig, "NotPendingTransaction");
    });

    it("Should emit TransactionSigned event", async () => {
      const { multisig, alice, bob } = await networkHelpers.loadFixture(deployMultisigWalletFixture);
      await multisig.connect(alice).initiateTransaction(bob.address, 1n, "0x");
      await expect(multisig.connect(bob).signTransaction(0n))
        .to.emit(multisig, "TransactionSigned").withArgs(bob.address, 0n);
    });
  });

  describe("unsignTransaction", async () => {
    it("Should allow an owner to unsign a transaction they signed", async () => {
      const { multisig, alice, bob } = await networkHelpers.loadFixture(deployMultisigWalletFixture);
      await multisig.connect(alice).initiateTransaction(bob.address, 1n, "0x");
      await multisig.connect(bob).signTransaction(0n);
      await multisig.connect(bob).unsignTransaction(0n);
      const tx = await multisig.connect(alice).getTransaction(0n);
      expect(tx.approvals).to.equal(0);
    });

    it("Should not allow unsigning if not previously approved", async () => {
      const { multisig, alice, bob } = await networkHelpers.loadFixture(deployMultisigWalletFixture);
      await multisig.connect(alice).initiateTransaction(bob.address, 1n, "0x");
      await expect(multisig.connect(bob).unsignTransaction(0n)).to.be.revertedWithCustomError(multisig, "NotApprover");
    });

    it("Should emit TransactionUnsigned event", async () => {
      const { multisig, alice, bob } = await networkHelpers.loadFixture(deployMultisigWalletFixture);
      await multisig.connect(alice).initiateTransaction(bob.address, 1n, "0x");
      await multisig.connect(bob).signTransaction(0n);
      await expect(multisig.connect(bob).unsignTransaction(0n))
        .to.emit(multisig, "TransactionUnsigned").withArgs(bob.address, 0n);
    });
  });

  describe("rejectTransaction", async () => {
    it("Should reject a transaction", async () => {
      const { multisig, alice, bob } = await networkHelpers.loadFixture(deployMultisigWalletFixture);
      await multisig.connect(alice).initiateTransaction(bob.address, 1n, "0x");
      await multisig.connect(bob).rejectTransaction(0n);
      const tx = await multisig.connect(alice).getTransaction(0n);
      expect(tx.rejections).to.be.equal(1);
      expect(tx.rejectors[0]).to.be.equal(bob.address);
    });

    it("Should not allow non-owner to reject a transaction", async () => {
      const { multisig, alice, bob, dave } = await networkHelpers.loadFixture(deployMultisigWalletFixture);
      await multisig.connect(alice).initiateTransaction(bob.address, 1n, "0x");
      await expect(multisig.connect(dave).rejectTransaction(0n)).to.be.revertedWithCustomError(multisig, "NotOwner");
    });

    it("Should not allow the creator to reject their own transaction", async () => {
      const { multisig, alice, bob } = await networkHelpers.loadFixture(deployMultisigWalletFixture);
      await multisig.connect(alice).initiateTransaction(bob.address, 1n, "0x");
      await expect(multisig.connect(alice).rejectTransaction(0n)).to.be.revertedWithCustomError(multisig, "OperationUnauthorized");
    });

    it("Should mark transaction REJECTED when threshold is reached", async () => {
      const { multisig, alice, bob, charlie } = await networkHelpers.loadFixture(deployMultisigWalletFixture);
      await multisig.connect(alice).addOwner(charlie.address);
      await multisig.connect(alice).initiateTransaction(bob.address, 1n, "0x");
      await multisig.connect(bob).rejectTransaction(0n);
      await multisig.connect(charlie).rejectTransaction(0n);
      const tx = await multisig.connect(alice).getTransaction(0n);
      expect(tx.status).to.equal(2n);
    });

    it("Should not reject an already REJECTED transaction", async () => {
      const { multisig, alice, bob, charlie } = await networkHelpers.loadFixture(deployMultisigWalletFixture);
      await multisig.connect(alice).addOwner(charlie.address);
      await multisig.connect(alice).initiateTransaction(bob.address, 1n, "0x");
      await multisig.connect(bob).rejectTransaction(0n);
      await multisig.connect(charlie).rejectTransaction(0n);
      await expect(multisig.connect(alice).rejectTransaction(0n)).to.be.revertedWithCustomError(multisig, "NotPendingTransaction");
    });

    it("Should emit TransactionIndividuallyRejected event", async () => {
      const { multisig, alice, bob } = await networkHelpers.loadFixture(deployMultisigWalletFixture);
      await multisig.connect(alice).initiateTransaction(bob.address, 1n, "0x");
      await expect(multisig.connect(bob).rejectTransaction(0n))
        .to.emit(multisig, "TransactionIndividuallyRejected").withArgs(bob.address, 0n);
    });
  });

  describe("deposit", async () => {
    it("Should allow an owner to deposit to the wallet", async () => {
      const { multisig, alice } = await networkHelpers.loadFixture(deployMultisigWalletFixture);
      const aliceBalanceBefore = (await alice.provider?.getBalance(alice.address)) || 0n;
      const contractBalanceBefore = await multisig.getWalletBalance();
      await multisig.connect(alice).deposit({ value: ethers.parseEther("10") });
      expect((await alice.provider?.getBalance(alice.address)) || 0n).to.be.lt(aliceBalanceBefore);
      expect(await multisig.connect(alice).getWalletBalance()).to.be.equal(contractBalanceBefore + ethers.parseEther("10"));
    });

    it("Should not allow non-owner to deposit to the wallet", async () => {
      const { multisig, dave } = await networkHelpers.loadFixture(deployMultisigWalletFixture);
      await expect(multisig.connect(dave).deposit({ value: ethers.parseEther("10") })).to.be.revertedWithCustomError(multisig, "NotOwner");
    });

    it("Should not deposit zero amount", async () => {
      const { multisig, alice } = await networkHelpers.loadFixture(deployMultisigWalletFixture);
      await expect(multisig.connect(alice).deposit({ value: ethers.parseEther("0") })).to.be.revertedWith("Invalid amount");
    });

    it("Should emit the DepositMade event", async () => {
      const { multisig, alice } = await networkHelpers.loadFixture(deployMultisigWalletFixture);
      await expect(multisig.connect(alice).deposit({ value: ethers.parseEther("10") }))
        .to.emit(multisig, "DepositMade").withArgs(alice.address, ethers.parseEther("10"));
    });

    it("Should track the deposit amount per owner", async () => {
      const { multisig, alice } = await networkHelpers.loadFixture(deployMultisigWalletFixture);
      await multisig.connect(alice).deposit({ value: ethers.parseEther("5") });
      const amount = await multisig.connect(alice).getDepositAmount(alice.address);
      expect(amount).to.equal(ethers.parseEther("5"));
    });
  });

  describe("execute", async () => {
    it("Should allow the creator to execute an approved transaction", async () => {
      const { multisig, alice, bob, charlie } = await networkHelpers.loadFixture(deployMultisigWalletFixture);
      await multisig.connect(alice).addOwner(charlie.address);
      await multisig.connect(alice).initiateTransaction(bob.address, 10n, "0x");
      await multisig.connect(bob).signTransaction(0n);
      await multisig.connect(charlie).signTransaction(0n);
      const bobBalanceBefore = (await bob.provider?.getBalance(bob.address)) || 0n;
      await multisig.connect(alice).execute(0n);
      expect(await bob.provider?.getBalance(bob.address)).to.be.equal(bobBalanceBefore + 10n);
    });

    it("Should not allow non-creator to execute a transaction", async () => {
      const { multisig, alice, bob, charlie } = await networkHelpers.loadFixture(deployMultisigWalletFixture);
      await multisig.connect(alice).addOwner(charlie.address);
      await multisig.connect(alice).initiateTransaction(bob.address, 10n, "0x");
      await multisig.connect(bob).signTransaction(0n);
      await multisig.connect(charlie).signTransaction(0n);
      await expect(multisig.connect(bob).execute(0n)).to.be.revertedWith("Not the transaction owner");
    });

    it("Should not execute a PENDING transaction", async () => {
      const { multisig, alice, bob, charlie } = await networkHelpers.loadFixture(deployMultisigWalletFixture);
      await multisig.connect(alice).addOwner(charlie.address);
      await multisig.connect(alice).initiateTransaction(bob.address, 10n, "0x");
      await multisig.connect(bob).signTransaction(0n);
      await expect(multisig.connect(alice).execute(0n)).to.be.revertedWith("Transaction not approved");
    });

    it("Should not execute a transaction that was already executed", async () => {
      const { multisig, alice, bob, charlie } = await networkHelpers.loadFixture(deployMultisigWalletFixture);
      await multisig.connect(alice).addOwner(charlie.address);
      await multisig.connect(alice).initiateTransaction(bob.address, 10n, "0x");
      await multisig.connect(bob).signTransaction(0n);
      await multisig.connect(charlie).signTransaction(0n);
      await multisig.connect(alice).execute(0n);
      await expect(multisig.connect(alice).execute(0n)).to.be.revertedWith("Transaction already executed");
    });

    it("Should not execute a REJECTED transaction", async () => {
      const { multisig, alice, bob, charlie } = await networkHelpers.loadFixture(deployMultisigWalletFixture);
      await multisig.connect(alice).addOwner(charlie.address);
      await multisig.connect(alice).initiateTransaction(bob.address, 10n, "0x");
      await multisig.connect(bob).rejectTransaction(0n);
      await multisig.connect(charlie).rejectTransaction(0n);
      await expect(multisig.connect(alice).execute(0n)).to.be.revertedWith("Transaction not approved");
    });

    it("Should emit TransactionExecuted event", async () => {
      const { multisig, alice, bob, charlie } = await networkHelpers.loadFixture(deployMultisigWalletFixture);
      await multisig.connect(alice).addOwner(charlie.address);
      await multisig.connect(alice).initiateTransaction(bob.address, 10n, "0x");
      await multisig.connect(bob).signTransaction(0n);
      await multisig.connect(charlie).signTransaction(0n);
      await expect(multisig.connect(alice).execute(0n))
        .to.emit(multisig, "TransactionExecuted").withArgs(0n);
    });
  });

  describe("view helpers", async () => {
    it("getWalletBalance should return contract balance", async () => {
      const { multisig, alice } = await networkHelpers.loadFixture(deployMultisigWalletFixture);
      const balance = await multisig.connect(alice).getWalletBalance();
      expect(balance).to.equal(ethers.parseEther("1000"));
    });

    it("getTxCount should increase with each initiated transaction", async () => {
      const { multisig, alice, bob } = await networkHelpers.loadFixture(deployMultisigWalletFixture);
      expect(await multisig.getTxCount()).to.equal(0n);
      await multisig.connect(alice).initiateTransaction(bob.address, 1n, "0x");
      expect(await multisig.getTxCount()).to.equal(1n);
      await multisig.connect(alice).initiateTransaction(bob.address, 1n, "0x");
      expect(await multisig.getTxCount()).to.equal(2n);
    });

    it("getDeposit should return the deposit details of an owner", async () => {
      const { multisig, alice } = await networkHelpers.loadFixture(deployMultisigWalletFixture);
      await multisig.connect(alice).deposit({ value: ethers.parseEther("3") });
      const deposit = await multisig.connect(alice).getDeposit(alice.address);
      expect(deposit.creator).to.equal(alice.address);
      expect(deposit.amount).to.equal(ethers.parseEther("3"));
    });
  });
});
