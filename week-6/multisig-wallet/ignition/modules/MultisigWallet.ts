import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("MultisigWalletModule", (m) => {
  const multisigWallet = m.contract("MultisigWallet", [m.getParameter<string[]>("owners")]);
  return { multisigWallet };
});
