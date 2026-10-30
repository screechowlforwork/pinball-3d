import { useEffect } from 'react'
import { Canvas } from '@react-three/fiber'
import { Scene, sceneHandle } from './scene/Scene'
import { HUD } from './ui/HUD'
import { input } from './game/input'
import { useGame } from './game/store'

function useKeyboard() {
  useEffect(() => {
    const down = (e: KeyboardEvent) => {
      if (e.repeat) return
      const s = useGame.getState()
      switch (e.key) {
        case 'ArrowLeft':
        case 'z':
        case 'Z':
          input.left = true
          break
        case 'ArrowRight':
        case '/':
        case 'm':
        case 'M':
          input.right = true
          break
        case ' ':
          e.preventDefault()
          if (s.phase === 'ready') s.setCharging(true)
          else if (s.phase === 'gameover') s.newGame()
          break
        case 'n':
        case 'N':
          sceneHandle.nudge(Math.random() > 0.5 ? 1 : -1)
          break
      }
    }
    const up = (e: KeyboardEvent) => {
      const s = useGame.getState()
      switch (e.key) {
        case 'ArrowLeft':
        case 'z':
        case 'Z':
          input.left = false
          break
        case 'ArrowRight':
        case '/':
        case 'm':
        case 'M':
          input.right = false
          break
        case ' ':
          s.setCharging(false)
          break
      }
    }
    window.addEventListener('keydown', down)
    window.addEventListener('keyup', up)
    return () => {
      window.removeEventListener('keydown', down)
      window.removeEventListener('keyup', up)
    }
  }, [])
}

export default function App() {
  useKeyboard()
  return (
    <div className="relative h-full w-full overflow-hidden bg-surface-dim">
      <Canvas
        shadows
        dpr={[1, 2]}
        camera={{ position: [0, 0.92, 0.68], fov: 42, near: 0.01, far: 10 }}
        gl={{ antialias: true }}
      >
        <color attach="background" args={['#0a0c11']} />
        <Scene />
      </Canvas>
      <HUD />
    </div>
  )
}
