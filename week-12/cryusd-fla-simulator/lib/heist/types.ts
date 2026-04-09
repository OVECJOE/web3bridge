export type Stage = 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7

export type ZoneName = "maker" | "aave" | "yearn" | "cream" | "exit"

export type ControlKey = "left" | "right" | "up" | "down" | "action"

export type Zone = {
  x: number
  y: number
  w: number
  h: number
  label: string
}

export type Telemetry = {
  stage: Stage
  objective: string
  instruction: string
  targetLabel: string
  flashCapital: number
  injection: number
  manipulatedPrice: number
  maxBorrowable: number
  drainedPercent: number
  phantomGap: number
  targetZone: ZoneName | null
  progress: number
  missionLog: string[]
  checklist: Array<{ id: string; label: string; done: boolean }>
}
