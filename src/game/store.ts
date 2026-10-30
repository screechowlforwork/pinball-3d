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
  const armEventClear = (ev: string | null) => {
    if (!ev) return
    setTimeout(() => {
      if (get().lastEvent === ev) set({ lastEvent: null })
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
  isNewBest: false,

  addScore: (n, label) => {
    set((s) => ({ score: s.score + n, lastEvent: label ?? s.lastEvent }))
    armEventClear(label ?? null)
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
    if (get().ballsLeft > 1) armEventClear('BALL LOST')
    set((s) => {
      const left = s.ballsLeft - 1
      if (left > 0) {
        return {
          ballsLeft: left,
          phase: 'ready',
          tilted: false,
          lanesLit: [false, false, false],
          lastEvent: 'BALL LOST',
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
    set({ lastEvent })
    armEventClear(lastEvent)
  },
  }
})
