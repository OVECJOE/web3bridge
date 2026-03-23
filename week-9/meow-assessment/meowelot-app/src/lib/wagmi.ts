import { getDefaultConfig } from "@rainbow-me/rainbowkit";
import { liskSepolia } from "./contracts";

const walletConnectProjectId = import.meta.env.VITE_WALLETCONNECT_PROJECT_ID;
const appUrl = import.meta.env.VITE_APP_URL || "http://localhost:5173";
const appIcon = import.meta.env.VITE_APP_ICON || "";

if (!walletConnectProjectId) {
  console.warn("VITE_WALLETCONNECT_PROJECT_ID is missing. Mobile wallets may not appear in the connect modal.");
}

export const wagmiConfig = getDefaultConfig({
  appName: "Meowelot",
  appDescription: "Simple $MEOW token app",
  appUrl,
  appIcon,
  projectId: walletConnectProjectId || "missing-project-id",
  chains: [liskSepolia],
  ssr: false,
});