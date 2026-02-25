import { expect } from "chai";
import { network } from "hardhat";

type Network = Awaited<ReturnType<typeof network.connect>>;

describe("MultisigWallet", function () {
  let ethers: Network['ethers'];
  let loadFixture: Network['networkHelpers']['loadFixture'];

  before(async () => {
    const { ethers: e, networkHelpers: n } = await network.connect();
    ethers = e;
    loadFixture = n.loadFixture;
  });

  async function deal(address: string, amountInEth: string) {
    const amount = ethers.parseEther(amountInEth);
    await ethers.provider.send("hardhat_setBalance", [
      address,
      `0x${amount.toString(16)}`
    ]);
  }

  async function deployMultisigWalletFixture() {
    const [alice, bob, charlie, dave] = await ethers.getSigners();

    // Fund the owners
    await deal(alice.address, "100");
    await deal(bob.address, "100");
    await deal(charlie.address, "100");

    const owners = [alice.address, bob.address];
    const multisig = await ethers.deployContract("MultiSigWallet", [owners]);

    return { multisig, alice, bob, charlie, dave };
  }

  describe("getOwnerCount", async () => {
    it("Should return the number of owners", async () => {
      const { multisig, alice } = await loadFixture(deployMultisigWalletFixture);
      const count = await multisig.connect(alice).getOwnerCount();
      expect(count).to.equal(2n);
    });

    it("Should allow anyone to see the owners count", async () => {
      const { multisig } = await loadFixture(deployMultisigWalletFixture);
      const count = await multisig.getOwnerCount();
      expect(count).to.equal(2n);
    });
  })

  describe("getOwners", async () => {
    it("Should return the list of owners", async () => {
      const { multisig, alice, bob } = await loadFixture(deployMultisigWalletFixture);
      const owners = await multisig.connect(alice).getOwners();
      expect(owners).to.have.members([alice.address, bob.address]);
    });

    it("Should not allow non-owners to see the list of owners", async () => {
      const { multisig, dave } = await loadFixture(deployMultisigWalletFixture);
      await expect(multisig.connect(dave).getOwners()).to.be.revertedWith("Not an owner");
    })
  })

  describe("addOwner", async () => {
    it("Should add an owner", async () => {
      const { multisig, alice, charlie } = await loadFixture(deployMultisigWalletFixture);
      await multisig.connect(alice).addOwner(charlie.address);
      const owners = await multisig.connect(alice).getOwners();

      expect(owners).to.contain(charlie.address);
      expect(owners.length).to.be.equal(3);
    })

    it("Should not allow non-owners to add an owner", async () => {
      const { multisig, dave, charlie } = await loadFixture(deployMultisigWalletFixture);
      await expect(multisig.connect(dave).addOwner(charlie.address)).to.be.revertedWith("Not an owner");
    })

    it("Should not allow adding an owner if the owner already exists", async () => {
      const { multisig, alice, bob } = await loadFixture(deployMultisigWalletFixture);
      await expect(multisig.connect(alice).addOwner(bob.address)).to.be.revertedWith("Already an owner");
    })

    it("Should not allow adding an owner if the owner is the zero address", async () => {
      const { multisig, alice } = await loadFixture(deployMultisigWalletFixture);
      await expect(multisig.connect(alice).addOwner("0x0000000000000000000000000000000000000000")).to.be.revertedWith("Invalid owner");
    })

    it("Should not allow adding an owner if the wallet has 3 owners", async () => {
      const { multisig, alice, charlie, dave } = await loadFixture(deployMultisigWalletFixture);
      await multisig.connect(alice).addOwner(charlie.address);
      await expect(multisig.connect(alice).addOwner(dave.address)).to.be.revertedWith("Max 3 owners");
    })
  })

  describe("removeOwner", async () => {
    it("Should remove an owner", async () => {
      const { multisig, alice, charlie } = await loadFixture(deployMultisigWalletFixture);

      await multisig.connect(alice).addOwner(charlie.address);
      await multisig.connect(alice).removeOwner(charlie.address);

      const owners = await multisig.connect(alice).getOwners();
      expect(owners).to.not.contain(charlie.address);
      expect(owners.length).to.be.equal(2n);
    });

    it("Should not allow a non-owner to remove an owner", async () => {
      const { multisig, alice, charlie, dave } = await loadFixture(deployMultisigWalletFixture);
      await multisig.connect(alice).addOwner(charlie.address);
      await expect(multisig.connect(dave).removeOwner(charlie.address)).to.be.revertedWith("Not an owner");
    });

    it("Should not allow removing the first owner", async () => {
      const { multisig, alice, charlie } = await loadFixture(deployMultisigWalletFixture);
      await multisig.connect(alice).addOwner(charlie.address);
      await expect(multisig.connect(charlie).removeOwner(alice.address)).to.be.revertedWith("Operation unauthorized");
    })

    it("Should not allow removing an owner if count is 2 or less", async () => {
      const { multisig, alice, bob } = await loadFixture(deployMultisigWalletFixture);
      await expect(multisig.connect(alice).removeOwner(bob.address)).to.be.revertedWith("Min 2 owners");
    })
  })

  describe("replaceOwner", async () => {
    it("Should replace an owner", async () => {
      const { multisig, alice, bob, charlie } = await loadFixture(deployMultisigWalletFixture);
      await multisig.connect(alice).replaceOwner(bob.address, charlie.address);

      const owners = await multisig.connect(alice).getOwners();
      expect(owners).to.contain(charlie.address);
      expect(owners).to.not.contain(bob.address);
      expect(owners.length).to.be.equal(2n);
    });

    it("Should not replace with an existing owner", async () => {
      const { multisig, alice, bob } = await loadFixture(deployMultisigWalletFixture);
      await expect(multisig.connect(alice).replaceOwner(bob.address, alice.address)).to.be.revertedWith("Already an owner");
    })

    it("Should not replace with a zero address", async () => {
      const { multisig, alice, bob } = await loadFixture(deployMultisigWalletFixture);
      await expect(multisig.replaceOwner(bob.address, "0x0000000000000000000000000000000000000000")).to.be.revertedWith("Invalid owner");
    })

    it("Should fail when old owner is not an owner", async () => {
      const { multisig, alice, bob, charlie } = await loadFixture(deployMultisigWalletFixture);
      await expect(multisig.replaceOwner(charlie.address, bob.address)).to.be.revertedWith("Not an owner");
    })

    it("Should emit two events", async () => {
      const { multisig, alice, bob, charlie, dave } = await loadFixture(deployMultisigWalletFixture);

      const resultPromise = multisig.connect(alice).replaceOwner(bob.address, charlie.address);
      await expect(resultPromise).to.emit(multisig, "OwnerRemoved").withArgs(bob.address).to.emit(multisig, "OwnerAdded").withArgs(charlie.address);
    })
  })
});
