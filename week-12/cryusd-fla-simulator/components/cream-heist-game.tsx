"use client"

import { useCallback, useEffect, useMemo, useRef, useState } from "react"
import { Chess, type Move, type PieceSymbol, type Square } from "chess.js"
import type p5 from "p5"

const BASE_VAULT_VALUE = 10_000_000
const SHARES_OUTSTANDING = 10_000_000
const COLLATERAL_FACTOR = 0.75
const MARKET_LIQUIDITY = 130_000_000
const ATTACKER_SHARES = 1_000_000
const TARGET_INJECTION = 500_000_000

const FILES = "abcdefgh"

type Tone = "neutral" | "good" | "warn"
type PanelKey = "mission" | "telemetry" | "log" | "control"
type SnapAnchor = "tl" | "tr" | "bl" | "br"
type Difficulty = "strict" | "sandbox"
type CoachProfile = "beginner" | "analyst"

type CoachInfo = {
  title: string
  why: string
  next: string
  concept: string
  terms: string
  mechanism: string
  brokenInvariant: string
  onchainSignal: string
  defense: string
}

type MissionStep = {
  id: number
  title: string
  description: string
  required: {
    from: Square
    to: Square
    piece: PieceSymbol
    label: string
  }
  blackReply?: string
  success: string
}

type Economy = {
  flashCapital: number
  injection: number
  borrowCap: number
  drained: number
}

type LogEntry = {
  text: string
  tone: Tone
}

type LastMove = {
  from: Square
  to: Square
}

type DrawState = {
  fen: string
  selected: Square | null
  legalTargets: Square[]
  required: MissionStep["required"] | null
  lastMove: LastMove | null
  started: boolean
}

const MISSIONS: MissionStep[] = [
  {
    id: 1,
    title: "Maker Flash Loan",
    description: "Open with central pawn pressure to model first flash liquidity unlock.",
    required: { from: "e2", to: "e4", piece: "p", label: "e2 -> e4 (Pawn)" },
    blackReply: "a6",
    success: "Maker route activated. First liquidity pulse acquired.",
  },
  {
    id: 2,
    title: "Aave Flash Loan",
    description: "Develop knight to stack a second flash source.",
    required: { from: "g1", to: "f3", piece: "n", label: "g1 -> f3 (Knight)" },
    blackReply: "h6",
    success: "Aave liquidity added. Flash stack is now armed.",
  },
  {
    id: 3,
    title: "Inflate Yearn Vault",
    description: "Deploy bishop pressure to represent valuation distortion.",
    required: { from: "f1", to: "c4", piece: "b", label: "f1 -> c4 (Bishop)" },
    blackReply: "a5",
    success: "Vault valuation inflated. Apparent collateral diverges from reality.",
  },
  {
    id: 4,
    title: "Post Collateral At Cream",
    description: "Queen shift mirrors posting manipulated collateral.",
    required: { from: "d1", to: "e2", piece: "q", label: "d1 -> e2 (Queen)" },
    blackReply: "h5",
    success: "Collateral posted. Borrow capacity now maps to manipulated value.",
  },
  {
    id: 5,
    title: "Drain Liquidity",
    description: "Stabilize position while automated borrow bursts keep draining reserves.",
    required: { from: "c2", to: "c3", piece: "p", label: "c2 -> c3 (Pawn)" },
    blackReply: "a4",
    success: "Liquidity extraction started. Market reserve is collapsing.",
  },
  {
    id: 6,
    title: "Exfiltrate",
    description: "Castle king side to symbolize coordinated bridge exfiltration.",
    required: { from: "e1", to: "g1", piece: "k", label: "e1 -> g1 (King side castle)" },
    success: "Exfil complete. Attack chain executed end-to-end.",
  },
]

const INITIAL_ECONOMY: Economy = {
  flashCapital: 0,
  injection: 0,
  borrowCap: 0,
  drained: 0,
}

function clamp(value: number, min: number, max: number) {
  return Math.min(max, Math.max(min, value))
}

function money(value: number) {
  return new Intl.NumberFormat("en-US", {
    style: "currency",
    currency: "USD",
    maximumFractionDigits: 0,
  }).format(value)
}

function toneClass(tone: Tone) {
  if (tone === "good") return "text-emerald-100"
  if (tone === "warn") return "text-rose-100"
  return "text-cyan-100/95"
}

