import { useEffect } from "react";
import { useAccount } from "wagmi";
import { useFaucetTimer } from "../hooks/useFaucetTimer";
import { useRequestToken } from "../hooks/useRequestToken";
import { useUserBalance } from "../hooks/useUserBalance";
import { extractErrorMessage, formatMeow, formatCountdown } from "../lib/utils";
import TxButton from "../components/TxButton";
import { EXPLORER_URL } from "../lib/contracts";
import toast from "react-hot-toast";
import { useIsMobile } from "../hooks/useIsMobile";

export default function Faucet() {
  const { address, isConnected } = useAccount();
  const { secondsLeft, canClaim, refetch: refetchTimer } = useFaucetTimer(address);
  const { requestToken, hash, isPending, isConfirming, isSuccess } = useRequestToken();
  const { tokenBalance, refetch: refetchBalance } = useUserBalance(address);
  const isMobile = useIsMobile();

  useEffect(() => {
    if (isSuccess) {
      toast.success("1,000 $MEOW claimed!");
      refetchTimer();
      refetchBalance();
    }
  }, [isSuccess, refetchBalance, refetchTimer]);

  async function handleClaim() {
    try {
      await requestToken();
    } catch (e: unknown) {
      const msg = extractErrorMessage(e);
      toast.error(msg.length > 80 ? msg.slice(0, 80) + "…" : msg);
    }
  }

  const h = Math.floor(secondsLeft / 3600);
  const m = Math.floor((secondsLeft % 3600) / 60);
  const s = secondsLeft % 60;

  // Arc progress (SVG)
  const totalCooldown = 24 * 3600;
  const elapsed = totalCooldown - secondsLeft;
  const pct = Math.min(elapsed / totalCooldown, 1);
  const timerSize = isMobile ? 170 : 220;
  const center = timerSize / 2;
  const R = isMobile ? 68 : 88;
  const circumference = 2 * Math.PI * R;
  const dash = circumference * pct;

  return (
    <div className="animate-fade-in" style={{ maxWidth: 520, margin: "0 auto" }}>
      <div style={{ fontFamily: "Syne", fontWeight: 800, fontSize: isMobile ? 26 : 32, marginBottom: 6 }}>
        Get Free Tokens
      </div>
      <div style={{ color: "var(--muted)", marginBottom: 32 }}>
        Claim free $MEOW in one tap. You can claim again after 24 hours per wallet.
      </div>

      {/* Circle timer */}
      <div style={{
        background: "var(--surface)", border: "1px solid var(--border)",
        borderRadius: "var(--radius-lg)", padding: isMobile ? "22px 14px" : "40px", textAlign: "center", marginBottom: 24,
      }}>
        <div style={{ position: "relative", display: "inline-block", marginBottom: 28 }}>
          <svg width={timerSize} height={timerSize} style={{ transform: "rotate(-90deg)" }}>
            {/* Track */}
            <circle cx={center} cy={center} r={R} fill="none" stroke="var(--surface2)" strokeWidth={10} />
            {/* Progress */}
            <circle
              cx={center} cy={center} r={R} fill="none"
              stroke={canClaim ? "var(--teal)" : "var(--gold)"}
              strokeWidth={10} strokeLinecap="round"
              strokeDasharray={`${dash} ${circumference}`}
              style={{ transition: "stroke-dasharray 1s linear" }}
            />
          </svg>
          <div style={{
            position: "absolute", inset: 0, display: "flex",
            flexDirection: "column", alignItems: "center", justifyContent: "center",
          }}>
            {canClaim ? (
              <>
                <div style={{ fontSize: 32 }}>🐆</div>
                <div style={{ fontFamily: "Syne", fontWeight: 800, fontSize: 15, color: "var(--teal)", marginTop: 4 }}>
                  CLAIM
                </div>
              </>
            ) : (
              <>
                <div style={{ fontFamily: "Syne", fontWeight: 800, fontSize: isMobile ? 21 : 28, color: "var(--gold)", lineHeight: 1 }}>
                  {String(h).padStart(2, "0")}:{String(m).padStart(2, "0")}:{String(s).padStart(2, "0")}
                </div>
                <div style={{ fontSize: 11, color: "var(--muted)", marginTop: 4 }}>hours · mins · secs</div>
              </>
            )}
          </div>
        </div>

        <div style={{ fontSize: 13, color: "var(--muted)", marginBottom: 24 }}>
          {canClaim
            ? "You are eligible to claim right now."
            : formatCountdown(secondsLeft)}
        </div>

        {!isConnected ? (
          <div style={{ color: "var(--muted)", fontSize: 13 }}>Connect your wallet to get free tokens</div>
        ) : (
          <TxButton
            fullWidth
            onClick={handleClaim}
            disabled={!canClaim}
            loading={isPending || isConfirming}
          >
            {isPending ? "Approve in wallet…" : isConfirming ? "Processing…" : "Get 1,000 $MEOW"}
          </TxButton>
        )}

        {hash && (
          <a
            href={`${EXPLORER_URL}/tx/${hash}`} target="_blank" rel="noreferrer"
            style={{ display: "block", marginTop: 12, fontSize: 12, color: "var(--muted)" }}
          >
            View tx ↗
          </a>
        )}
      </div>

      {/* Info cards */}
      <div style={{ display: "grid", gridTemplateColumns: isMobile ? "1fr" : "1fr 1fr", gap: 12 }}>
        {[
          { label: "You Receive",     value: "1,000 $MEOW", color: "var(--gold)" },
          { label: "Wait Time",       value: "24 hours",    color: "var(--amber)" },
          { label: "Your Balance",    value: isConnected ? formatMeow(tokenBalance) + " $MEOW" : "—", color: "var(--teal)" },
          { label: "Rule",            value: "One timer per wallet",  color: "var(--purple)" },
        ].map(({ label, value, color }) => (
          <div key={label} style={{
            background: "var(--surface)", border: "1px solid var(--border)",
            borderRadius: "var(--radius)", padding: "14px 16px",
          }}>
            <div style={{ fontSize: 11, color: "var(--muted)", marginBottom: 4 }}>{label}</div>
            <div style={{ fontFamily: "Syne", fontWeight: 700, color, fontSize: 14 }}>{value}</div>
          </div>
        ))}
      </div>
    </div>
  );
}
