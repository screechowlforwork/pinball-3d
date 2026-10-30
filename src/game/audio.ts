// Tiny WebAudio synth — no assets needed. Sounds are short, soft blips.
let ctx: AudioContext | null = null

function ac(): AudioContext | null {
  try {
    ctx ??= new AudioContext()
    if (ctx.state === 'suspended') void ctx.resume()
    return ctx
  } catch {
    return null
  }
}

export function tone(freq: number, dur = 0.08, type: OscillatorType = 'square', vol = 0.06, slide = 0) {
  const c = ac()
  if (!c) return
  const t = c.currentTime
  const o = c.createOscillator()
  const g = c.createGain()
  o.type = type
  o.frequency.setValueAtTime(freq, t)
  if (slide) o.frequency.exponentialRampToValueAtTime(Math.max(20, freq + slide), t + dur)
  g.gain.setValueAtTime(vol, t)
  g.gain.exponentialRampToValueAtTime(0.0001, t + dur)
  o.connect(g).connect(c.destination)
  o.start(t)
  o.stop(t + dur)
}

export const sfx = {
  bumper: () => tone(220 + Math.random() * 60, 0.09, 'square', 0.09, -120),
  sling: () => tone(170, 0.08, 'sawtooth', 0.07, -60),
  rollover: () => tone(880, 0.14, 'sine', 0.06, 220),
  target: () => tone(660, 0.1, 'triangle', 0.07, -100),
  flipper: () => tone(140, 0.05, 'triangle', 0.05, 60),
  launch: () => tone(200, 0.3, 'sawtooth', 0.05, 400),
  drain: () => tone(110, 0.5, 'sine', 0.08, -60),
  tilt: () => tone(70, 0.5, 'square', 0.08),
  score: () => tone(1200, 0.12, 'sine', 0.05, 300),
}
