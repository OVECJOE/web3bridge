import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("AttendanceRegistryModule", (m) => {
  const registry = m.contract("AttendanceRegistry");
  return { registry };
});