function coachCopy(started: boolean, stage: number, profile: CoachProfile): CoachInfo {
  if (!started) {
    return {
      title: "What Is A Flash Loan?",
      why: "A flash loan is uncollateralized capital borrowed and repaid inside one transaction. Attackers chain actions fast before state settles.",
      next: "Press Start Operation, then execute required move highlights.",
      concept: "One-tx borrowed liquidity enables temporary market distortion.",
      terms: "Flash loan, atomic transaction, temporary buying power",
      mechanism: "Borrow -> manipulate state -> extract value -> repay, all inside one atomic path.",
      brokenInvariant: "Healthy systems assume temporary state cannot mint durable borrow capacity.",
      onchainSignal: "Large same-block borrows and multi-protocol call chains with unusual token routing.",
      defense: "Real-time risk checks on transient state, borrow caps, and oracle/accounting sanity guards.",
    }
  }

  if (stage === 0) {
    return {
      title: "Stage 1: First Liquidity Pulse",
      why:
        profile === "analyst"
          ? "First flash source establishes principal that can be recycled across protocols before settlement."
          : "The attacker first sources large temporary capital from Maker to create enough force for manipulation.",
      next: "Play the highlighted required move.",
      concept: "Temporary capital is the fuel for downstream valuation abuse.",
      terms: "Flash principal, atomic composability",
      mechanism: "Acquire large notional without pre-funded collateral by relying on same-tx repayment.",
      brokenInvariant: "Assumption that borrow size always reflects real long-lived capital.",
      onchainSignal: "Single transaction starts with debt leg and quickly touches multiple lending/vault contracts.",
      defense: "Throttle flash exposure per block and enforce dynamic borrow ceilings.",
    }
  }

  if (stage === 1) {
    return {
      title: "Stage 2: Stack Flash Sources",
      why:
        profile === "analyst"
          ? "Multi-source flash routing increases depth, reducing slippage/constraint risk during manipulation."
          : "Combining Maker and Aave increases total pressure and attack budget.",
      next: "Execute the next required mission move.",
      concept: "Multi-source flash liquidity compounds manipulation capacity.",
      terms: "Liquidity stacking, path composability",
      mechanism: "Aggregate principal from independent pools to increase effective exploit bandwidth.",
      brokenInvariant: "Risk engines treat each pool in isolation while attacker composes them atomically.",
      onchainSignal: "Back-to-back flash borrow events from separate pools in one tx trace.",
      defense: "Cross-protocol anomaly detection and aggregate exposure checks.",
    }
  }

  if (stage === 2) {
    return {
      title: "Stage 3: Inflate Vault Value",
      why:
        profile === "analyst"
          ? "Donation-style asset injection can raise vault share price when assets increase without proportional share minting."
          : "Capital is injected where accounting can be temporarily distorted, inflating apparent collateral value.",
      next: "Follow the required move to complete inflation setup.",
      concept: "Book value diverges from real redeemable value.",
      terms: "Share price inflation, donation attack, accounting oracle",
      mechanism: "If $P'=\frac{V_0+I}{S}$ rises via injected assets $I$ while shares $S$ stay fixed, collateral app value jumps.",
      brokenInvariant: "Share price assumed to track organic market value rather than manipulable accounting state.",
      onchainSignal: "Large vault asset transfer with negligible corresponding share mint/burn activity.",
      defense: "Use TWAP/lagged valuation, donation-resistant accounting, and mint/burn consistency checks.",
    }
  }

  if (stage === 3) {
    return {
      title: "Stage 4: Post Phantom Collateral",
      why:
        profile === "analyst"
          ? "Collateral engine ingests manipulated share valuation and computes borrow limit from overstated notional."
          : "The protocol accepts inflated valuation as collateral, granting borrow power that should not exist.",
      next: "Execute the required move to post at Cream.",
      concept: "Risk engine trusts manipulated pricing inputs.",
      terms: "Collateral factor, borrow limit, phantom equity",
      mechanism: "Borrow power $B=\min(L,CF\cdot A_{shares}\cdot P')$ inflates as $P'$ is manipulated.",
      brokenInvariant: "Borrow limits expected to be bounded by economically realizable collateral value.",
      onchainSignal: "Sudden jump in account liquidity/health with no proportional external market move.",
      defense: "Collateral haircut caps, rapid-change clamps, and independent oracle cross-checks.",
    }
  }

  if (stage === 4) {
    return {
      title: "Stage 5: Drain Liquidity",
      why:
        profile === "analyst"
          ? "Protocol converts synthetic borrow headroom into real token outflows, creating solvency gap."
          : "Borrowing against phantom collateral extracts real assets from the pool.",
      next: "Complete required move to continue drain sequence.",
      concept: "Fake collateral unlocks real token outflows.",
      terms: "Liquidity drain, solvency gap, bad debt",
      mechanism: "Real reserves leave pool while collateral mark remains inflated until repricing/recovery.",
      brokenInvariant: "Pool assets assumed recoverable against posted collateral under stress.",
      onchainSignal: "Rapid borrow bursts, reserve utilization spikes, and abrupt available-liquidity collapse.",
      defense: "Per-block outflow caps, circuit breakers, and dynamic liquidation throttles.",
    }
  }

  if (stage === 5) {
    return {
      title: "Stage 6: Exfiltrate",
      why:
        profile === "analyst"
          ? "Post-drain routing fragments flows and reduces recovery probability before governance response."
          : "After extraction, funds are routed away quickly to prevent recovery actions.",
      next: "Play final required move to complete exfiltration.",
      concept: "Speed + routing finalizes exploit profit.",
      terms: "Exfiltration, bridge hop, laundering path",
      mechanism: "Move assets across venues/chains to increase tracking and intervention latency.",
      brokenInvariant: "Assumes response time can outpace adversarial routing speed.",
      onchainSignal: "Immediate transfer fan-out to bridges/mix paths after reserve drain.",
      defense: "Real-time monitoring hooks, emergency pause triggers, and post-incident tracing workflows.",
    }
  }

  return {
    title: "Debrief",
    why:
      profile === "analyst"
        ? "Chain complete: temporary accounting distortion translated into durable balance-sheet damage."
        : "You just executed the full exploit chain from temporary liquidity to permanent pool loss.",
    next: "Replay in Strict or Sandbox to reinforce intuition.",
    concept: "Temporary valuation manipulation can create lasting insolvency.",
    terms: "Bad debt crystallization, insolvency realization",
    mechanism: "Phantom collateral gap converts into unrecoverable protocol loss once prices normalize.",
    brokenInvariant: "Collateral quality and liquidity were overestimated at decision time.",
    onchainSignal: "Post-event reserve deficit and abnormal liquidation coverage shortfall.",
    defense: "Defense-in-depth: resilient pricing, accounting hardening, and kill-switch governance latency reduction.",
  }
}

function squareToCoord(square: Square) {
  const file = FILES.indexOf(square[0])
  const rank = Number(square[1])
  return { file, rank }
}

function applyMissionEconomy(index: number, prev: Economy): Economy {
  if (index === 0) return { ...prev, flashCapital: prev.flashCapital + 280_000_000 }
  if (index === 1) return { ...prev, flashCapital: prev.flashCapital + 320_000_000 }
  if (index === 2) return { ...prev, injection: TARGET_INJECTION }

  if (index === 3) {
    const manipulatedPrice = (BASE_VAULT_VALUE + prev.injection) / SHARES_OUTSTANDING
    const apparentCollateral = ATTACKER_SHARES * manipulatedPrice
    const borrowCap = Math.min(MARKET_LIQUIDITY, apparentCollateral * COLLATERAL_FACTOR)
    return { ...prev, borrowCap }
  }

  if (index === 4) return { ...prev, drained: Math.round(prev.borrowCap * 0.72) }
  if (index === 5) return { ...prev, drained: prev.borrowCap }
  return prev
}

