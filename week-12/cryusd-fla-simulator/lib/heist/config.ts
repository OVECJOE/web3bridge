import { Stage, Zone, ZoneName } from "@/lib/heist/types"

export const BASE_VAULT_VALUE = 10_000_000
export const SHARES_OUTSTANDING = 10_000_000
export const COLLATERAL_FACTOR = 0.75
export const MARKET_LIQUIDITY = 130_000_000
export const ATTACKER_SHARES = 1_000_000
export const TARGET_INJECTION = 500_000_000

export const WORLD_WIDTH = 3200
export const WORLD_HEIGHT = 2200

export const STAGE_LABELS = [
  "Briefing",
  "Acquire Maker Loan",
  "Acquire Aave Loan",
  "Inflate Yearn Vault",
  "Post Collateral",
  "Drain Liquidity",
  "Exfiltrate",
  "Debrief",
] as const

export const ZONE_LABELS: Record<ZoneName, string> = {
  maker: "MakerDAO Flash Deck",
  aave: "Aave Flash Deck",
  yearn: "Yearn yUSD Vault",
  cream: "Cream Core Market",
  exit: "Bridge Exfil",
}

export function stageMeta(stage: Stage) {
  if (stage === 0) {
    return {
      objective: "Operation briefing",
      instruction: "Use Begin Operation to deploy",
      targetZone: null,
    }
  }
  if (stage === 1) {
    return {
      objective: "Secure Maker flash capital",
      instruction: "Move to Maker zone and tap Action",
      targetZone: "maker" as const,
    }
  }
  if (stage === 2) {
    return {
      objective: "Secure Aave flash capital",
      instruction: "Move to Aave zone and tap Action",
      targetZone: "aave" as const,
    }
  }
  if (stage === 3) {
    return {
      objective: "Inflate Yearn valuation",
      instruction: "Hold Action inside Yearn zone",
      targetZone: "yearn" as const,
    }
  }
  if (stage === 4) {
    return {
      objective: "Post inflated collateral",
      instruction: "Enter Cream zone and tap Action once",
      targetZone: "cream" as const,
    }
  }
  if (stage === 5) {
    return {
      objective: "Drain available liquidity",
      instruction: "Hold Action inside Cream zone",
      targetZone: "cream" as const,
    }
  }
  if (stage === 6) {
    return {
      objective: "Exfiltrate through bridge",
      instruction: "Move to Exit zone and tap Action",
      targetZone: "exit" as const,
    }
  }
  return {
    objective: "Debrief",
    instruction: "Run operation again",
    targetZone: null,
  }
}

export function makeZones(): Record<ZoneName, Zone> {
  return {
    maker: {
      x: WORLD_WIDTH * 0.08,
      y: WORLD_HEIGHT * 0.18,
      w: WORLD_WIDTH * 0.17,
      h: WORLD_HEIGHT * 0.13,
      label: ZONE_LABELS.maker,
    },
    aave: {
      x: WORLD_WIDTH * 0.08,
      y: WORLD_HEIGHT * 0.68,
      w: WORLD_WIDTH * 0.17,
      h: WORLD_HEIGHT * 0.13,
      label: ZONE_LABELS.aave,
    },
    yearn: {
      x: WORLD_WIDTH * 0.39,
      y: WORLD_HEIGHT * 0.36,
      w: WORLD_WIDTH * 0.2,
      h: WORLD_HEIGHT * 0.19,
      label: ZONE_LABELS.yearn,
    },
    cream: {
      x: WORLD_WIDTH * 0.72,
      y: WORLD_HEIGHT * 0.36,
      w: WORLD_WIDTH * 0.18,
      h: WORLD_HEIGHT * 0.2,
      label: ZONE_LABELS.cream,
    },
    exit: {
      x: WORLD_WIDTH * 0.77,
      y: WORLD_HEIGHT * 0.14,
      w: WORLD_WIDTH * 0.16,
      h: WORLD_HEIGHT * 0.12,
      label: ZONE_LABELS.exit,
    },
  }
}
