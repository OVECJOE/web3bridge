import { useState, useEffect } from "react";
import { useAccount } from "wagmi";
import { formatUnits, isAddress } from "viem";
import { useTransfer } from "../hooks/useTransfer";
import { useUserBalance } from "../hooks/useUserBalance";
import { useTokenInfo } from "../hooks/useTokenInfo";
import { extractErrorMessage, formatMeow, parseTokenAmount } from "../lib/utils";
import TxButton from "../components/TxButton";
import InputField from "../components/InputField";
import { EXPLORER_URL } from "../lib/contracts";
import toast from "react-hot-toast";
import { useIsMobile } from "../hooks/useIsMobile";

export default function Transfer() {
  const { address, isConnected } = useAccount();
  const { transfer, hash, isPending, isConfirming, isSuccess } = useTransfer();
  const { tokenBalance, refetch } = useUserBalance(address);
  const { nftThreshold } = useTokenInfo();
  const isMobile = useIsMobile();

  const [to, setTo]       = useState("");
  const [amount, setAmount] = useState("");
  const [toErr, setToErr]   = useState("");
  const [amtErr, setAmtErr] = useState("");

  useEffect(() => {
    if (isSuccess) {
      toast.success("Transfer successful!");
      setTo(""); setAmount("");
      refetch();
    }
  }, [isSuccess, refetch]);

  function validate() {
    let ok = true;
    if (!isAddress(to)) { setToErr("Invalid address"); ok = false; } else setToErr("");
    const parsed = parseTokenAmount(amount);
    if (parsed <= 0n) { setAmtErr("Enter a valid amount"); ok = false; }
    else if (parsed > tokenBalance) { setAmtErr("Insufficient balance"); ok = false; }
    else setAmtErr("");
    return ok;
  }

  async function handleTransfer() {
    if (!validate()) return;
    try {
      await transfer(to as `0x${string}`, parseTokenAmount(amount));
    } catch (e: unknown) {
      const msg = extractErrorMessage(e);
      toast.error(msg.length > 80 ? msg.slice(0, 80) + "…" : msg);
    }
  }

  const parsedAmt = parseTokenAmount(amount);
  const willGetNFT = nftThreshold > 0n && parsedAmt >= nftThreshold;

  // Fee preview
  const burnAmt     = parsedAmt * 100n / 10000n;
  const treasuryAmt = parsedAmt * 50n  / 10000n;
  const extraBurn   = parsedAmt * 50n  / 10000n;
  const netAmt      = parsedAmt - burnAmt - treasuryAmt - extraBurn;

  return (
    <div className="animate-fade-in" style={{ maxWidth: 520, margin: "0 auto" }}>
      <div style={{ fontFamily: "Syne", fontWeight: 800, fontSize: isMobile ? 26 : 32, marginBottom: 6 }}>Send Tokens</div>
      <div style={{ color: "var(--muted)", marginBottom: 32 }}>
        Send $MEOW to another wallet. Large transfers unlock a bonus NFT for the receiver.
      </div>

      <div style={{
        background: "var(--surface)", border: "1px solid var(--border)",
        borderRadius: "var(--radius-lg)", padding: isMobile ? "18px 14px" : "28px",
      }}>
        {/* Balance */}
        <div style={{
          display: "flex", justifyContent: "space-between", alignItems: "center",
          flexWrap: "wrap", gap: 6,
          marginBottom: 20, padding: "10px 14px",
          background: "var(--surface2)", borderRadius: "var(--radius)",
        }}>
          <span style={{ fontSize: 12, color: "var(--muted)" }}>Available to send</span>
          <span style={{ fontFamily: "Syne", fontWeight: 700, color: "var(--gold)" }}>
            {isConnected ? formatMeow(tokenBalance, 4) : "—"} $MEOW
          </span>
        </div>

        <InputField
          label="Receiver Wallet Address"
          placeholder="0x..."
          value={to}
          onChange={e => setTo(e.target.value)}
          error={toErr}
        />

        <div style={{ position: "relative" }}>
          <InputField
            label="Amount to Send"
            placeholder="0.00"
            type="number"
            min="0"
            value={amount}
            onChange={e => setAmount(e.target.value)}
            error={amtErr}
            hint={isConnected ? `Max: ${formatMeow(tokenBalance, 0)} $MEOW` : undefined}
          />
          {isConnected && tokenBalance > 0n && (
            <button
              onClick={() => setAmount(formatUnits(tokenBalance, 18))}
              style={{
                position: "absolute", right: 10, top: isMobile ? 32 : 30,
                padding: "2px 8px", fontSize: 10, fontFamily: "Syne", fontWeight: 700,
                background: "var(--surface2)", border: "1px solid var(--border)",
                borderRadius: 4, color: "var(--muted)", cursor: "pointer",
              }}
            >
              MAX
            </button>
          )}
        </div>

        {/* Fee preview */}
        {parsedAmt > 0n && (
          <div style={{
            background: "var(--surface2)", borderRadius: "var(--radius)",
            padding: "14px", marginBottom: 20, fontSize: 12,
          }}>
            <div style={{ fontFamily: "Syne", fontWeight: 700, marginBottom: 8, fontSize: 11, color: "var(--muted)", textTransform: "uppercase", letterSpacing: 1 }}>
              What Happens to This Transfer
            </div>
            {[
              { label: "Burned",              value: formatMeow(burnAmt),     color: "var(--red)" },
              { label: "Project Treasury",    value: formatMeow(treasuryAmt), color: "var(--amber)" },
              { label: "Extra Burn",          value: formatMeow(extraBurn),   color: "var(--red)" },
              { label: "Receiver Gets",       value: formatMeow(netAmt) + " $MEOW", color: "var(--teal)" },
            ].map(({ label, value, color }) => (
              <div key={label} style={{ display: "flex", justifyContent: "space-between", marginBottom: 4 }}>
                <span style={{ color: "var(--muted)" }}>{label}</span>
                <span style={{ color, fontFamily: "Syne", fontWeight: 700 }}>{value}</span>
              </div>
            ))}
          </div>
        )}

        {/* NFT badge */}
        {willGetNFT && (
          <div style={{
            display: "flex", alignItems: "center", gap: 10,
            padding: "10px 14px", marginBottom: 20,
            background: "rgba(128,96,240,0.1)", border: "1px solid var(--purple)",
            borderRadius: "var(--radius)", fontSize: 12, color: "var(--purple)",
          }}>
            <span style={{ fontSize: 20 }}>🐆</span>
            <span><strong>Bonus unlocked.</strong> This transfer will mint a collectible NFT for the receiver.</span>
          </div>
        )}

        {!isConnected ? (
          <div style={{ textAlign: "center", color: "var(--muted)", fontSize: 13 }}>Connect your wallet to send tokens</div>
        ) : (
          <TxButton fullWidth onClick={handleTransfer} loading={isPending || isConfirming}>
            {isPending ? "Approve in wallet…" : isConfirming ? "Processing…" : "Send $MEOW"}
          </TxButton>
        )}

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