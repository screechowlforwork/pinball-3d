import { useRef } from 'react'
import * as THREE from 'three'
import { useFrame } from '@react-three/fiber'
import { RigidBody } from '@react-three/rapier'
import type { RapierRigidBody } from '@react-three/rapier'
import { COLORS, TABLE } from '../game/constants'
import { useGame } from '../game/store'
import { sfx } from '../game/audio'

const REST_Z = 0.495
const PULL_Z = 0.46

// Spring plunger: hold to charge, release to fire the ball up the lane.
// The impulse is applied directly to the ball; the plunger mesh is visual.
export function Plunger({ ballRef }: { ballRef: React.RefObject<RapierRigidBody | null> }) {
  const mesh = useRef<THREE.Group>(null)
  const power = useRef(0)
  const wasCharging = useRef(false)
  const laneRest = useRef(0)

  useFrame((_, dt) => {
    const s = useGame.getState()

    // A weak plunge that can't clear the lane drops back to the plunger.
    // Once the ball settles in the lane, serve it again instead of locking
    // the game in 'playing' with no way to launch.
    const ball = ballRef.current
    if (s.phase === 'playing' && ball) {
      const p = ball.translation()
      const v = ball.linvel()
      const inLane = p.x > TABLE.laneX && p.z > 0.3
      const slow = Math.hypot(v.x, v.z) < 0.08
      laneRest.current = inLane && slow ? laneRest.current + dt : 0
      if (laneRest.current > 0.6) {
        laneRest.current = 0
        s.readyBall()
        s.setEvent('BALL RETURNED — launch again')
      }
    }

    if (s.phase !== 'ready') {
      power.current = 0
      wasCharging.current = false
    } else if (s.charging) {
      power.current = Math.min(1, power.current + dt / 1.1)
      s.setLaunchPower(power.current)
      wasCharging.current = true
    } else if (wasCharging.current) {
      // Release: fire.
      const b = ballRef.current
      if (b) {
        const impulse = 0.02 + 0.2 * power.current
        b.applyImpulse({ x: 0, y: 0, z: -impulse }, true)
        sfx.launch()
      }
      power.current = 0
      wasCharging.current = false
      s.launch()
    }
    if (mesh.current) {
      const z = REST_Z - (REST_Z - PULL_Z) * power.current
      mesh.current.position.z += (z - mesh.current.position.z) * Math.min(1, dt * 20)
    }
  })

  return (
    <group ref={mesh} position={[0.2525, 0.012, REST_Z]}>
      <RigidBody type="fixed" colliders="cuboid">
        <mesh castShadow>
          <boxGeometry args={[0.045, 0.024, 0.018]} />
          <meshStandardMaterial color={COLORS.plunger} emissive={COLORS.plunger} emissiveIntensity={0.6} roughness={0.3} metalness={0.3} />
        </mesh>
      </RigidBody>
      {/* Rod */}
      <mesh position={[0, -0.002, -0.03]}>
        <cylinderGeometry args={[0.004, 0.004, 0.05, 12]} />
        <meshStandardMaterial color="#8b93a8" metalness={0.8} roughness={0.3} />
      </mesh>
    </group>
  )
}
