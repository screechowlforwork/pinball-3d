import { useMemo, useRef } from 'react'
import * as THREE from 'three'
import { useFrame } from '@react-three/fiber'
import { CapsuleCollider, RigidBody } from '@react-three/rapier'
import type { RapierRigidBody } from '@react-three/rapier'
import { COLORS } from '../game/constants'
import { input } from '../game/input'
import { useGame } from '../game/store'
import { sfx } from '../game/audio'

const LEN = 0.075
const R = 0.0095
const H = 0.024
const SPEED = 14 // rad/s swing speed

interface Props {
  side: 'left' | 'right'
  pivot: [number, number]
}

// Kinematic flipper: rotating toward the target angle gives the ball its impulse.
export function Flipper({ side, pivot }: Props) {
  const sign = side === 'left' ? 1 : -1
  const rest = side === 'left' ? -0.5 : 0.5
  const active = side === 'left' ? 0.75 : -0.75

  const body = useRef<RapierRigidBody>(null)
  const angle = useRef(rest)
  const lastPressed = useRef(false)
  const tilted = useGame((s) => s.tilted)

  const geo = useMemo(() => {
    // Tapered flipper bat: fat at the pivot, rounded tip.
    const s = new THREE.Shape()
    s.absarc(0, 0, R * 1.25, Math.PI / 2, -Math.PI / 2, true)
    s.lineTo(LEN - R, -R * 0.75)
    s.absarc(LEN - R, 0, R * 0.75, -Math.PI / 2, Math.PI / 2, true)
    s.lineTo(0, R * 1.25)
    const g = new THREE.ExtrudeGeometry(s, { depth: H, bevelEnabled: true, bevelThickness: 0.004, bevelSize: 0.003, bevelSegments: 3, curveSegments: 16 })
    g.rotateX(-Math.PI / 2)
    if (side === 'right') g.scale(-1, 1, 1)
    return g
  }, [side])

  useFrame((_, dt) => {
    const pressed = side === 'left' ? input.left : input.right
    const target = pressed && !tilted ? active : rest
    const diff = target - angle.current
    const step = Math.sign(diff) * Math.min(Math.abs(diff), SPEED * dt)
    angle.current += step
    const q = new THREE.Quaternion().setFromAxisAngle(new THREE.Vector3(0, 1, 0), angle.current)
    body.current?.setNextKinematicRotation(q)
    if (pressed && !lastPressed.current) sfx.flipper()
    lastPressed.current = pressed
  })

  return (
    <RigidBody
      ref={body}
      type="kinematicPosition"
      position={[pivot[0], H / 2 + 0.004, pivot[1]]}
      colliders={false}
    >
      <CapsuleCollider
        args={[LEN / 2 - R, R]}
        position={[sign * (LEN / 2), 0, 0]}
        rotation={[0, 0, Math.PI / 2]}
        friction={0.2}
        restitution={0.15}
      />
      <mesh geometry={geo} castShadow position={[0, -H / 2, 0]}>
        <meshStandardMaterial color={COLORS.flipper} roughness={0.25} metalness={0.4} emissive={COLORS.flipper} emissiveIntensity={0.35} />
      </mesh>
    </RigidBody>
  )
}
