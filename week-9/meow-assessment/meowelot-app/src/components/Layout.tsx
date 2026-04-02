import React from "react";
import { NavLink, useLocation } from "react-router-dom";
import { useAccount } from "wagmi";
import { ConnectButton } from "@rainbow-me/rainbowkit";
import { useUserBalance } from "../hooks/useUserBalance";
import { formatMeow, shortenAddress } from "../lib/utils";
import { useIsMobile } from "../hooks/useIsMobile";

const NAV = [
  { to: "/",          label: "Home",            icon: "⬡" },
  { to: "/faucet",    label: "Get Free Tokens", icon: "⌀" },
  { to: "/transfer",  label: "Send Tokens",     icon: "→" },
  { to: "/mint",      label: "Admin Mint",      icon: "✦" },
  { to: "/gallery",   label: "My Collectibles", icon: "◈" },
];

export default function Layout({ children }: { children: React.ReactNode }) {
  const { address, isConnected } = useAccount();
  const { tokenBalance, nftBalance, isOwner } = useUserBalance(address);
  const location = useLocation();
  const isMobile = useIsMobile();
  const [navOpen, setNavOpen] = React.useState(false);

  const navItems = NAV.filter((item) => {
    if (item.to === "/mint") return isConnected && isOwner;
    if (item.to === "/gallery") return !isOwner;
    return true;
  });

  React.useEffect(() => {
    if (!isMobile) setNavOpen(true);
  }, [isMobile]);

  React.useEffect(() => {
    if (isMobile) setNavOpen(false);
  }, [location.pathname, isMobile]);

  return (
    <div style={{ display: "flex", minHeight: "100vh", flexDirection: isMobile ? "column" : "row" }}>
      {/* Sidebar */}
      <aside style={{
        width: isMobile ? "100%" : 220,
        flexShrink: 0,
        background: "var(--surface)",
        borderRight: isMobile ? "none" : "1px solid var(--border)",
        borderBottom: isMobile ? "1px solid var(--border)" : "none",
        padding: isMobile ? "14px 0 10px" : "24px 0",
        display: "flex",
        flexDirection: "column",
        position: isMobile ? "static" : "fixed",
        top: 0,
        left: 0,
        height: isMobile ? "auto" : "100vh",
        zIndex: 100,
      }}>
        {/* Logo */}
        <div style={{
          padding: isMobile ? "0 12px 8px" : "0 24px 32px",
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
          gap: 10,
        }}>
          <div>
            <div style={{
              fontFamily: "Syne",
              fontWeight: 800,
              fontSize: isMobile ? 18 : 16,
              color: "var(--gold)",
              letterSpacing: -0.35,
            }}>
              MEOWELOT
            </div>
            {(!isMobile || navOpen) && (
              <div style={{ fontSize: 11, color: "var(--muted)", marginTop: 2 }}>Friendly token app on Lisk Sepolia</div>
            )}
          </div>
          {isMobile && (
            <button
              type="button"
              onClick={() => setNavOpen(v => !v)}
              aria-expanded={navOpen}
              aria-label={navOpen ? "Collapse navigation" : "Expand navigation"}
              style={{
                border: "1px solid var(--border2)",
                background: "var(--surface2)",
                color: "var(--text)",
                borderRadius: "var(--radius)",
                padding: "6px 10px",
                fontSize: 11,
                fontFamily: "Syne",
                fontWeight: 700,
                lineHeight: 1.1,
              }}
            >
              {navOpen ? "Hide" : "Menu"}
            </button>
          )}
        </div>

        {/* Nav */}
        <nav style={{
          flex: 1,
          display: isMobile && !navOpen ? "none" : (isMobile ? "flex" : "block"),
          padding: isMobile ? "0 8px" : "0 12px",
          overflowX: isMobile ? "auto" : "visible",
          whiteSpace: isMobile ? "nowrap" : "normal",
          gap: isMobile ? 6 : 0,
        }}>
          {navItems.map(({ to, label, icon }) => (
            <NavLink key={to} to={to} end={to === "/"} style={({ isActive }) => ({
              display: "flex", alignItems: "center", gap: isMobile ? 8 : 12,
              padding: isMobile ? "8px 10px" : "10px 12px", borderRadius: "var(--radius)",
              marginBottom: isMobile ? 0 : 4,
              marginRight: isMobile ? 6 : 0,
              textDecoration: "none", transition: "all 0.15s",
              background: isActive ? "rgba(240,192,64,0.1)" : "transparent",
              color: isActive ? "var(--gold)" : "var(--muted)",
              borderLeft: isMobile ? "none" : (isActive ? "2px solid var(--gold)" : "2px solid transparent"),
              borderBottom: isMobile ? (isActive ? "2px solid var(--gold)" : "2px solid transparent") : "none",
            })}>
              <span style={{ fontSize: 16, width: 20, textAlign: "center" }}>{icon}</span>
              <span style={{ fontFamily: "Syne", fontWeight: 600, fontSize: 13, whiteSpace: "nowrap" }}>{label}</span>
            </NavLink>
          ))}
        </nav>

        {/* Wallet mini panel */}
        {isConnected && address && (
          <div style={{
            display: isMobile && !navOpen ? "none" : "block",
            margin: isMobile ? "10px 10px 0" : "0 12px 12px", padding: "12px",
            background: "var(--surface2)", borderRadius: "var(--radius)",
            border: "1px solid var(--border)",
          }}>
            <div style={{ fontSize: 11, color: "var(--muted)", marginBottom: 6 }}>Wallet connected</div>
            <div style={{ fontSize: 12, color: "var(--gold)", fontWeight: 700, marginBottom: 4 }}>
              {shortenAddress(address)}
            </div>
            <div style={{ fontSize: 11, color: "var(--text)" }}>
              {formatMeow(tokenBalance)} $MEOW
            </div>
            <div style={{ fontSize: 11, color: "var(--teal)", marginTop: 2 }}>
              {nftBalance.toString()} collectible NFTs
            </div>
          </div>
        )}
      </aside>

      {/* Main */}
      <main style={{ marginLeft: isMobile ? 0 : 220, flex: 1, minHeight: "100vh", background: "var(--bg)" }}>
        {/* Top bar */}
        <header style={{
          position: "sticky", top: 0, zIndex: 50,
          background: "rgba(10,10,15,0.85)", backdropFilter: "blur(12px)",
          borderBottom: "1px solid var(--border)",
          padding: isMobile ? "12px 14px" : "14px 32px",
          display: "flex", alignItems: "center", justifyContent: "space-between",
          gap: 12,
        }}>
          <div style={{ fontFamily: "Syne", fontWeight: 700, fontSize: isMobile ? 14 : 15, color: "var(--text)" }}>
            {navItems.find(n => n.to === location.pathname)?.label ?? "Meowelot"}
          </div>
          <ConnectButton
            showBalance={false}
            chainStatus="icon"
            accountStatus={isMobile ? "avatar" : "address"}
          />
        </header>

        <div style={{ padding: isMobile ? "16px 12px 20px" : "32px", maxWidth: 900, margin: "0 auto" }}>
          {children}
        </div>
      </main>
    </div>
  );
}