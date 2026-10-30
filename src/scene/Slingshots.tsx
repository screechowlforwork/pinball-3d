import { CuboidCollider, RigidBody } from '@react-three/rapier'
import type { CollisionPayload } from '@react-three/rapier'
import { COLORS, SCORE } from '../game/constants'
import { useGame } from '../game/store'
import { sfx } from '../game/audio'

const KICK = 0.06

function Slingshot({ side }: { side: 'left' | 'right' }) {
  const sign = side === 'left' ? 1 : -1
  // Angled face: slopes from outer-top to inner-bottom ("\" on the left).
  const angle = sign * -0.7
  const x = sign * -0.135
  const z = 0.315

  const onHit = (e: CollisionPayload) => {
    const other = e.other.rigidBody
    if (!other) return
    const p = other.translation()
    const dx = p.x - x
    const dz = p.z - z
    const len = Math.hypot(dx, dz) || 1
    other.applyImpulse(
      { x: (dx / len) * KICK + sign * 0.01, y: 0, z: (dz / len) * KICK + 0.02 },
      true,
    )
    useGame.getState().addScore(SCORE.slingshot, 'SLINGSHOT')
    sfx.sling()
  }

  return (
    <RigidBody type="fixed" colliders={false} position={[x, 0, z]} onCollisionEnter={onHit}>
      <CuboidCollider
        args={[0.055, 0.022, 0.008]}
        position={[0, 0.022, 0]}
        rotation={[0, angle, 0]}
        restitution={0.7}
        friction={0.05}
      />
      <mesh position={[0, 0.011, 0]} rotation={[0, angle, 0]} castShadow>
        <boxGeometry args={[0.11, 0.02, 0.016]} />
        <meshStandardMaterial
          color={COLORS.sling}
          emissive={COLORS.sling}
          emissiveIntensity={0.9}
          roughness={0.3}
        />
      </mesh>
    </RigidBody>
  )
}

export function Slingshots() {
  return (
    <group>
      <Slingshot side="left" />
      <Slingshot side="right" />
    </group>
  )
}
