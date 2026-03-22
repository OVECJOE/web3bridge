interface Props {
  label: string;
  value: string;
  sub?: string;
  accent?: string;
  icon?: string;
}

export default function StatCard({ label, value, sub, accent = "var(--gold)", icon }: Props) {
  return (
    <div style={{
      background: "var(--surface)", border: "1px solid var(--border)",
      borderRadius: "var(--radius-lg)", padding: "clamp(14px, 3vw, 20px) clamp(14px, 3vw, 24px)",
      position: "relative", overflow: "hidden",
    }}>
      {/* accent line */}
      <div style={{ position: "absolute", top: 0, left: 0, right: 0, height: 2, background: accent }} />
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start" }}>
        <div>
          <div style={{ fontSize: 11, color: "var(--muted)", textTransform: "uppercase", letterSpacing: 1, marginBottom: 8 }}>
            {label}
          </div>
          <div style={{ fontFamily: "Syne", fontWeight: 800, fontSize: "clamp(20px, 6vw, 28px)", color: "var(--text)", lineHeight: 1 }}>
            {value}
          </div>
          {sub && <div style={{ fontSize: 12, color: "var(--muted)", marginTop: 6 }}>{sub}</div>}
        </div>
        {icon && <span style={{ fontSize: 28, opacity: 0.5 }}>{icon}</span>}
      </div>
    </div>
  );
}