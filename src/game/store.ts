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
  addScore: (n: number, label?: string) => void
  setCharging: (c: boolean) => void
  setLaunchPower: (p: number) => void
  launch: () => void
  drainBall: () => void
  newGame: () => void
  lightLane: (i: number) => void
  setTilted: (t: boolean) => void
  setEvent: (e: string | null) => void
}

const BASE_BALLS = 3

export const useGame = create<GameState>((set, get) => ({
  score: 0,
  best: 0,
  ballsLeft: BASE_BALLS,
  phase: 'ready',
  tilted: false,
  charging: false,
  launchPower: 0,
  lanesLit: [false, false, false],
  lastEvent: null,

  addScore: (n, label) =>
    set((s) => ({ score: s.score + n, lastEvent: label ?? s.lastEvent })),

  setCharging: (charging) => set({ charging, launchPower: charging ? get().launchPower : 0 }),
  setLaunchPower: (launchPower) => set({ launchPower }),

  launch: () => set({ phase: 'playing', charging: false, launchPower: 0 }),

  drainBall: () =>
    set((s) => {
      const left = s.ballsLeft - 1
      if (left > 0) {
        return { ballsLeft: left, phase: 'ready', tilted: false, lanesLit: [false, false, false] }
      }
      return {
        ballsLeft: 0,
        phase: 'gameover',
        tilted: false,
        best: Math.max(s.best, s.score),
      }
    }),

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
  setEvent: (lastEvent) => set({ lastEvent }),
}))
