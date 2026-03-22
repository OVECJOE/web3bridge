import { useState, useEffect } from "react";
import { useAccount } from "wagmi";
import { isAddress } from "viem";
import { useMint } from "../hooks/useMint";
import { useUserBalance } from "../hooks/useUserBalance";
import { useTokenInfo } from "../hooks/useTokenInfo";
import { extractErrorMessage, formatMeow, parseTokenAmount } from "../lib/utils";
import TxButton from "../components/TxButton";
import InputField from "../components/InputField";
import { EXPLORER_URL } from "../lib/contracts";
import toast from "react-hot-toast";
import { useIsMobile } from "../hooks/useIsMobile";

export default function Mint() {
  const { address, isConnected } = useAccount();
  const { mint, hash, isPending, isConfirming, isSuccess } = useMint();
  const { isOwner, refetch } = useUserBalance(address);
  const info = useTokenInfo();
  const { refetch: refetchTokenInfo } = info;
  const isMobile = useIsMobile();

  const [to, setTo]       = useState("");
  const [amount, setAmount] = useState("");
  const [toErr, setToErr]   = useState("");
  const [amtErr, setAmtErr] = useState("");

  useEffect(() => {
    if (isSuccess) {
      toast.success("Tokens minted!");
      setAmount("");
      refetch();
      refetchTokenInfo();
    }
  }, [isSuccess, refetch, refetchTokenInfo]);

  function validate() {
    let ok = true;
    const target = to || address || "";
    if (!isAddress(target)) { setToErr("Invalid address"); ok = false; } else setToErr("");
    const parsed = parseTokenAmount(amount);
    if (parsed <= 0n) { setAmtErr("Enter a valid amount"); ok = false; }
    else if (parsed > info.remainingMint) { setAmtErr("Exceeds remaining mintable supply"); ok = false; }
    else setAmtErr("");
    return ok;
  }

  async function handleMint() {
    if (!validate()) return;
    const target = (to || address) as `0x${string}`;
    try {
      await mint(target, parseTokenAmount(amount));
    } catch (e: unknown) {
      const msg = extractErrorMessage(e);
      toast.error(msg.length > 80 ? msg.slice(0, 80) + "…" : msg);
    }
  }

  if (!isConnected) {
    return (
      <div className="animate-fade-in" style={{ textAlign: "center", paddingTop: isMobile ? 36 : 80 }}>
        <div style={{ fontSize: 48, marginBottom: 16 }}>🔒</div>
        <div style={{ fontFamily: "Syne", fontWeight: 700, fontSize: 20, marginBottom: 8 }}>Connect Wallet</div>
        <div style={{ color: "var(--muted)" }}>Connect to check owner access</div>
      </div>
    );
  }

  if (!isOwner) {
    return (
      <div className="animate-fade-in" style={{ textAlign: "center", paddingTop: isMobile ? 36 : 80 }}>
        <div style={{ fontSize: 48, marginBottom: 16 }}>🚫</div>
        <div style={{ fontFamily: "Syne", fontWeight: 700, fontSize: 20, marginBottom: 8 }}>Owner Only</div>
        <div style={{ color: "var(--muted)" }}>Only the contract owner can mint tokens.</div>
      </div>
    );
  }

  const parsedAmt = parseTokenAmount(amount);
  const supplyAfter = info.totalSupply + parsedAmt;
  const pctAfter = info.maxSupply > 0n ? Number((supplyAfter * 10000n) / info.maxSupply) / 100 : 0;

  return (
    <div className="animate-fade-in" style={{ maxWidth: 520, margin: "0 auto" }}>
      <div style={{ display: "flex", alignItems: "center", gap: 12, marginBottom: 6, flexWrap: "wrap" }}>
        <div style={{ fontFamily: "Syne", fontWeight: 800, fontSize: isMobile ? 26 : 32 }}>Mint Tokens</div>
        <div style={{
          padding: "3px 10px", background: "rgba(128,96,240,0.15)",
          border: "1px solid var(--purple)", borderRadius: "var(--radius)",
          fontSize: 11, color: "var(--purple)", fontFamily: "Syne", fontWeight: 700,
        }}>OWNER</div>
      </div>
      <div style={{ color: "var(--muted)", marginBottom: 32 }}>
        Mint new $MEOW up to the 10M hard cap.
      </div>

      {/* Supply status */}
      <div style={{
        background: "var(--surface)", border: "1px solid var(--border)",
        borderRadius: "var(--radius-lg)", padding: isMobile ? "16px 14px" : "20px 24px", marginBottom: 20,
      }}>
        <div style={{ fontFamily: "Syne", fontWeight: 700, fontSize: 13, marginBottom: 12 }}>Supply Status</div>
        <div style={{ display: "grid", gridTemplateColumns: isMobile ? "1fr" : "1fr 1fr 1fr", gap: 12, marginBottom: 12 }}>
          {[
            { label: "Current",   value: formatMeow(info.totalSupply),   color: "var(--gold)" },
            { label: "Remaining", value: formatMeow(info.remainingMint), color: "var(--teal)" },
            { label: "Max",       value: formatMeow(info.maxSupply),     color: "var(--muted)" },
          ].map(({ label, value, color }) => (
            <div key={label} style={{ textAlign: "center" }}>
              <div style={{ fontSize: 11, color: "var(--muted)", marginBottom: 4 }}>{label}</div>
              <div style={{ fontFamily: "Syne", fontWeight: 700, color, fontSize: 15 }}>{value}</div>
            </div>
          ))}
        </div>
        <div style={{ height: 8, background: "var(--surface2)", borderRadius: 4, overflow: "hidden" }}>
          <div style={{
            height: "100%",
            width: `${Number((info.totalSupply * 10000n) / (info.maxSupply || 1n)) / 100}%`,
            background: "var(--gold)", borderRadius: 4,
          }} />
        </div>
      </div>

      <div style={{
        background: "var(--surface)", border: "1px solid var(--border)",
        borderRadius: "var(--radius-lg)", padding: isMobile ? "18px 14px" : "28px",
      }}>
        <InputField
          label="Mint To (leave blank for your wallet)"
          placeholder={address ?? "0x..."}
          value={to}
          onChange={e => setTo(e.target.value)}
          error={toErr}
        />

        <InputField
          label="Amount"
          placeholder="0"
          type="number"
          min="0"
          value={amount}
          onChange={e => setAmount(e.target.value)}
          error={amtErr}
          hint={`Max mintable: ${formatMeow(info.remainingMint)} $MEOW`}
        />

        {parsedAmt > 0n && (
          <div style={{
            padding: "12px 14px", marginBottom: 20,
            background: "var(--surface2)", borderRadius: "var(--radius)", fontSize: 12,
          }}>
            <div style={{ color: "var(--muted)", marginBottom: 4 }}>After mint, supply will be:</div>
            <div style={{ fontFamily: "Syne", fontWeight: 700, color: "var(--gold)" }}>
              {formatMeow(supplyAfter)} $MEOW ({pctAfter.toFixed(2)}% of max)
            </div>
          </div>
        )}

        <TxButton fullWidth onClick={handleMint} loading={isPending || isConfirming}>
          {isPending ? "Confirm in wallet…" : isConfirming ? "Confirming…" : "Mint $MEOW"}
        </TxButton>

        {hash && (
          <a href={`${EXPLORER_URL}/tx/${hash}`} target="_blank" rel="noreferrer"
            style={{ display: "block", textAlign: "center", marginTop: 12, fontSize: 12, color: "var(--muted)" }}>
            View tx ↗
          </a>
        )}
      </div>
    </div>
  );
}
