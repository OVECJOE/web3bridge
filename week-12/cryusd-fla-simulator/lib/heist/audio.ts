type ToneSpec = {
  frequency: number
  duration: number
  gain: number
  type: OscillatorType
}

export class HeistAudio {
  private context: AudioContext | null = null

  private ensureContext() {
    if (typeof window === "undefined") return null
    if (!this.context) {
      this.context = new AudioContext()
    }
    if (this.context.state === "suspended") {
      void this.context.resume()
    }
    return this.context
  }

  private tone(spec: ToneSpec, whenOffset = 0) {
    const ctx = this.ensureContext()
    if (!ctx) return

    const now = ctx.currentTime + whenOffset
    const osc = ctx.createOscillator()
    const gain = ctx.createGain()

    osc.type = spec.type
    osc.frequency.setValueAtTime(spec.frequency, now)

    gain.gain.setValueAtTime(0.0001, now)
    gain.gain.exponentialRampToValueAtTime(spec.gain, now + 0.01)
    gain.gain.exponentialRampToValueAtTime(0.0001, now + spec.duration)

    osc.connect(gain)
    gain.connect(ctx.destination)
    osc.start(now)
    osc.stop(now + spec.duration + 0.03)
  }

  action() {
    this.tone({ frequency: 440, duration: 0.09, gain: 0.08, type: "triangle" })
  }

  stageUp() {
    this.tone({ frequency: 390, duration: 0.09, gain: 0.08, type: "triangle" })
    this.tone({ frequency: 520, duration: 0.1, gain: 0.08, type: "triangle" }, 0.08)
    this.tone({ frequency: 650, duration: 0.12, gain: 0.1, type: "sine" }, 0.16)
  }

  complete() {
    this.tone({ frequency: 320, duration: 0.11, gain: 0.08, type: "triangle" })
    this.tone({ frequency: 480, duration: 0.11, gain: 0.09, type: "triangle" }, 0.09)
    this.tone({ frequency: 720, duration: 0.2, gain: 0.12, type: "sine" }, 0.19)
  }
}
