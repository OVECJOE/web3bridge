import React from "react";

interface Props extends React.InputHTMLAttributes<HTMLInputElement> {
  label?: string;
  hint?: string;
  error?: string;
}

export default function InputField({ label, hint, error, style, ...rest }: Props) {
  return (
    <div style={{ marginBottom: 16 }}>
      {label && (
        <label style={{ display: "block", fontSize: 12, color: "var(--muted)", marginBottom: 6, fontFamily: "Syne", fontWeight: 600 }}>
          {label}
        </label>
      )}
      <input
        style={{
          width: "100%", padding: "12px 14px",
          background: "var(--surface2)", border: `1px solid ${error ? "var(--red)" : "var(--border)"}`,
          borderRadius: "var(--radius)", color: "var(--text)",
          outline: "none", transition: "border-color 0.15s",
          ...style,
        }}
        onFocus={e => { e.target.style.borderColor = error ? "var(--red)" : "var(--gold)"; }}
        onBlur={e =>  { e.target.style.borderColor = error ? "var(--red)" : "var(--border)"; }}
        {...rest}
      />
      {hint && !error && <div style={{ fontSize: 11, color: "var(--muted)", marginTop: 4 }}>{hint}</div>}
      {error && <div style={{ fontSize: 11, color: "var(--red)", marginTop: 4 }}>{error}</div>}
    </div>
  );
}