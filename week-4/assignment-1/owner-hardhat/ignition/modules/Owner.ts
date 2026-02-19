import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("OwnerModule", (m) => {
  const owner = m.contract("Owner");
  return { owner };
});
