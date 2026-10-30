import { useMemo } from 'react'
import * as THREE from 'three'
import { CuboidCollider, RigidBody } from '@react-three/rapier'
import { COLORS, TABLE } from '../game/constants'

const { halfW, top, bottom, laneX, wallH, wallT } = TABLE

interface WallSpec {
  pos: [number, number, number]
  size: [number, number, number]
  rotY?: number
}

function seg(cx: number, cz: number, len: number, angle: number, t = wallT): WallSpec {
  return {
    pos: [cx, wallH / 2, cz],
    size: [len, wallH, t],
    rotY: angle,
  }
}

// Build every wall collider + matching neon rail visual in one pass.
function buildWalls(): WallSpec[] {
  const walls: WallSpec[] = []
  const arcZ = -0.28

  // Straight outer walls (left, right) running along Z from the top arc to the bottom edge.
  walls.push(seg(-halfW - wallT / 2, (arcZ + bottom) / 2, bottom - arcZ, Math.PI / 2))
  walls.push(seg(halfW + wallT / 2, (arcZ + bottom) / 2, bottom - arcZ, Math.PI / 2))
  // Bottom wall only under the shooter lane.
  walls.push(seg((laneX + halfW) / 2, bottom + wallT / 2, halfW - laneX + wallT * 2, 0))

  // Shooter-lane divider: runs along Z, ends where the top arc begins.
  walls.push(seg(laneX, (arcZ + bottom) / 2, bottom - arcZ, Math.PI / 2))

  // Top arc: semicircle centered at (0, arcZ) joining both side walls.
  const r = halfW + wallT / 2
  const n = 14
  for (let i = 0; i < n; i++) {
    const a0 = (i / n) * Math.PI
    const a1 = ((i + 1) / n) * Math.PI
    const am = (a0 + a1) / 2
    const cx = Math.cos(am) * r
    const cz = arcZ - Math.sin(am) * r
    const len = r * (a1 - a0) * 1.25
    walls.push(seg(cx, cz, len, am + Math.PI / 2))
  }

  // Small rounded cap on top of the lane divider so the ball slides over it.
  walls.push({
    pos: [laneX, wallH / 2, arcZ],
    size: [wallT, wallH, 0.06],
  })

  // Inner guide rails above the slingshots (inlane/outlane separators).
  // The right side is the shooter lane: no outlane guide, and the inlane rail
  // must stop short of the lane divider (face at x = laneX + wallT/2).
  walls.push(seg(-0.195, 0.26, 0.19, -0.5))
  walls.push(seg(0.17, 0.26, 0.09, 0.5))
  walls.push(seg(-0.245, 0.28, 0.14, -0.35))

  // Orbit guides framing the bumper field. Each end keeps >= ~0.035 of gap
  // from the outer wall / lane divider so a ball can never wedge behind them.
  walls.push(seg(-0.16, -0.17, 0.14, 0.6))
  walls.push(seg(0.1, -0.17, 0.14, -0.6))

  return walls
}

function Playfield() {
  const geo = useMemo(() => {
    // Slightly larger slab than the walled area; sits just under the ball's rest height.
    return new THREE.BoxGeometry(halfW * 2 + wallT * 2 + 0.02, 0.02, bottom - top + 0.04)
  }, [])
  return (
    <mesh geometry={geo} position={[0, -0.011, 0]} receiveShadow>
      <meshPhysicalMaterial
        color={COLORS.playfield}
        roughness={0.25}
        metalness={0.15}
        clearcoat={0.9}
        clearcoatRoughness={0.15}
      />
    </mesh>
  )
}

export function Table() {
  const walls = useMemo(() => buildWalls(), [])
  return (
    <group>
      {/* Floor collider */}
      <RigidBody type="fixed" colliders={false} friction={0.15}>
        <CuboidCollider args={[halfW + 0.05, 0.01, (bottom - top) / 2 + 0.05]} position={[0, -0.01, 0]} />
        {walls.map((w, i) => (
          <CuboidCollider
            key={i}
            args={[w.size[0] / 2, w.size[1] / 2, w.size[2] / 2]}
            position={w.pos}
            rotation={[0, w.rotY ?? 0, 0]}
            restitution={0.25}
          />
        ))}
      </RigidBody>

      <Playfield />

      {/* Neon rails on top of the walls */}
      {walls.map((w, i) => (
        <mesh key={i} position={[w.pos[0], wallH + 0.002, w.pos[2]]} rotation={[0, w.rotY ?? 0, 0]}>
          <boxGeometry args={[w.size[0], 0.004, Math.max(w.size[2], 0.006)]} />
          <meshStandardMaterial
            color={COLORS.railEmissive}
            emissive={COLORS.rail}
            emissiveIntensity={2.2}
            toneMapped={false}
          />
        </mesh>
      ))}
      {/* Wall bodies (glass) */}
      {walls.map((w, i) => (
        <mesh key={`g${i}`} position={w.pos} rotation={[0, w.rotY ?? 0, 0]} castShadow>
          <boxGeometry args={w.size} />
          <meshPhysicalMaterial
            color={COLORS.rail}
            transparent
            opacity={0.16}
            roughness={0.05}
            metalness={0}
            transmission={0.6}
            thickness={0.02}
          />
        </mesh>
      ))}
    </group>
  )
}
