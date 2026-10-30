import { useEffect, useRef } from 'react'
import { useFrame } from '@react-three/fiber'
import { RigidBody } from '@react-three/rapier'
import type { RapierRigidBody } from '@react-three/rapier'
import { BALL_START, COLORS, DRAIN_Z, TABLE } from '../game/constants'
import { useGame } from '../game/store'
import { sfx } from '../game/audio'

export function Ball({ bodyRef }: { bodyRef?: React.RefObject<RapierRigidBody | null> }) {
  const inner = useRef<RapierRigidBody>(null)
  const body = bodyRef ?? inner
  const phase = useGame((s) => s.phase)
  const stillTime = useRef(0)

  // Return the ball to the shooter lane whenever a new ball is served.
  useEffect(() => {
    if (phase === 'ready' && body.current) {
      body.current.setTranslation(BALL_START, true)
      body.current.setLinvel({ x: 0, y: 0, z: 0 }, true)
      body.current.setAngvel({ x: 0, y: 0, z: 0 }, true)
    }
  }, [phase])

  useFrame((_, dt) => {
    const b = body.current
    if (!b) return
    const p = b.translation()
    // Failsafe drain: ball fell past the flippers without tripping the sensor.
    if (p.z > DRAIN_Z + 0.08 || p.y < -0.2) {
      if (useGame.getState().phase === 'playing') {
        sfx.drain()
        useGame.getState().drainBall()
      } else {
        // Not in play (e.g. debug teleport): just respawn, don't consume a ball.
        b.setTranslation(BALL_START, true)
        b.setLinvel({ x: 0, y: 0, z: 0 }, true)
        b.setAngvel({ x: 0, y: 0, z: 0 }, true)
      }
      return
    }
    // Stuck detection during play: nudge a motionless ball free.
    if (phase === 'playing') {
      const v = b.linvel()
      const speed = Math.hypot(v.x, v.z)
      stillTime.current = speed < 0.05 ? stillTime.current + dt : 0
      if (stillTime.current > 3) {
        b.applyImpulse({ x: (Math.random() - 0.5) * 0.02, y: 0, z: -0.03 }, true)
        stillTime.current = 0
      }
    }
  })

  return (
    <RigidBody
      ref={body}
      colliders="ball"
      args={[TABLE.ballR]}
      position={BALL_START}
      ccd
      density={7800}
      restitution={0.3}
      friction={0.1}
      linearDamping={0.05}
      angularDamping={0.4}
    >
      <mesh castShadow>
        <sphereGeometry args={[TABLE.ballR, 32, 32]} />
        <meshStandardMaterial color={COLORS.ball} metalness={0.95} roughness={0.12} />
      </mesh>
    </RigidBody>
  )
}
