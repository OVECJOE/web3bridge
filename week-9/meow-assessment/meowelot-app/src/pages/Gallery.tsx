import { useState } from "react";
import { useNFTGallery, type OcelotNFT } from "../hooks/useNFTGallery";
import { formatMeow } from "../lib/utils";
import { EXPLORER_URL, NFT_ADDRESS } from "../lib/contracts";
import { useAccount } from "wagmi";
import { useIsMobile } from "../hooks/useIsMobile";

function OcelotCard({ nft, isMobile }: { nft: OcelotNFT; isMobile: boolean }) {
  const [imgError, setImgError] = useState(false);
  const { traits, tokenId, tokenURI } = nft;

  // Decode SVG from base64 tokenURI
  let svgSrc = "";
  try {
    if (tokenURI.startsWith("data:application/json;base64,")) {
      const json = JSON.parse(atob(tokenURI.split(",")[1]));
      svgSrc = json.image;
    }
  } catch {
    setImgError(true);
  }

  const ACC_ICONS: Record<string, string> = {
    "None": "", "Gold Chain": "⛓️", "Laser Eyes": "🔴", "Crown": "👑", "Sunglasses": "🕶️"
  };

  return (
    <div style={{
      background: "var(--surface)", border: "1px solid var(--border)",
      borderRadius: "var(--radius-lg)", overflow: "hidden",
      transition: "border-color 0.15s, transform 0.15s",
    }}
      onMouseEnter={e => {
        (e.currentTarget as HTMLDivElement).style.borderColor = "var(--gold)";
        (e.currentTarget as HTMLDivElement).style.transform = "translateY(-3px)";
      }}
      onMouseLeave={e => {
        (e.currentTarget as HTMLDivElement).style.borderColor = "var(--border)";
        (e.currentTarget as HTMLDivElement).style.transform = "translateY(0)";
      }}
    >
      {/* NFT Image */}
      <div style={{ background: "var(--surface2)", aspectRatio: "1", position: "relative" }}>
        {svgSrc && !imgError ? (
          <img
            src={svgSrc} alt={`Ocelot #${tokenId}`}
            style={{ width: "100%", height: "100%", objectFit: "cover" }}
            onError={() => setImgError(true)}
          />
        ) : (
          <div style={{
            width: "100%", height: "100%", display: "flex",
            alignItems: "center", justifyContent: "center", fontSize: 48,
          }}>🐆</div>
        )}
        <div style={{
          position: "absolute", top: 8, left: 8,
          background: "rgba(0,0,0,0.6)", borderRadius: 6,
          padding: "2px 8px", fontSize: 11, fontFamily: "Syne", fontWeight: 700, color: "var(--gold)",
        }}>
          #{tokenId}
        </div>
        {traits.accName && traits.accName !== "None" && (
          <div style={{
            position: "absolute", top: 8, right: 8,
            background: "rgba(0,0,0,0.6)", borderRadius: 6,
            padding: "2px 8px", fontSize: 14,
          }}>
            {ACC_ICONS[traits.accName]}
          </div>
        )}
      </div>

      {/* Info */}
      <div style={{ padding: isMobile ? "12px" : "14px" }}>
        <div style={{ fontFamily: "Syne", fontWeight: 700, fontSize: 14, marginBottom: 10 }}>
          Meowelot Ocelot #{tokenId}
        </div>
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 6, fontSize: 11 }}>
          {[
            { label: "Fur",    value: traits.furName },
            { label: "Eyes",   value: traits.eyeName },
            { label: "BG",     value: traits.bgName },
            { label: "ACC",    value: traits.accName },
          ].map(({ label, value }) => (
            <div key={label} style={{
              background: "var(--surface2)", borderRadius: 6, padding: "5px 8px",
            }}>
              <div style={{ color: "var(--muted)", fontSize: 10, marginBottom: 1 }}>{label}</div>
              <div style={{ color: "var(--text)", fontFamily: "Syne", fontWeight: 600, fontSize: 11 }}>{value}</div>
            </div>
          ))}
        </div>
        <div style={{ marginTop: 10, padding: "6px 8px", background: "rgba(128,96,240,0.1)", borderRadius: 6 }}>
          <span style={{ fontSize: 10, color: "var(--muted)" }}>Earned by transferring </span>
          <span style={{ fontSize: 11, color: "var(--purple)", fontFamily: "Syne", fontWeight: 700 }}>
            {formatMeow(traits.amount)} $MEOW
          </span>
        </div>
        <a
          href={`${EXPLORER_URL}/token/${NFT_ADDRESS}/instance/${tokenId}`}
          target="_blank" rel="noreferrer"
          style={{ display: "block", marginTop: 10, fontSize: 11, color: "var(--muted)", textAlign: "center" }}
        >
          View on Explorer ↗
        </a>
      </div>
    </div>
  );
}

export default function Gallery() {
  const { address, isConnected } = useAccount();
  const { nfts, count } = useNFTGallery(address);
  const isMobile = useIsMobile();

  if (!isConnected) {
    return (
      <div className="animate-fade-in" style={{ textAlign: "center", paddingTop: isMobile ? 36 : 80 }}>
        <div style={{ fontSize: 48, marginBottom: 16 }}>🐆</div>
        <div style={{ fontFamily: "Syne", fontWeight: 700, fontSize: 20, marginBottom: 8 }}>My Ocelots</div>
        <div style={{ color: "var(--muted)" }}>Connect your wallet to see your Ocelot NFTs</div>
      </div>
    );
  }

  return (
    <div className="animate-fade-in">
      <div style={{ display: "flex", alignItems: "baseline", gap: 16, marginBottom: 6, flexWrap: "wrap" }}>
        <div style={{ fontFamily: "Syne", fontWeight: 800, fontSize: isMobile ? 26 : 32 }}>My Ocelots</div>
        <div style={{ fontFamily: "Syne", fontWeight: 700, fontSize: 18, color: "var(--gold)" }}>
          {count}
        </div>
      </div>
      <div style={{ color: "var(--muted)", marginBottom: 32 }}>
        Soulbound NFTs earned by transferring ≥ 10,000 $MEOW. Fully on-chain SVG art.
      </div>

      {count === 0 ? (
        <div style={{
          textAlign: "center", padding: isMobile ? "40px 20px" : "80px 40px",
          background: "var(--surface)", border: "1px solid var(--border)",
          borderRadius: "var(--radius-lg)",
        }}>
          <div style={{ fontSize: 64, marginBottom: 16 }}>🐾</div>
          <div style={{ fontFamily: "Syne", fontWeight: 700, fontSize: 18, marginBottom: 8 }}>No Ocelots Yet</div>
          <div style={{ color: "var(--muted)", maxWidth: 320, margin: "0 auto" }}>
            Transfer ≥ 10,000 $MEOW to any address to earn your first spotted companion.
          </div>
        </div>
      ) : (
        <div style={{
          display: "grid",
          gridTemplateColumns: `repeat(auto-fill, minmax(${isMobile ? 170 : 220}px, 1fr))`,
          gap: isMobile ? 12 : 20,
        }}>
          {nfts.map(nft => <OcelotCard key={nft.tokenId} nft={nft} isMobile={isMobile} />)}
        </div>
      )}
    </div>
  );
}