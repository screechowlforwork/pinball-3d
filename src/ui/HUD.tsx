import { input } from '../game/input'
import { useGame } from '../game/store'
import { sceneHandle } from '../scene/Scene'

function ScoreCard() {
  const score = useGame((s) => s.score)
  const best = useGame((s) => s.best)
  const ballsLeft = useGame((s) => s.ballsLeft)
  return (
    <div className="pointer-events-none absolute left-4 top-4 flex flex-col gap-2">
      <div className="rounded-xl bg-surface-container/80 px-5 py-3 backdrop-blur-md">
        <div className="text-[11px] font-medium uppercase tracking-widest text-on-surface-variant">Score</div>
        <div className="font-mono text-3xl font-bold tabular-nums text-primary">
          {score.toLocaleString()}
        </div>
        {best > 0 && (
          <div className="text-[11px] text-on-surface-variant">Best {best.toLocaleString()}</div>
        )}
      </div>
      <div className="flex gap-1.5 px-1">
        {Array.from({ length: 3 }).map((_, i) => (
          <span
            key={i}
            className={`h-3 w-3 rounded-full transition-colors ${
              i < ballsLeft ? 'bg-primary shadow-[0_0_8px_#7ee0ff]' : 'bg-outline-variant'
            }`}
          />
        ))}
      </div>
    </div>
  )
}

function EventToast() {
  const lastEvent = useGame((s) => s.lastEvent)
  const tilted = useGame((s) => s.tilted)
  if (!lastEvent && !tilted) return null
  return (
    <div className="pointer-events-none absolute left-1/2 top-16 -translate-x-1/2">
      <div
        className={`rounded-xl px-4 py-2 text-sm font-medium backdrop-blur-md ${
          tilted ? 'bg-error-container/80 text-on-error-container' : 'bg-secondary-container/70 text-on-secondary-container'
        }`}
      >
        {tilted ? 'TILT — flippers locked' : lastEvent}
      </div>
    </div>
  )
}

function LaunchHint() {
  const phase = useGame((s) => s.phase)
  const charging = useGame((s) => s.charging)
  const power = useGame((s) => s.launchPower)
  if (phase !== 'ready') return null
  return (
    <div className="pointer-events-none absolute bottom-24 left-1/2 -translate-x-1/2 flex flex-col items-center gap-2">
      <div className="rounded-xl bg-surface-container/80 px-4 py-2 text-sm text-on-surface-variant backdrop-blur-md">
        Hold <span className="font-semibold text-on-surface">SPACE</span> (or pull the button) to launch
      </div>
      <div className="h-2 w-40 overflow-hidden rounded-full bg-surface-container-high">
        <div
          className="h-full rounded-full bg-primary transition-[width] duration-75"
          style={{ width: `${(charging ? power : 0) * 100}%` }}
        />
      </div>
    </div>
  )
}

function GameOver() {
  const phase = useGame((s) => s.phase)
  const score = useGame((s) => s.score)
  const isNewBest = useGame((s) => s.isNewBest)
  const newGame = useGame((s) => s.newGame)
  if (phase !== 'gameover') return null
  return (
    <div className="absolute inset-0 z-10 flex items-center justify-center bg-surface-dim/60 backdrop-blur-sm">
      <div className="flex w-72 flex-col items-center gap-4 rounded-xl bg-surface-container-high p-8 shadow-2xl">
        <div className="text-2xl font-medium text-on-surface">Game Over</div>
        <div className="font-mono text-4xl font-bold text-primary">{score.toLocaleString()}</div>
        {isNewBest && (
          <div className="rounded-md bg-tertiary-container px-3 py-1 text-xs font-medium text-on-tertiary-container">
            New best!
          </div>
        )}
        <button
          onClick={newGame}
          className="mt-2 w-full rounded-xl bg-primary py-3 text-sm font-semibold text-on-primary transition hover:brightness-110 active:scale-95"
        >
          Play again
        </button>
      </div>
    </div>
  )
}

// Invisible touch zones over the bottom half of the screen.
function TouchControls() {
  const setCharging = useGame((s) => s.setCharging)
  const phase = useGame((s) => s.phase)
  return (
    <div className="absolute inset-x-0 bottom-0 top-[45%] z-[5] flex touch-none select-none">
      <div
        className="flex-1"
        onPointerDown={(e) => {
          e.preventDefault()
          input.left = true
        }}
        onPointerUp={() => (input.left = false)}
        onPointerLeave={() => (input.left = false)}
        onPointerCancel={() => (input.left = false)}
      />
      <div
        className="flex-1"
        onPointerDown={(e) => {
          e.preventDefault()
          input.right = true
        }}
        onPointerUp={() => (input.right = false)}
        onPointerLeave={() => (input.right = false)}
        onPointerCancel={() => (input.right = false)}
      />
      {phase === 'ready' && (
        <div className="absolute bottom-8 left-1/2 -translate-x-1/2">
          <button
            className="h-14 w-14 rounded-full bg-primary text-on-primary shadow-[0_0_20px_rgba(126,224,255,0.5)] transition active:scale-90"
            onPointerDown={(e) => {
              e.preventDefault()
              setCharging(true)
            }}
            onPointerUp={() => setCharging(false)}
            onPointerLeave={() => setCharging(false)}
            aria-label="Launch ball"
          >
            <svg viewBox="0 0 24 24" className="mx-auto h-6 w-6" fill="currentColor">
              <path d="M12 3l7 9h-4v9h-6v-9H5l7-9z" />
            </svg>
          </button>
        </div>
      )}
    </div>
  )
}

function NudgeButtons() {
  const phase = useGame((s) => s.phase)
  if (phase !== 'playing') return null
  return (
    <div className="absolute bottom-8 right-4 z-[6] flex gap-2">
      <button
        className="rounded-lg bg-surface-container-high/80 px-3 py-2 text-xs font-medium text-on-surface-variant backdrop-blur-md active:scale-95"
        onPointerDown={() => sceneHandle.nudge(-1)}
      >
        Nudge L
      </button>
      <button
        className="rounded-lg bg-surface-container-high/80 px-3 py-2 text-xs font-medium text-on-surface-variant backdrop-blur-md active:scale-95"
        onPointerDown={() => sceneHandle.nudge(1)}
      >
        Nudge R
      </button>
    </div>
  )
}

export function HUD() {
  return (
    <>
      <ScoreCard />
      <EventToast />
      <LaunchHint />
      <GameOver />
      <TouchControls />
      <NudgeButtons />
      <div className="pointer-events-none absolute right-4 top-4 rounded-lg bg-surface-container/60 px-3 py-2 text-[11px] text-on-surface-variant backdrop-blur-md">
        ← → / Z M : flippers · Space : launch · N : nudge
      </div>
    </>
  )
}
