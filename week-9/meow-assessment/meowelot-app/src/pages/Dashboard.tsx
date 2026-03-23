import { useAccount } from "wagmi";
import { useTokenInfo } from "../hooks/useTokenInfo";
import { useUserBalance } from "../hooks/useUserBalance";
import { formatMeow, shortenAddress } from "../lib/utils";
import StatCard from "../components/StatCard";
import { EXPLORER_URL, TOKEN_ADDRESS, NFT_ADDRESS } from "../lib/contracts";
import { useIsMobile } from "../hooks/useIsMobile";

export default function Dashboard() {
  const { address, isConnected } = useAccount();
  const info = useTokenInfo();
  const user = useUserBalance(address);
  const isMobile = useIsMobile();

  const supplyPct = info.maxSupply > 0n
    ? Number((info.totalSupply * 10000n) / info.maxSupply) / 100
    : 0;

  const burnPct = info.maxSupply > 0n
    ? Number((info.totalBurned * 10000n) / info.maxSupply) / 100
    : 0;

  return (
    <div className="animate-fade-in">
      {/* Hero */}
      <div style={{
        marginBottom: 32,
        padding: isMobile ? "24px 18px 20px" : "40px 40px 36px",
        background: "var(--surface)",
        borderRadius: "var(--radius-lg)",
        border: "1px solid var(--border)",
        position: "relative", overflow: "hidden",
      }}>
        {/* big ocelot spot pattern */}
        <div style={{
          position: "absolute", right: isMobile ? -70 : -40, top: -40,
          width: isMobile ? 220 : 280, height: isMobile ? 220 : 280, borderRadius: "50%",
          background: "radial-gradient(circle, rgba(240,192,64,0.08) 0%, transparent 70%)",
        }} />
        <div style={{
          fontFamily: "Syne", fontWeight: 800, fontSize: isMobile ? 24 : 36,
          color: "var(--gold)", lineHeight: 1, marginBottom: 8,
        }}>
          Welcome to Meowelot
        </div>
        <div style={{ fontSize: isMobile ? 14 : 16, color: "var(--muted)", marginBottom: 20 }}>
          A simple place to get, send, and track your $MEOW tokens.
        </div>
        <div style={{ display: "flex", gap: 12, flexWrap: "wrap" }}>
          {[
            { label: "Token", value: shortenAddress(TOKEN_ADDRESS), href: `${EXPLORER_URL}/address/${TOKEN_ADDRESS}` },
            { label: "NFT",   value: shortenAddress(NFT_ADDRESS),   href: `${EXPLORER_URL}/address/${NFT_ADDRESS}` },
          ].map(({ label, value, href }) => (
            <a key={label} href={href} target="_blank" rel="noreferrer" style={{
              display: "inline-flex", alignItems: "center", gap: 6,
              padding: "6px 14px", background: "var(--surface2)",
              border: "1px solid var(--border)", borderRadius: "var(--radius)",
              fontSize: 12, color: "var(--muted)", textDecoration: "none",
            }}>
              <span style={{ color: "var(--gold)", fontFamily: "Syne", fontWeight: 700 }}>{label}</span>
              {value} ↗
            </a>
          ))}
        </div>
      </div>

      {/* Stats grid */}
      <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(180px, 1fr))", gap: 16, marginBottom: 24 }}>
        <StatCard label="Tokens Created"          value={formatMeow(info.totalSupply)} sub={`${supplyPct.toFixed(2)}% of maximum`} accent="var(--gold)"   icon="◎" />
        <StatCard label="Tokens Removed"       value={formatMeow(info.totalBurned)} sub={`${burnPct.toFixed(2)}% removed`}      accent="var(--red)"    icon="🔥" />
        <StatCard label="Still Mintable"          value={formatMeow(info.remainingMint)} sub="only app owner can mint"             accent="var(--teal)"   icon="✦" />
        <StatCard label="Maximum Supply Limit"    value={formatMeow(info.maxSupply)}   sub="hard cap"                              accent="var(--purple)"  icon="⬡" />
      </div>

      {/* Supply bar */}
      <div style={{
        background: "var(--surface)", border: "1px solid var(--border)",
        borderRadius: "var(--radius-lg)", padding: isMobile ? "16px 14px" : "20px 24px", marginBottom: 24,
      }}>
        <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 10, gap: 8, flexWrap: "wrap" }}>
          <span style={{ fontFamily: "Syne", fontWeight: 700, fontSize: 14 }}>Token Supply Overview</span>
          <span style={{ fontSize: 12, color: "var(--muted)" }}>{supplyPct.toFixed(2)}% minted</span>
        </div>
        <div style={{ height: 10, background: "var(--surface2)", borderRadius: 5, overflow: "hidden" }}>
          <div style={{
            height: "100%", width: `${supplyPct}%`,
            background: "linear-gradient(90deg, var(--gold2), var(--gold))",
            borderRadius: 5, transition: "width 0.5s ease",
          }} />
        </div>
        <div style={{ display: "flex", gap: 20, marginTop: 12, fontSize: 11, color: "var(--muted)", flexWrap: "wrap" }}>
          <span>⬤ <span style={{ color: "var(--gold)" }}>In Wallets</span>: {formatMeow(info.totalSupply)}</span>
          <span>⬤ <span style={{ color: "var(--red)" }}>Removed</span>: {formatMeow(info.totalBurned)}</span>
          <span>⬤ <span style={{ color: "var(--border2)" }}>Not Yet Minted</span>: {formatMeow(info.remainingMint)}</span>
        </div>
      </div>

      {/* Tokenomics */}
      <div style={{
        background: "var(--surface)", border: "1px solid var(--border)",
        borderRadius: "var(--radius-lg)", padding: isMobile ? "16px 14px" : "20px 24px", marginBottom: 24,
      }}>
        <div style={{ fontFamily: "Syne", fontWeight: 700, fontSize: 14, marginBottom: 16 }}>How Transfers Work</div>
        <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(140px, 1fr))", gap: 12 }}>
          {[
            { label: "Burned Per Transfer", value: `${Number(info.burnFeeBps)}%`,             color: "var(--red)" },
            { label: "Treasury Fee",        value: `${Number(info.treasuryFeeBps)/100}%`,     color: "var(--amber)" },
            { label: "Extra Burn",          value: "0.5%",                                  color: "var(--red)" },
            { label: "Wallet Holding Limit",value: formatMeow(info.antiWhaleCap) + " $MEOW", color: "var(--teal)" },
            { label: "Free Claim Amount",   value: "1,000 $MEOW",                            color: "var(--gold)" },
            { label: "NFT Reward (Sender)",value: formatMeow(info.nftThreshold) + " $MEOW", color: "var(--purple)" },
          ].map(({ label, value, color }) => (
            <div key={label} style={{
              background: "var(--surface2)", borderRadius: "var(--radius)",
              padding: "12px 14px", border: "1px solid var(--border)",
            }}>
              <div style={{ fontSize: 11, color: "var(--muted)", marginBottom: 4 }}>{label}</div>
              <div style={{ fontFamily: "Syne", fontWeight: 700, color, fontSize: 15 }}>{value}</div>
            </div>
          ))}
        </div>
      </div>

      {/* User card */}
      {isConnected && address && (
        <div style={{
          background: "var(--surface)", border: "1px solid var(--gold)",
          borderRadius: "var(--radius-lg)", padding: isMobile ? "16px 14px" : "20px 24px",
          animation: "pulse-glow 3s infinite",
        }}>
          <div style={{ fontFamily: "Syne", fontWeight: 700, fontSize: 14, marginBottom: 12, color: "var(--gold)" }}>
            Your Wallet
          </div>
          <div style={{ display: "flex", gap: 32, flexWrap: "wrap" }}>
            <div>
              <div style={{ fontSize: 11, color: "var(--muted)" }}>Wallet</div>
              <div style={{ fontFamily: "Syne", fontWeight: 600, fontSize: 13 }}>{shortenAddress(address)}</div>
            </div>
            <div>
              <div style={{ fontSize: 11, color: "var(--muted)" }}>Token Balance</div>
              <div style={{ fontFamily: "Syne", fontWeight: 800, fontSize: 20, color: "var(--gold)" }}>
                {formatMeow(user.tokenBalance)}
              </div>
            </div>
            <div>
              <div style={{ fontSize: 11, color: "var(--muted)" }}>Collectible NFTs</div>
              <div style={{ fontFamily: "Syne", fontWeight: 800, fontSize: 20, color: "var(--teal)" }}>
                {user.nftBalance.toString()}
              </div>
            </div>
            {user.isOwner && (
              <div style={{
                alignSelf: "center", padding: "4px 12px",
                background: "rgba(128,96,240,0.15)", border: "1px solid var(--purple)",
                borderRadius: "var(--radius)", fontSize: 11, color: "var(--purple)",
                fontFamily: "Syne", fontWeight: 700,
              }}>
                OWNER
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}