import { formatUnits, parseUnits } from "viem";

export function formatMeow(value: bigint, decimals = 2): string {
  const num = parseFloat(formatUnits(value, 18));
  if (num >= 1_000_000) return (num / 1_000_000).toFixed(2) + "M";
  if (num >= 1_000) return (num / 1_000).toFixed(decimals) + "K";
  return num.toFixed(decimals);
}

export function formatCountdown(seconds: number): string {
  if (seconds <= 0) return "Available now";
  const h = Math.floor(seconds / 3600);
  const m = Math.floor((seconds % 3600) / 60);
  const s = seconds % 60;
  const parts: string[] = [];
  if (h > 0) parts.push(`${h}h`);
  if (m > 0) parts.push(`${m}m`);
  parts.push(`${s}s`);
  return `Retry in ${parts.join(" ")}`;
}

export function shortenAddress(addr: string): string {
  return `${addr.slice(0, 6)}…${addr.slice(-4)}`;
}

export function parseTokenAmount(val: string): bigint {
  try {
    const cleaned = val.replace(/,/g, "").trim();
    if (!cleaned) return 0n;
    return parseUnits(cleaned, 18);
  } catch {
    return 0n;
  }
}

export function extractErrorMessage(error: unknown): string {
  if (typeof error === "string") return error;
  if (error instanceof Error) return error.message;

  if (typeof error === "object" && error !== null) {
    const maybeRecord = error as Record<string, unknown>;
    if (typeof maybeRecord.shortMessage === "string") return maybeRecord.shortMessage;
    if (typeof maybeRecord.message === "string") return maybeRecord.message;
  }

  return "Transaction failed";
}