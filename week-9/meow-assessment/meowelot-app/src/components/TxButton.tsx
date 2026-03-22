import React from "react";

interface Props extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  loading?: boolean;
  variant?: "primary" | "danger" | "ghost";
  fullWidth?: boolean;
}

export default function TxButton({ loading, variant = "primary", fullWidth, children, disabled, style, ...rest }: Props) {
  const base: React.CSSProperties = {
    display: "inline-flex", alignItems: "center", justifyContent: "center", gap: 8,
    padding: "12px 28px", borderRadius: "var(--radius)", fontFamily: "Syne",
    fontWeight: 700, fontSize: 14, border: "none", transition: "all 0.15s",
    cursor: disabled || loading ? "not-allowed" : "pointer",
    opacity: disabled || loading ? 0.5 : 1,
    width: fullWidth ? "100%" : undefined,
    ...style,
  };

  const variants = {
    primary: { background: "var(--gold)", color: "#0a0a0f" },
    danger:  { background: "var(--red)",  color: "#fff" },
    ghost:   { background: "var(--surface2)", color: "var(--text)", border: "1px solid var(--border)" },
  };

  return (
    <button style={{ ...base, ...variants[variant] }} disabled={disabled || loading} {...rest}>
      {loading ? (
        <span style={{
          width: 14, height: 14, border: "2px solid currentColor",
          borderTopColor: "transparent", borderRadius: "50%",
          display: "inline-block", animation: "spin 0.7s linear infinite",
        }} />
      ) : null}
      {children}
    </button>
  );
}