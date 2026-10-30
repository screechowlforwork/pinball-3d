import { create } from 'zustand'

export type Phase = 'ready' | 'playing' | 'gameover'

interface GameState {
  score: number
  best: number
  ballsLeft: number
  phase: Phase
  tilted: boolean
  charging: boolean
  launchPower: number
  lanesLit: boolean[]
  lastEvent: string | null
  eventSeq: number
  isNewBest: boolean
  addScore: (n: number, label?: string) => void
  setCharging: (c: boolean) => void
  setLaunchPower: (p: number) => void
  launch: () => void
  readyBall: () => void
  drainBall: () => void
  newGame: () => void
  lightLane: (i: number) => void
  setTilted: (t: boolean) => void
  setEvent: (e: string | null) => void
}

const BASE_BALLS = 3
const EVENT_MS = 2200

export const useGame = create<GameState>((set, get) => {
  // Clear an event after a short display unless a newer event replaced it.
  // Compared by sequence number, not label — repeated same-label events
  // (e.g. two bumper hits in a row) must not be cut short by an older timer.
  const armEventClear = (seq: number) => {
    setTimeout(() => {
      if (get().eventSeq === seq) set({ lastEvent: null })
    }, EVENT_MS)
  }
  return {
  score: 0,
  best: 0,
  ballsLeft: BASE_BALLS,
  phase: 'ready',
  tilted: false,
  charging: false,
  launchPower: 0,
  lanesLit: [false, false, false],
  lastEvent: null,
  eventSeq: 0,
  isNewBest: false,

  addScore: (n, label) => {
    set((s) => ({
      score: s.score + n,
      lastEvent: label ?? s.lastEvent,
      eventSeq: label ? s.eventSeq + 1 : s.eventSeq,
    }))
    if (label) armEventClear(get().eventSeq)
  },

  setCharging: (charging) => set({ charging, launchPower: charging ? get().launchPower : 0 }),
  setLaunchPower: (launchPower) => set({ launchPower }),

  launch: () => set({ phase: 'playing', charging: false, launchPower: 0 }),

  // Ball settled back in the shooter lane without leaving it (or returned over
  // the divider): serve it again instead of consuming a ball.
  readyBall: () =>
    set((s) =>
      s.phase === 'playing' ? { phase: 'ready', tilted: false } : {},
    ),

  drainBall: () => {
    set((s) => {
      const left = s.ballsLeft - 1
      if (left > 0) {
        return {
          ballsLeft: left,
          phase: 'ready',
          tilted: false,
          lanesLit: [false, false, false],
          lastEvent: 'BALL LOST',
          eventSeq: s.eventSeq + 1,
        }
      }
      return {
        ballsLeft: 0,
        phase: 'gameover',
        tilted: false,
        isNewBest: s.score > s.best,
        best: Math.max(s.best, s.score),
      }
    })
    if (get().phase === 'ready' && get().lastEvent === 'BALL LOST') {
      armEventClear(get().eventSeq)
    }
  },

  newGame: () =>
    set((s) => ({
      score: 0,
      ballsLeft: BASE_BALLS,
      phase: 'ready',
      tilted: false,
      charging: false,
      launchPower: 0,
      lanesLit: [false, false, false],
      best: s.best,
      lastEvent: null,
      isNewBest: false,
    })),

  lightLane: (i) =>
    set((s) => {
      if (s.lanesLit[i]) return {}
      const lanesLit = s.lanesLit.slice()
      lanesLit[i] = true
      const all = lanesLit.every(Boolean)
      return { lanesLit, score: s.score + (all ? 1000 : 0) }
    }),

  setTilted: (tilted) => set({ tilted }),
  setEvent: (lastEvent) => {
    set((s) => ({ lastEvent, eventSeq: lastEvent ? s.eventSeq + 1 : s.eventSeq }))
    if (lastEvent) armEventClear(get().eventSeq)
  },
  }
})
