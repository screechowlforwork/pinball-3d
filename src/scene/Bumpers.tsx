import { useRef, useState } from 'react'
import { CylinderCollider, RigidBody } from '@react-three/rapier'
import type { CollisionPayload } from '@react-three/rapier'
import { COLORS, SCORE } from '../game/constants'
import { useGame } from '../game/store'
import { sfx } from '../game/audio'

const POSITIONS: [number, number][] = [
  [-0.1, -0.1],
  [0.1, -0.1],
  [0, -0.005],
]
const R = 0.033
const KICK = 0.09

function Bumper({ x, z }: { x: number; z: number }) {
  const [flash, setFlash] = useState(0)
  const flashRef = useRef(0)

  const onHit = (e: CollisionPayload) => {
    const other = e.other.rigidBody
    if (!other) return
    const p = other.translation()
    const dx = p.x - x
    const dz = p.z - z
    const len = Math.hypot(dx, dz) || 1
    other.applyImpulse({ x: (dx / len) * KICK, y: 0, z: (dz / len) * KICK }, true)
    useGame.getState().addScore(SCORE.bumper, 'BUMPER')
    sfx.bumper()
    flashRef.current = 1
    setFlash(1)
    setTimeout(() => {
      flashRef.current = 0
      setFlash(0)
    }, 120)
  }

  return (
    <RigidBody
      type="fixed"
      colliders={false}
      position={[x, 0, z]}
      onCollisionEnter={onHit}
    >
      <CylinderCollider args={[0.02, R]} position={[0, 0.02, 0]} restitution={0.6} friction={0.05} />
      {/* Skirt */}
      <mesh position={[0, 0.008, 0]} castShadow>
        <cylinderGeometry args={[R, R + 0.008, 0.016, 32]} />
        <meshStandardMaterial color={COLORS.bumper} roughness={0.35} metalness={0.2} />
      </mesh>
      {/* Cap */}
      <mesh position={[0, 0.03, 0]} castShadow>
        <cylinderGeometry args={[R * 0.62, R * 0.8, 0.02, 32]} />
        <meshStandardMaterial
          color={COLORS.bumperCap}
          emissive={COLORS.bumperCap}
          emissiveIntensity={flash ? 6 : 1.2}
          toneMapped={false}
        />
      </mesh>
      {flash > 0 && (
        <pointLight position={[0, 0.05, 0]} intensity={2.5} distance={0.3} color={COLORS.bumperCap} />
      )}
    </RigidBody>
  )
}

export function Bumpers() {
  return (
    <group>
      {POSITIONS.map(([x, z], i) => (
        <Bumper key={i} x={x} z={z} />
      ))}
    </group>
  )
}
