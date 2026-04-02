import { BrowserRouter, Navigate, Routes, Route } from "react-router-dom";
import { useAccount } from "wagmi";
import { WagmiProvider } from "wagmi";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { RainbowKitProvider, darkTheme } from "@rainbow-me/rainbowkit";
import { Toaster } from "react-hot-toast";
import "@rainbow-me/rainbowkit/styles.css";

import { wagmiConfig } from "./lib/wagmi";
import Layout from "./components/Layout";
import Dashboard from "./pages/Dashboard";
import Faucet from "./pages/Faucet";
import Transfer from "./pages/Transfer";
import Mint from "./pages/Mint";
import Gallery from "./pages/Gallery";
import { useIsMobile } from "./hooks/useIsMobile";
import { useUserBalance } from "./hooks/useUserBalance";

const queryClient = new QueryClient();

function OwnerOnly({ children }: { children: JSX.Element }) {
  const { address } = useAccount();
  const { isOwner, isLoading } = useUserBalance(address);

  if (isLoading) return null;
  if (!isOwner) return <Navigate to="/" replace />;
  return children;
}

function NonOwnerOnly({ children }: { children: JSX.Element }) {
  const { address } = useAccount();
  const { isOwner, isLoading } = useUserBalance(address);

  if (isLoading) return null;
  if (isOwner) return <Navigate to="/" replace />;
  return children;
}

export default function App() {
  const isMobile = useIsMobile();

  return (
    <WagmiProvider config={wagmiConfig}>
      <QueryClientProvider client={queryClient}>
        <RainbowKitProvider
          theme={darkTheme({
            accentColor: "#f0c040",
            accentColorForeground: "#0a0a0f",
            borderRadius: "medium",
            fontStack: "system",
          })}
        >
          <BrowserRouter>
            <Layout>
              <Routes>
                <Route path="/"         element={<Dashboard />} />
                <Route path="/faucet"   element={<Faucet />} />
                <Route path="/transfer" element={<Transfer />} />
                <Route path="/mint"     element={<OwnerOnly><Mint /></OwnerOnly>} />
                <Route path="/gallery"  element={<NonOwnerOnly><Gallery /></NonOwnerOnly>} />
              </Routes>
            </Layout>
          </BrowserRouter>
          <Toaster
            position={isMobile ? "bottom-center" : "bottom-right"}
            toastOptions={{
              style: {
                background: "var(--surface2)",
                color: "var(--text)",
                border: "1px solid var(--border2)",
                fontFamily: "'Space Mono', monospace",
                fontSize: isMobile ? 12 : 13,
              },
              success: { iconTheme: { primary: "#f0c040", secondary: "#0a0a0f" } },
              error:   { iconTheme: { primary: "#f04060", secondary: "#fff" } },
            }}
          />
        </RainbowKitProvider>
      </QueryClientProvider>
    </WagmiProvider>
  );
}