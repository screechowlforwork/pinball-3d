import { useRef, useState } from 'react'
import { CuboidCollider, RigidBody } from '@react-three/rapier'
import { COLORS, SCORE } from '../game/constants'
import { useGame } from '../game/store'
import { sfx } from '../game/audio'

const LANES: { x: number; z: number }[] = [
  { x: -0.09, z: -0.33 },
  { x: 0, z: -0.33 },
  { x: 0.09, z: -0.33 },
]

function RolloverLane({ i, x, z }: { i: number; x: number; z: number }) {
  const lit = useGame((s) => s.lanesLit[i])
  const cooldown = useRef(0)

  const onEnter = () => {
    const now = performance.now()
    if (now - cooldown.current < 800) return
    cooldown.current = now
    const s = useGame.getState()
    if (!s.lanesLit[i]) {
      s.addScore(SCORE.rollover, 'LANE')
      s.lightLane(i)
      if (useGame.getState().lanesLit.every(Boolean)) {
        s.setEvent('ALL LANES LIT +1000')
        sfx.score()
      }
    } else {
      s.addScore(50, 'LANE')
    }
    sfx.rollover()
  }

  return (
    <group position={[x, 0, z]}>
      <RigidBody type="fixed" colliders={false} onIntersectionEnter={onEnter}>
        <CuboidCollider args={[0.02, 0.012, 0.012]} position={[0, 0.014, 0]} sensor />
      </RigidBody>
      {/* Light ring on the floor */}
      <mesh position={[0, 0.002, 0]} rotation={[-Math.PI / 2, 0, 0]}>
        <ringGeometry args={[0.012, 0.02, 24]} />
        <meshStandardMaterial
          color={lit ? COLORS.lane : '#3a4157'}
          emissive={lit ? COLORS.lane : '#222840'}
          emissiveIntensity={lit ? 3 : 0.4}
          toneMapped={false}
          side={2}
        />
      </mesh>
      {lit && <pointLight position={[0, 0.05, 0]} intensity={1.2} distance={0.18} color={COLORS.lane} />}
    </group>
  )
}

export function Lanes() {
  return (
    <group>
      {LANES.map((l, i) => (
        <RolloverLane key={i} i={i} {...l} />
      ))}
    </group>
  )
}

function Target({ x, z, rotY }: { x: number; z: number; rotY: number }) {
  const [flash, setFlash] = useState(false)
  const cooldown = useRef(0)

  const onEnter = () => {
    const now = performance.now()
    if (now - cooldown.current < 500) return
    cooldown.current = now
    useGame.getState().addScore(SCORE.target, 'TARGET')
    sfx.target()
    setFlash(true)
    setTimeout(() => setFlash(false), 150)
  }

  return (
    <group position={[x, 0, z]} rotation={[0, rotY, 0]}>
      <RigidBody type="fixed" colliders={false} onIntersectionEnter={onEnter}>
        <CuboidCollider args={[0.008, 0.018, 0.012]} position={[0, 0.018, 0]} sensor />
        <CuboidCollider args={[0.006, 0.018, 0.01]} position={[0, 0.018, 0.012]} restitution={0.4} />
      </RigidBody>
      <mesh position={[0, 0.018, 0]} castShadow>
        <boxGeometry args={[0.016, 0.036, 0.008]} />
        <meshStandardMaterial
          color={COLORS.target}
          emissive={COLORS.target}
          emissiveIntensity={flash ? 5 : 0.9}
          toneMapped={false}
        />
      </mesh>
    </group>
  )
}

export function Targets() {
  return (
    <group>
      <Target x={-0.235} z={0.02} rotY={Math.PI / 2} />
      {/* Right side mirrors the left target's 0.045 offset from the lane divider face. */}
      <Target x={0.178} z={0.02} rotY={Math.PI / 2} />
      <Target x={-0.16} z={-0.24} rotY={0.5} />
      <Target x={0.16} z={-0.24} rotY={-0.5} />
    </group>
  )
}