function buildPieceSvg(type: PieceSymbol, color: "w" | "b") {
  const isWhite = color === "w"
  const base = isWhite ? "#f2f8ff" : "#141b2a"
  const edge = isWhite ? "#5a7791" : "#d6e5ff"
  const accent = isWhite ? "#8adfff" : "#6dc2ff"
  const glow = isWhite ? "rgba(170,236,255,0.35)" : "rgba(90,170,255,0.3)"

  let shape = ""
  if (type === "p") {
    shape = '<circle cx="60" cy="38" r="12" /><path d="M40 86h40l-6-32H46z" /><rect x="34" y="86" width="52" height="10" rx="3" />'
  }
  if (type === "r") {
    shape = '<rect x="40" y="32" width="40" height="44" rx="4" /><rect x="34" y="76" width="52" height="12" rx="3" /><rect x="36" y="24" width="10" height="8" /><rect x="55" y="24" width="10" height="8" /><rect x="74" y="24" width="10" height="8" />'
  }
  if (type === "n") {
    shape = '<path d="M42 88h40l-6-22-16-8-4-13-14 8 5 12z" /><path d="M46 44c8-12 22-16 34-8l-11 8c4 4 6 9 4 14-6-7-14-9-23-7z" />'
  }
  if (type === "b") {
    shape = '<path d="M60 24c10 0 17 8 17 18 0 6-3 10-6 14l-4 4 7 24H46l7-24-4-4c-3-4-6-8-6-14 0-10 7-18 17-18z" /><path d="M58 34l8 8-12 18" stroke-width="4" fill="none" />'
  }
  if (type === "q") {
    shape = '<path d="M34 84h52l-7-32-12 8-7-15-7 15-12-8z" /><circle cx="42" cy="34" r="5" /><circle cx="60" cy="28" r="5" /><circle cx="78" cy="34" r="5" /><rect x="34" y="84" width="52" height="11" rx="3" />'
  }
  if (type === "k") {
    shape = '<path d="M40 84h40l-5-30-10-8h-10l-10 8z" /><rect x="34" y="84" width="52" height="11" rx="3" /><path d="M60 22v16M52 30h16" stroke-width="5" fill="none" />'
  }

  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 120 120"><defs><filter id="g"><feGaussianBlur stdDeviation="2"/></filter></defs><circle cx="60" cy="60" r="54" fill="${glow}" filter="url(#g)"/><circle cx="60" cy="60" r="50" fill="${base}" stroke="${edge}" stroke-width="4"/><g fill="${accent}" stroke="${edge}" stroke-width="3" stroke-linecap="round" stroke-linejoin="round">${shape}</g></svg>`
}

export default function CreamHeistGame() {
  const boardHostRef = useRef<HTMLDivElement | null>(null)
  const sheetRef = useRef<HTMLDivElement | null>(null)

  const gameRef = useRef(new Chess())
  const startedRef = useRef(false)
  const stageRef = useRef(0)
  const selectedRef = useRef<Square | null>(null)
  const timelineRef = useRef<string[]>([gameRef.current.fen()])

  const dragRef = useRef({
    active: false,
    offsetX: 0,
    offsetY: 0,
  })

  const [started, setStarted] = useState(false)
  const [difficulty, setDifficulty] = useState<Difficulty>("strict")
  const [stage, setStage] = useState(0)
  const [fen, setFen] = useState(gameRef.current.fen())
  const [moveCount, setMoveCount] = useState(0)
  const [history, setHistory] = useState<string[]>([])
  const [timeline, setTimeline] = useState<string[]>([gameRef.current.fen()])
  const [timelineCursor, setTimelineCursor] = useState(0)
  const [selected, setSelected] = useState<Square | null>(null)
  const [legalTargets, setLegalTargets] = useState<Square[]>([])
  const [lastMove, setLastMove] = useState<LastMove | null>(null)
  const [status, setStatus] = useState("Press Start Operation to begin the guided attack line.")
  const [economy, setEconomy] = useState<Economy>(INITIAL_ECONOMY)
  const [logs, setLogs] = useState<LogEntry[]>([
    { text: "System armed. Chess rules validated by chess.js.", tone: "neutral" },
  ])

  const [openPanel, setOpenPanel] = useState<PanelKey | null>("mission")
  const [panelAnchor, setPanelAnchor] = useState<SnapAnchor>("br")
  const [panelPos, setPanelPos] = useState({ x: 0, y: 0 })
  const [dragging, setDragging] = useState(false)
  const [contentVisible, setContentVisible] = useState(true)
  const [coachExpanded, setCoachExpanded] = useState(false)
  const [coachProfile, setCoachProfile] = useState<CoachProfile>("analyst")

  const displayFen = timeline[timelineCursor] ?? fen
  const coach = coachCopy(started, stage, coachProfile)

  const drawStateRef = useRef<DrawState>({
    fen: displayFen,
    selected,
    legalTargets,
    required: null,
    lastMove,
    started,
  })

  useEffect(() => {
    startedRef.current = started
  }, [started])

  useEffect(() => {
    stageRef.current = stage
  }, [stage])

  useEffect(() => {
    selectedRef.current = selected
  }, [selected])

  useEffect(() => {
    drawStateRef.current = {
      fen: displayFen,
      selected,
      legalTargets,
      required: started && stage < MISSIONS.length ? MISSIONS[stage].required : null,
      lastMove,
      started,
    }
  }, [displayFen, selected, legalTargets, stage, lastMove, started])

  const derived = useMemo(() => {
    const basePrice = BASE_VAULT_VALUE / SHARES_OUTSTANDING
    const manipulatedPrice = (BASE_VAULT_VALUE + economy.injection) / SHARES_OUTSTANDING
    const apparentCollateral = ATTACKER_SHARES * manipulatedPrice
    const realCollateral = ATTACKER_SHARES * basePrice
    const phantomGap = apparentCollateral - realCollateral
    const drainedPercent = MARKET_LIQUIDITY > 0 ? (economy.drained / MARKET_LIQUIDITY) * 100 : 0
    const progress = started ? clamp(stage / MISSIONS.length, 0, 1) : 0
    const turn = displayFen.split(" ")[1] === "w" ? "White" : "Black"

    return {
      manipulatedPrice,
      phantomGap,
      drainedPercent,
      progress,
      turn,
    }
  }, [economy, stage, started, displayFen])

  const coachMath = useMemo(() => {
    const basePrice = BASE_VAULT_VALUE / SHARES_OUTSTANDING
    const manipulatedPrice = (BASE_VAULT_VALUE + economy.injection) / SHARES_OUTSTANDING
    const apparentCollateral = ATTACKER_SHARES * manipulatedPrice
    const realCollateral = ATTACKER_SHARES * basePrice
    const phantomGap = apparentCollateral - realCollateral
    const borrowCap = Math.min(MARKET_LIQUIDITY, apparentCollateral * COLLATERAL_FACTOR)
    const drainPct = MARKET_LIQUIDITY > 0 ? (economy.drained / MARKET_LIQUIDITY) * 100 : 0

    return {
      basePrice,
      manipulatedPrice,
      apparentCollateral,
      realCollateral,
      phantomGap,
      borrowCap,
      drainPct,
    }
  }, [economy.drained, economy.injection])

  const currentMission = started && stage < MISSIONS.length ? MISSIONS[stage] : null

  useEffect(() => {
    setContentVisible(false)
    const id = window.requestAnimationFrame(() => {
      setContentVisible(true)
    })
    return () => {
      window.cancelAnimationFrame(id)
    }
  }, [openPanel])

  const addLog = useCallback((text: string, tone: Tone = "neutral") => {
    setLogs((prev) => [...prev.slice(-8), { text, tone }])
  }, [])

  const clearSelection = useCallback(() => {
    setSelected(null)
    setLegalTargets([])
  }, [])

  const selectSquare = useCallback((square: Square) => {
    const game = gameRef.current
    const moves = game.moves({ square, verbose: true }) as Move[]
    setSelected(square)
    setLegalTargets(moves.map((m) => m.to as Square))
  }, [])

  const syncGameSnapshot = useCallback((pushToTimeline: boolean) => {
    const game = gameRef.current
    const nextFen = game.fen()
    const nextHistory = game.history()

    setFen(nextFen)
    setHistory(nextHistory)
    setMoveCount(nextHistory.length)

    if (pushToTimeline) {
      const nextTimeline = [...timelineRef.current, nextFen]
      timelineRef.current = nextTimeline
      setTimeline(nextTimeline)
      setTimelineCursor(nextTimeline.length - 1)
    }
  }, [])

  const playBlackReply = useCallback(
    (preferred?: string) => {
      const game = gameRef.current
      if (game.turn() !== "b") return

      let reply: Move | null = null
      if (preferred) {
        try {
          reply = game.move(preferred)
        } catch {
          reply = null
        }
      }

      if (!reply) {
        const legal = game.moves({ verbose: true }) as Move[]
        if (legal.length === 0) return
        const chosen = legal[Math.floor(Math.random() * Math.min(6, legal.length))]
        try {
          reply = game.move({ from: chosen.from, to: chosen.to, promotion: "q" })
        } catch {
          reply = null
        }
      }

      if (reply) {
        setLastMove({ from: reply.from as Square, to: reply.to as Square })
        addLog(`Defense replies ${reply.san}.`, "neutral")
        syncGameSnapshot(true)
      }
    },
    [addLog, syncGameSnapshot],
  )

  const startOperation = useCallback(() => {
    const game = gameRef.current
    game.reset()

    const initialFen = game.fen()

    setStarted(true)
    setStage(0)
    setFen(initialFen)
    setHistory([])
    setMoveCount(0)
    setLastMove(null)
    setEconomy(INITIAL_ECONOMY)
    setStatus(`Stage 1: ${MISSIONS[0].title}. Required move: ${MISSIONS[0].required.label}`)
    setCoachExpanded(false)
    setLogs([
      { text: "Operation started. Follow mission moves in sequence.", tone: "good" },
      { text: `Objective: ${MISSIONS[0].required.label}`, tone: "neutral" },
    ])
    clearSelection()

    timelineRef.current = [initialFen]
    setTimeline([initialFen])
    setTimelineCursor(0)
  }, [clearSelection])

  const handleSquareClick = useCallback(
    (square: Square) => {
      if (!startedRef.current) {
        setStatus("Start the operation first.")
        return
      }

      if (timelineCursor !== timeline.length - 1) {
        setStatus("Scrubber is in replay mode. Jump back to LIVE to continue playing.")
        addLog("Replay mode active. Move scrubber to LIVE before playing.", "warn")
        return
      }

      if (stageRef.current >= MISSIONS.length) return

      const game = gameRef.current
      const mission = MISSIONS[stageRef.current]
      const selectedSquare = selectedRef.current
      const currentTurn = game.turn()
      const pieceAtSquare = game.get(square)

      if (!selectedSquare) {
        if (pieceAtSquare && pieceAtSquare.color === currentTurn) {
          selectSquare(square)
          return
        }

        addLog("Select one of your current-turn pieces.", "warn")
        return
      }

      if (selectedSquare === square) {
        clearSelection()
        return
      }

      let attempted: Move | null = null
      try {
        attempted = game.move({ from: selectedSquare, to: square, promotion: "q" })
      } catch {
        attempted = null
      }

      if (!attempted) {
        if (pieceAtSquare && pieceAtSquare.color === currentTurn) {
          selectSquare(square)
        } else {
          addLog("Illegal chess move.", "warn")
        }
        return
      }

      const missionMatch =
        attempted.from === mission.required.from &&
        attempted.to === mission.required.to &&
        attempted.piece === mission.required.piece

      if (difficulty === "strict" && !missionMatch) {
        game.undo()
        setFen(game.fen())
        setStatus(`Strategic mismatch. Required move: ${mission.required.label}`)
        addLog(`Legal move ${attempted.san} rejected in STRICT mode.`, "warn")

        if (pieceAtSquare && pieceAtSquare.color === game.turn()) {
          selectSquare(square)
        } else {
          clearSelection()
        }
        return
      }

      clearSelection()
      setLastMove({ from: attempted.from as Square, to: attempted.to as Square })
      syncGameSnapshot(true)

      if (missionMatch) {
        setStatus(mission.success)
        addLog(`You played ${attempted.san}. ${mission.success}`, "good")
        addLog(`Why this works: ${coachCopy(true, stageRef.current, coachProfile).why}`, "neutral")
        setEconomy((prev) => applyMissionEconomy(stageRef.current, prev))

        playBlackReply(mission.blackReply)

        const nextStage = stageRef.current + 1
        setStage(nextStage)

        if (nextStage >= MISSIONS.length) {
          setStatus("Exploit chain complete. Collateral illusion converted into drained liquidity.")
          addLog("Mission complete. Replay to internalize exploit mechanics.", "good")
        } else {
          const next = MISSIONS[nextStage]
          setStatus(`Stage ${next.id}: ${next.title}. Required move: ${next.required.label}`)
          addLog(`Next objective: ${next.required.label}`, "neutral")
        }
      } else {
        setStatus(`Sandbox move ${attempted.san}. Objective unchanged: ${mission.required.label}`)
        addLog(`Sandbox accepted ${attempted.san}. Objective still ${mission.required.label}.`, "neutral")
        playBlackReply(mission.blackReply)
      }
    },
    [addLog, clearSelection, coachProfile, difficulty, playBlackReply, selectSquare, syncGameSnapshot, timeline, timelineCursor],
  )

  const getSnapPosition = useCallback((anchor: SnapAnchor, width: number, height: number) => {
    const margin = 14
    const topY = 86
    const bottomY = window.innerHeight - height - 90

    const leftX = margin
    const rightX = window.innerWidth - width - margin

    if (anchor === "tl") return { x: leftX, y: topY }
    if (anchor === "tr") return { x: rightX, y: topY }
    if (anchor === "bl") return { x: leftX, y: bottomY }
    return { x: rightX, y: bottomY }
  }, [])

  const snapToNearest = useCallback(
    (x: number, y: number, width: number, height: number) => {
      const anchors: SnapAnchor[] = ["tl", "tr", "bl", "br"]
      const cx = x + width / 2
      const cy = y + height / 2

      let bestAnchor: SnapAnchor = "br"
      let bestDist = Number.POSITIVE_INFINITY

      anchors.forEach((anchor) => {
        const pos = getSnapPosition(anchor, width, height)
        const ax = pos.x + width / 2
        const ay = pos.y + height / 2
        const d = (ax - cx) ** 2 + (ay - cy) ** 2
        if (d < bestDist) {
          bestDist = d
          bestAnchor = anchor
        }
      })

      const snapped = getSnapPosition(bestAnchor, width, height)
      return { anchor: bestAnchor, position: snapped }
    },
    [getSnapPosition],
  )

  const positionPanelFromAnchor = useCallback(() => {
    if (!sheetRef.current) return
    const width = sheetRef.current.offsetWidth
    const height = sheetRef.current.offsetHeight
    const pos = getSnapPosition(panelAnchor, width, height)
    setPanelPos(pos)
  }, [getSnapPosition, panelAnchor])

  useEffect(() => {
    if (!openPanel) return

    const id = window.requestAnimationFrame(() => {
      positionPanelFromAnchor()
    })

    const onResize = () => positionPanelFromAnchor()
    window.addEventListener("resize", onResize)

    return () => {
      window.cancelAnimationFrame(id)
      window.removeEventListener("resize", onResize)
    }
  }, [openPanel, positionPanelFromAnchor])

  const handleSheetDragStart = useCallback((e: React.PointerEvent<HTMLDivElement>) => {
    if (!sheetRef.current) return

    const rect = sheetRef.current.getBoundingClientRect()
    dragRef.current.active = true
    dragRef.current.offsetX = e.clientX - rect.left
    dragRef.current.offsetY = e.clientY - rect.top
    setDragging(true)

    e.currentTarget.setPointerCapture(e.pointerId)
  }, [])

  const handleSheetDragMove = useCallback((e: React.PointerEvent<HTMLDivElement>) => {
    if (!dragRef.current.active || !sheetRef.current) return

    const width = sheetRef.current.offsetWidth
    const height = sheetRef.current.offsetHeight
    const margin = 8

    const nextX = clamp(e.clientX - dragRef.current.offsetX, margin, window.innerWidth - width - margin)
    const nextY = clamp(e.clientY - dragRef.current.offsetY, margin, window.innerHeight - height - margin)
    setPanelPos({ x: nextX, y: nextY })
  }, [])

  const handleSheetDragEnd = useCallback(
    (e: React.PointerEvent<HTMLDivElement>) => {
      if (!dragRef.current.active || !sheetRef.current) return

      dragRef.current.active = false
      setDragging(false)
      e.currentTarget.releasePointerCapture(e.pointerId)

      const width = sheetRef.current.offsetWidth
      const height = sheetRef.current.offsetHeight
      const snap = snapToNearest(panelPos.x, panelPos.y, width, height)
      setPanelAnchor(snap.anchor)
      setPanelPos(snap.position)
    },
    [panelPos.x, panelPos.y, snapToNearest],
  )

  const togglePanel = useCallback((panel: PanelKey) => {
    setOpenPanel((prev) => (prev === panel ? null : panel))
  }, [])

  useEffect(() => {
    let mounted = true
    let instance: { remove: () => void } | null = null

    async function boot() {
      const p5Module = await import("p5")
      const P5 = p5Module.default

      if (!mounted || !boardHostRef.current) return

      instance = new P5((p: p5) => {
        let boardX = 0
        let boardY = 0
        let boardSize = 0
        let sq = 0

        const pieceImages: Record<string, HTMLImageElement> = {}

        function loadPieceSprites() {
          const colors: Array<"w" | "b"> = ["w", "b"]
          const pieces: PieceSymbol[] = ["k", "q", "r", "b", "n", "p"]

          colors.forEach((color) => {
            pieces.forEach((type) => {
              const svg = buildPieceSvg(type, color)
              const src = `data:image/svg+xml;utf8,${encodeURIComponent(svg)}`
              const img = new Image()
              img.src = src
              pieceImages[`${color}${type}`] = img
            })
          })
        }

        function layout() {
          const pad = 20
          boardSize = Math.floor(Math.max(280, Math.min(p.width, p.height) - pad * 2))
          boardX = Math.floor((p.width - boardSize) / 2)
          boardY = Math.floor((p.height - boardSize) / 2)
          sq = boardSize / 8
        }

        function pointToSquare(mx: number, my: number): Square | null {
          if (mx < boardX || my < boardY || mx > boardX + boardSize || my > boardY + boardSize) return null
          const file = Math.floor((mx - boardX) / sq)
          const rank = 8 - Math.floor((my - boardY) / sq)
          if (file < 0 || file > 7 || rank < 1 || rank > 8) return null
          return `${FILES[file]}${rank}` as Square
        }

        function squareTopLeft(square: Square) {
          const { file, rank } = squareToCoord(square)
          return {
            x: boardX + file * sq,
            y: boardY + (8 - rank) * sq,
          }
        }

        function drawBoard(state: DrawState) {
          p.clear()

          p.noStroke()
          p.fill(255, 255, 255, 22)
          p.rect(boardX - 14, boardY - 14, boardSize + 28, boardSize + 28, 22)

          for (let row = 0; row < 8; row += 1) {
            for (let col = 0; col < 8; col += 1) {
              const rank = 8 - row
              const square = `${FILES[col]}${rank}` as Square
              const light = (col + rank) % 2 === 0
              const selectedSquare = state.selected === square
              const legal = state.legalTargets.includes(square)
              const moved = !!state.lastMove && (state.lastMove.from === square || state.lastMove.to === square)

              const c = light ? [237, 244, 255, 236] : [43, 56, 72, 252]
              p.fill(moved ? 101 : c[0], moved ? 236 : c[1], moved ? 198 : c[2], moved ? 210 : c[3])
              p.rect(boardX + col * sq, boardY + row * sq, sq, sq)

              if (selectedSquare) {
                p.noFill()
                p.stroke(248, 252, 255, 250)
                p.strokeWeight(2)
                p.rect(boardX + col * sq + 2, boardY + row * sq + 2, sq - 4, sq - 4)
              }

              if (legal) {
                p.noStroke()
                p.fill(14, 23, 36, 155)
                p.circle(boardX + col * sq + sq / 2, boardY + row * sq + sq / 2, sq * 0.24)
              }
            }
          }

          if (state.required) {
            const from = squareTopLeft(state.required.from)
            const to = squareTopLeft(state.required.to)

            p.noFill()
            p.stroke(255, 170, 144, 245)
            p.strokeWeight(2.4)
            p.rect(from.x + 2, from.y + 2, sq - 4, sq - 4)

            p.stroke(125, 245, 208, 245)
            p.rect(to.x + 2, to.y + 2, sq - 4, sq - 4)

            p.stroke(190, 245, 255, 215)
            p.strokeWeight(1.5)
            p.line(from.x + sq / 2, from.y + sq / 2, to.x + sq / 2, to.y + sq / 2)
          }

          p.fill(211, 235, 255, 210)
          p.noStroke()
          p.textAlign(p.CENTER, p.CENTER)
          p.textSize(11)
          for (let f = 0; f < 8; f += 1) {
            p.text(FILES[f].toUpperCase(), boardX + f * sq + sq / 2, boardY + boardSize + 14)
          }

          p.textAlign(p.RIGHT, p.CENTER)
          for (let r = 8; r >= 1; r -= 1) {
            p.text(String(r), boardX - 8, boardY + (8 - r) * sq + sq / 2)
          }
        }

        function drawPieces(state: DrawState) {
          const game = new Chess(state.fen)
          const board = game.board()

          for (let row = 0; row < 8; row += 1) {
            for (let col = 0; col < 8; col += 1) {
              const piece = board[row][col]
              if (!piece) continue

              const key = `${piece.color}${piece.type}`
              const img = pieceImages[key]
              const cx = boardX + col * sq + sq / 2
              const cy = boardY + row * sq + sq / 2

              const phase = row * 13 + col * 7 + (piece.color === "w" ? 0 : 18)
              const bob = Math.sin((p.frameCount + phase) / 18) * 1.4
              const pulse = 1 + Math.sin((p.frameCount + phase) / 15) * 0.03
              const size = sq * 0.9 * pulse

              if (img && img.complete) {
                ;(p.drawingContext as CanvasRenderingContext2D).drawImage(img, cx - size / 2, cy - size / 2 + bob, size, size)
              } else {
                p.noStroke()
                p.fill(piece.color === "w" ? p.color(248, 252, 255, 230) : p.color(13, 18, 30, 230))
                p.circle(cx, cy, sq * 0.68)
              }
            }
          }
        }

        p.setup = () => {
          const host = boardHostRef.current as HTMLDivElement
          const renderer = p.createCanvas(host.clientWidth, host.clientHeight)
          renderer.parent(host)
          p.frameRate(60)
          ;(renderer.elt as HTMLCanvasElement).oncontextmenu = () => false
          loadPieceSprites()
          layout()
        }

        p.windowResized = () => {
          const host = boardHostRef.current as HTMLDivElement
          p.resizeCanvas(host.clientWidth, host.clientHeight)
          layout()
        }

        p.mousePressed = () => {
          const target = pointToSquare(p.mouseX, p.mouseY)
          if (target) handleSquareClick(target)
          return false
        }

        const touchHandlers = p as unknown as {
          touchStarted?: () => boolean
        }

        touchHandlers.touchStarted = () => {
          const target = pointToSquare(p.mouseX, p.mouseY)
          if (target) handleSquareClick(target)
          return false
        }

        p.draw = () => {
          layout()
          const state = drawStateRef.current
          drawBoard(state)
          drawPieces(state)

          if (!state.started) {
            p.noStroke()
            p.fill(7, 12, 20, 130)
            p.rect(boardX, boardY, boardSize, boardSize)
            p.fill(236, 247, 255)
            p.textAlign(p.CENTER, p.CENTER)
            p.textSize(24)
            p.text("Start Operation", boardX + boardSize / 2, boardY + boardSize / 2 - 10)
            p.textSize(13)
            p.text("Board is locked until mission starts.", boardX + boardSize / 2, boardY + boardSize / 2 + 18)
          }
        }
      })
    }

    boot()

    return () => {
      mounted = false
      instance?.remove()
    }
  }, [handleSquareClick])

  return (
    <div className="relative h-[100svh] w-full overflow-hidden bg-[#090d16] text-white">
      <div className="pointer-events-none absolute inset-0 bg-[radial-gradient(circle_at_14%_16%,rgba(145,227,255,0.22),transparent_35%),radial-gradient(circle_at_84%_76%,rgba(255,134,165,0.18),transparent_42%),linear-gradient(160deg,rgba(255,255,255,0.08),transparent_28%)]" />

      <div ref={boardHostRef} className="absolute inset-0 z-0" />

      <div className="pointer-events-none absolute inset-0 z-20">
        <div className="pointer-events-none absolute left-1/2 top-3 w-[min(95vw,760px)] -translate-x-1/2 md:top-4">
          <div className="rounded-2xl border border-white/30 bg-white/10 px-3 py-2 shadow-[inset_0_1px_0_rgba(255,255,255,0.45),0_18px_48px_rgba(0,0,0,0.35)] backdrop-blur-2xl md:px-4 md:py-3">
            <div className="flex flex-wrap items-center gap-x-3 gap-y-1 text-xs md:text-sm">
              <span className="rounded-lg border border-white/25 bg-white/10 px-2 py-1 text-[10px] uppercase tracking-[0.16em] text-cyan-100/85">
                Stage {stage}/{MISSIONS.length}
              </span>
              <span className="text-cyan-50/95">{currentMission ? currentMission.required.label : status}</span>
              <span className="text-cyan-100/75">Mode: {difficulty === "strict" ? "Strict" : "Sandbox"}</span>
            </div>
            <div className="mt-2 h-1.5 overflow-hidden rounded-full border border-white/20 bg-white/10">
              <div
                className="h-full bg-gradient-to-r from-cyan-200 via-emerald-200 to-rose-200 transition-all duration-500"
                style={{ width: `${Math.round(derived.progress * 100)}%` }}
              />
            </div>
          </div>
        </div>

        <div className="pointer-events-none absolute bottom-20 left-3 z-20 w-[min(90vw,420px)] md:bottom-5 md:left-5">
          <div className="pointer-events-auto rounded-2xl border border-white/30 bg-white/10 p-3 shadow-[inset_0_1px_0_rgba(255,255,255,0.4),0_22px_60px_rgba(0,0,0,0.4)] backdrop-blur-2xl md:p-4">
            <div className="flex items-center justify-between gap-2">
              <p className="text-[10px] uppercase tracking-[0.16em] text-cyan-100/85">Tactical Coach</p>
              <div className="flex items-center gap-1.5">
                <button
                  type="button"
                  onClick={() => setCoachProfile("beginner")}
                  className={`rounded-md border px-2 py-1 text-[10px] uppercase tracking-[0.14em] ${
                    coachProfile === "beginner"
                      ? "border-cyan-100/75 bg-cyan-100/85 text-black"
                      : "border-white/30 bg-white/10 text-cyan-50/90"
                  }`}
                >
                  Beginner
                </button>
                <button
                  type="button"
                  onClick={() => setCoachProfile("analyst")}
                  className={`rounded-md border px-2 py-1 text-[10px] uppercase tracking-[0.14em] ${
                    coachProfile === "analyst"
                      ? "border-cyan-100/75 bg-cyan-100/85 text-black"
                      : "border-white/30 bg-white/10 text-cyan-50/90"
                  }`}
                >
                  Analyst
                </button>
                <button
                  type="button"
                  onClick={() => setCoachExpanded((v) => !v)}
                  className="rounded-md border border-white/30 bg-white/10 px-2 py-1 text-[10px] uppercase tracking-[0.14em] text-cyan-50/90"
                >
                  {coachExpanded ? "Less" : "More"}
                </button>
              </div>
            </div>

            <p className="mt-1 text-sm font-semibold text-white md:text-base">{coach.title}</p>
            <p className="mt-1 text-xs text-cyan-50/90 md:text-sm">{coach.why}</p>
            <p className="mt-2 text-[11px] text-emerald-100/95">Next: {coach.next}</p>
            <p className="mt-1 text-[11px] text-cyan-100/75">Concept: {coach.concept}</p>

            <div
              className={`overflow-hidden transition-all duration-300 ease-out ${
                coachExpanded ? "mt-3 max-h-[380px] opacity-100" : "max-h-0 opacity-0"
              }`}
            >
              <div className="rounded-xl border border-white/20 bg-black/20 p-3 text-[11px] text-cyan-50/90">
                <p className="mb-2 text-[10px] uppercase tracking-[0.14em] text-cyan-100/85">Protocol Lens</p>
                <p>Terms: {coach.terms}</p>
                <p className="mt-1">Mechanism: {coach.mechanism}</p>
                <p className="mt-1">Broken invariant: {coach.brokenInvariant}</p>
                <p className="mt-1">On-chain signal: {coach.onchainSignal}</p>
                <p className="mt-1">Defensive control: {coach.defense}</p>

                <p className="mb-2 text-[10px] uppercase tracking-[0.14em] text-cyan-100/85">Exploit Math</p>
                <p>P&apos; = (V0 + I) / S</p>
                <p>C_app = A_shares * P&apos;</p>
                <p>B = min(L, C_app * CF)</p>
                <p>Drain% = (D / L) * 100</p>

                <p className="mt-3 text-[10px] uppercase tracking-[0.14em] text-cyan-100/85">Worked Example</p>
                <p>V0={money(BASE_VAULT_VALUE)}, I={money(economy.injection)}, S={SHARES_OUTSTANDING.toLocaleString()}</p>
                <p>P&apos;={coachMath.manipulatedPrice.toFixed(2)} and base P={coachMath.basePrice.toFixed(2)}</p>
                <p>C_app={money(coachMath.apparentCollateral)} vs C_real={money(coachMath.realCollateral)}</p>
                <p>Phantom gap={money(coachMath.phantomGap)}</p>
                <p>Borrow cap={money(coachMath.borrowCap)} with CF={COLLATERAL_FACTOR.toFixed(2)}</p>
                <p>Drained={money(economy.drained)} ({coachMath.drainPct.toFixed(1)}% of {money(MARKET_LIQUIDITY)})</p>
              </div>
            </div>
          </div>
        </div>

        <div
          ref={sheetRef}
          style={{ left: `${panelPos.x}px`, top: `${panelPos.y}px` }}
          className={`pointer-events-auto absolute z-30 w-[min(94vw,420px)] max-h-[min(65vh,620px)] overflow-hidden rounded-[24px] border border-white/30 bg-white/10 shadow-[inset_0_1px_0_rgba(255,255,255,0.4),0_26px_80px_rgba(0,0,0,0.45)] backdrop-blur-2xl transition-[opacity,transform] duration-300 ease-out ${
            openPanel ? "translate-y-0 scale-100 opacity-100" : "pointer-events-none translate-y-3 scale-95 opacity-0"
          } ${dragging ? "cursor-grabbing" : ""}`}
          onPointerMove={handleSheetDragMove}
          onPointerUp={handleSheetDragEnd}
          onPointerCancel={handleSheetDragEnd}
        >
          <div
            className="flex cursor-grab items-center justify-between border-b border-white/15 px-3 py-2"
            onPointerDown={handleSheetDragStart}
          >
            <p className="text-[11px] uppercase tracking-[0.18em] text-cyan-100/85">
              {openPanel === "mission"
                ? "Mission Deck"
                : openPanel === "telemetry"
                  ? "Exploit Telemetry"
                  : openPanel === "log"
                    ? "Combat Log"
                    : "Control"}
            </p>
            <div className="flex items-center gap-2">
              <span className="text-[10px] uppercase tracking-[0.14em] text-cyan-100/65">Snap: {panelAnchor.toUpperCase()}</span>
              <button
                type="button"
                onPointerDown={(e) => {
                  e.stopPropagation()
                }}
                onClick={(e) => {
                  e.stopPropagation()
                  setOpenPanel(null)
                }}
                className="rounded-lg border border-white/30 bg-white/10 px-2 py-1 text-[10px] uppercase tracking-[0.16em] text-cyan-50/90"
              >
                Minimize
              </button>
            </div>
          </div>

          <div
            className={`max-h-[calc(min(65vh,620px)-45px)] overflow-auto p-3 text-sm transition-all duration-350 ease-out ${
              contentVisible ? "translate-y-0 opacity-100" : "translate-y-2 opacity-0"
            }`}
          >
            {openPanel === "mission" && (
              <div className="space-y-2">
                {MISSIONS.map((m, idx) => {
                  const done = stage > idx
                  const active = stage === idx && started
                  return (
                    <div
                      key={m.id}
                      className={`rounded-xl border px-3 py-2 ${
                        active
                          ? "border-cyan-100/80 bg-cyan-100/20"
                          : done
                            ? "border-emerald-100/70 bg-emerald-100/20"
                            : "border-white/20 bg-white/5"
                      }`}
                    >
                      <p className="text-[10px] uppercase tracking-[0.14em] text-cyan-100/80">Stage {m.id}</p>
                      <p className="mt-0.5 font-medium text-white">{m.title}</p>
                      <p className="mt-1 text-xs text-cyan-50/85">{m.required.label}</p>
                      <p className="mt-1 text-xs text-cyan-50/75">{m.description}</p>
                    </div>
                  )
                })}
              </div>
            )}

            {openPanel === "telemetry" && (
              <div className="space-y-3">
                <div className="grid grid-cols-2 gap-2 text-xs">
                  <MetricCard label="Turn" value={derived.turn} />
                  <MetricCard label="Moves" value={String(moveCount)} />
                  <MetricCard label="Flash Capital" value={money(economy.flashCapital)} />
                  <MetricCard label="Injection" value={money(economy.injection)} />
                  <MetricCard label="Price / Share" value={derived.manipulatedPrice.toFixed(2)} />
                  <MetricCard label="Borrow Cap" value={money(economy.borrowCap)} />
                  <MetricCard label="Drained" value={money(economy.drained)} />
                  <MetricCard label="Drained %" value={`${derived.drainedPercent.toFixed(1)}%`} />
                  <MetricCard label="Phantom Gap" value={money(derived.phantomGap)} span2 />
                </div>

                <MiniMap fen={displayFen} required={currentMission?.required ?? null} lastMove={lastMove} />
              </div>
            )}

            {openPanel === "log" && (
              <div className="space-y-3">
                <div className="rounded-xl border border-white/20 bg-black/20 p-3">
                  <div className="mb-2 flex items-center justify-between gap-2 text-xs text-cyan-100/85">
                    <span>Move History Scrubber</span>
                    <button
                      type="button"
                      onClick={() => setTimelineCursor(timeline.length - 1)}
                      className="rounded-md border border-white/25 bg-white/10 px-2 py-1 text-[10px] uppercase tracking-[0.14em]"
                    >
                      Live
                    </button>
                  </div>

                  <input
                    type="range"
                    min={0}
                    max={Math.max(0, timeline.length - 1)}
                    value={timelineCursor}
                    onChange={(e) => setTimelineCursor(Number(e.target.value))}
                    className="sim-range"
                  />
                  <p className="mt-1 text-[11px] text-cyan-50/80">
                    Ply {timelineCursor}/{Math.max(0, timeline.length - 1)}
                  </p>
                </div>

                <div className="rounded-xl border border-white/20 bg-black/20 p-3">
                  <p className="mb-2 text-xs uppercase tracking-[0.16em] text-cyan-100/85">SAN Timeline</p>
                  <div className="max-h-44 space-y-1 overflow-auto text-xs">
                    {history.length === 0 && <p className="text-cyan-50/70">No moves yet.</p>}
                    {history.length > 0 &&
                      Array.from({ length: Math.ceil(history.length / 2) }).map((_, idx) => {
                        const white = history[idx * 2] ?? ""
                        const black = history[idx * 2 + 1] ?? ""
                        const rowStartPly = idx * 2 + 1
                        const rowEndPly = idx * 2 + (black ? 2 : 1)
                        const active = timelineCursor >= rowStartPly && timelineCursor <= rowEndPly

                        return (
                          <p key={`${idx}-${white}-${black}`} className={active ? "text-emerald-100" : "text-cyan-50/85"}>
                            {idx + 1}. {white} {black}
                          </p>
                        )
                      })}
                  </div>
                </div>

                <div className="rounded-xl border border-white/20 bg-black/20 p-3">
                  <p className="mb-2 text-xs uppercase tracking-[0.16em] text-cyan-100/85">Event Feed</p>
                  <div className="space-y-1.5 text-xs">
                    {logs.map((entry, idx) => (
                      <p key={`${entry.text}-${idx}`} className={toneClass(entry.tone)}>
                        {entry.text}
                      </p>
                    ))}
                  </div>
                </div>
              </div>
            )}

            {openPanel === "control" && (
              <div className="space-y-3">
                <button
                  type="button"
                  onClick={startOperation}
                  className="w-full rounded-xl border border-cyan-100/75 bg-gradient-to-br from-cyan-100/90 to-emerald-100/90 px-4 py-3 text-sm font-semibold uppercase tracking-[0.16em] text-black transition-opacity hover:opacity-90"
                >
                  {started ? "Restart Operation" : "Start Operation"}
                </button>

                <div className="rounded-xl border border-white/20 bg-black/20 p-3">
                  <p className="mb-2 text-xs uppercase tracking-[0.16em] text-cyan-100/85">Difficulty</p>
                  <div className="grid grid-cols-2 gap-2">
                    <button
                      type="button"
                      onClick={() => setDifficulty("strict")}
                      className={`rounded-lg border px-3 py-2 text-xs uppercase tracking-[0.14em] ${
                        difficulty === "strict"
                          ? "border-cyan-100/75 bg-cyan-100/85 text-black"
                          : "border-white/25 bg-white/10 text-cyan-50/90"
                      }`}
                    >
                      Strict Line
                    </button>
                    <button
                      type="button"
                      onClick={() => setDifficulty("sandbox")}
                      className={`rounded-lg border px-3 py-2 text-xs uppercase tracking-[0.14em] ${
                        difficulty === "sandbox"
                          ? "border-cyan-100/75 bg-cyan-100/85 text-black"
                          : "border-white/25 bg-white/10 text-cyan-50/90"
                      }`}
                    >
                      Sandbox
                    </button>
                  </div>
                </div>

                <div className="rounded-xl border border-white/20 bg-black/20 p-3 text-xs text-cyan-50/85">
                  <p>1. Click a piece to select it.</p>
                  <p>2. Click destination square to move.</p>
                  <p>3. Strict mode enforces mission move exactly.</p>
                  <p>4. Sandbox allows legal deviations while objective remains.</p>
                </div>
              </div>
            )}
          </div>
        </div>

        <div className="pointer-events-auto absolute bottom-3 right-3 z-40 flex max-w-[min(95vw,560px)] flex-wrap justify-end gap-2 md:bottom-5 md:right-5">
          <ToolboxButton label="Mission" active={openPanel === "mission"} onClick={() => togglePanel("mission")} />
          <ToolboxButton label="Telemetry" active={openPanel === "telemetry"} onClick={() => togglePanel("telemetry")} />
          <ToolboxButton label="Log" active={openPanel === "log"} onClick={() => togglePanel("log")} />
          <ToolboxButton label="Control" active={openPanel === "control"} onClick={() => togglePanel("control")} />
        </div>
      </div>
    </div>
  )
}

function MetricCard({
  label,
  value,
  span2,
}: {
  label: string
  value: string
  span2?: boolean
}) {
  return (
    <div className={`rounded-xl border border-white/25 bg-white/10 px-2.5 py-2 backdrop-blur-xl ${span2 ? "col-span-2" : ""}`}>
      <p className="text-[10px] uppercase tracking-[0.14em] text-cyan-100/75">{label}</p>
      <p className="mt-0.5 font-mono text-sm text-white">{value}</p>
    </div>
  )
}

function ToolboxButton({
  label,
  active,
  onClick,
}: {
  label: string
  active: boolean
  onClick: () => void
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={`rounded-xl border px-3 py-2 text-xs font-semibold uppercase tracking-[0.14em] transition-colors ${
        active
          ? "border-cyan-100/75 bg-cyan-100/85 text-black"
          : "border-white/30 bg-white/10 text-cyan-50/90 hover:bg-white/20"
      }`}
    >
      {label}
    </button>
  )
}

function MiniMap({
  fen,
  required,
  lastMove,
}: {
  fen: string
  required: MissionStep["required"] | null
  lastMove: LastMove | null
}) {
  const board = useMemo(() => new Chess(fen).board(), [fen])

  return (
    <div className="rounded-xl border border-white/20 bg-black/20 p-3">
      <p className="mb-2 text-xs uppercase tracking-[0.16em] text-cyan-100/85">Tactical Minimap</p>
      <div className="grid grid-cols-8 overflow-hidden rounded-lg border border-white/20">
        {board.flatMap((row, rowIndex) =>
          row.map((piece, colIndex) => {
            const rank = 8 - rowIndex
            const square = `${FILES[colIndex]}${rank}` as Square
            const light = (colIndex + rank) % 2 === 0
            const reqFrom = required?.from === square
            const reqTo = required?.to === square
            const moved = !!lastMove && (lastMove.from === square || lastMove.to === square)

            return (
              <div
                key={`${square}-${piece?.type ?? ""}${piece?.color ?? ""}`}
                className={`relative flex aspect-square items-center justify-center border border-black/10 text-[10px] ${
                  light ? "bg-cyan-50/85" : "bg-slate-700/95"
                } ${moved ? "ring-1 ring-emerald-300/90" : ""}`}
              >
                {reqFrom && <span className="absolute left-0.5 top-0.5 h-1.5 w-1.5 rounded-full bg-rose-400" />}
                {reqTo && <span className="absolute right-0.5 top-0.5 h-1.5 w-1.5 rounded-full bg-emerald-300" />}
                {piece && <span className={piece.color === "w" ? "text-slate-900" : "text-cyan-50"}>{piece.type.toUpperCase()}</span>}
              </div>
            )
          }),
        )}
      </div>
      <p className="mt-2 text-[11px] text-cyan-50/80">Red dot = required from square, Green dot = required destination.</p>
    </div>
  )
}
