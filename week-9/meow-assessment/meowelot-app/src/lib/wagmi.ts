import { createConfig, http } from "wagmi";
import { liskSepolia } from "./contracts";

export const wagmiConfig = createConfig({
  chains: [liskSepolia],
  transports: {
    [liskSepolia.id]: http(),
  },
});