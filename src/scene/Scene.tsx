import { useEffect, useRef } from 'react'
import * as THREE from 'three'
import { useFrame, useThree } from '@react-three/fiber'
import { CuboidCollider, Physics, RigidBody, useRapier } from '@react-three/rapier'
import type { RapierRigidBody } from '@react-three/rapier'
import { DRAIN_Z, GRAVITY } from '../game/constants'
import { useGame } from '../game/store'
import { sfx } from '../game/audio'
import { Table } from './Table'
import { Flipper } from './Flipper'
import { Plunger } from './Plunger'
import { Ball } from './Ball'
import { Bumpers } from './Bumpers'
import { Slingshots } from './Slingshots'
import { Lanes, Targets } from './Lanes'
import { Lighting } from './Lighting'
import { Effects } from './Effects'

const CAM_POS = new THREE.Vector3(0, 1.12, 0.8)
const CAM_TARGET = new THREE.Vector3(0, 0, 0.02)

// Module-level handles so DOM input handlers (outside the canvas) can reach in.
export const sceneHandle = {
  nudge: (_dir: number) => {},
}

function CameraRig({ ballRef }: { ballRef: React.RefObject<RapierRigidBody | null> }) {
  const { camera } = useThree()
  const cur = useRef({ pos: CAM_POS.clone(), tgt: CAM_TARGET.clone() })
  const shake = useRef(0)

  useEffect(() => {
    const prev = sceneHandle.nudge
    sceneHandle.nudge = makeNudge(ballRef, (v) => (shake.current = Math.min(1, shake.current + v)))
    return () => {
      sceneHandle.nudge = prev
    }
  }, [ballRef])

  useFrame((_, dt) => {
    const b = ballRef.current
    const desired = CAM_POS.clone()
    const tgt = CAM_TARGET.clone()
    if (b) {
      const p = b.translation()
      desired.x += p.x * 0.12
      desired.z += THREE.MathUtils.clamp(p.z - 0.1, -0.4, 0.4) * 0.1
      tgt.x += p.x * 0.08
      tgt.z += THREE.MathUtils.clamp(p.z, -0.4, 0.5) * 0.1
    }
    const k = Math.min(1, dt * 4)
    cur.current.pos.lerp(desired, k)
    cur.current.tgt.lerp(tgt, k)
    shake.current = Math.max(0, shake.current - dt * 3)
    const s = shake.current * 0.025
    camera.position.set(
      cur.current.pos.x + (Math.random() - 0.5) * s,
      cur.current.pos.y + (Math.random() - 0.5) * s,
      cur.current.pos.z,
    )
    camera.lookAt(cur.current.tgt)
  })
  return null
}

const nudgeTimes: number[] = []
function makeNudge(ballRef: React.RefObject<RapierRigidBody | null>, shake: (v: number) => void) {
  return (dir: number) => {
    const s = useGame.getState()
    if (s.phase !== 'playing' || s.tilted) return
    const now = performance.now()
    nudgeTimes.push(now)
    while (nudgeTimes.length && now - nudgeTimes[0] > 2000) nudgeTimes.shift()
    ballRef.current?.applyImpulse({ x: dir * 0.02, y: 0, z: -0.008 }, true)
    shake(1)
    if (nudgeTimes.length > 3) {
      nudgeTimes.length = 0
      s.setTilted(true)
      s.setEvent('TILT — flippers locked')
      sfx.tilt()
      setTimeout(() => useGame.getState().setTilted(false), 3000)
    } else {
      s.setEvent('NUDGE')
    }
  }
}

// Debug helper: dumps every collider's pose + shape to window.__colliders.
function ColliderDump() {
  const { world } = useRapier()
  useEffect(() => {
    const list: unknown[] = []
    world.forEachCollider((c) => {
      const p = c.translation()
      const r = c.rotation()
      const q = new THREE.Quaternion(r.x, r.y, r.z, r.w)
      const e = new THREE.Euler().setFromQuaternion(q)
      list.push({
        shape: c.shape.type,
        pos: [+p.x.toFixed(3), +p.y.toFixed(3), +p.z.toFixed(3)],
        rotY: +e.y.toFixed(2),
        he: 'halfExtents' in c.shape
          ? [
              +(c.shape as { halfExtents: { x: number; y: number; z: number } }).halfExtents.x.toFixed(3),
              +(c.shape as { halfExtents: { x: number; y: number; z: number } }).halfExtents.y.toFixed(3),
              +(c.shape as { halfExtents: { x: number; y: number; z: number } }).halfExtents.z.toFixed(3),
            ]
          : undefined,
        sensor: c.isSensor(),
      })
    })
    ;(window as unknown as { __colliders: unknown[]; __world: typeof world }).__colliders = list
    ;(window as unknown as { __world: typeof world }).__world = world
  }, [world])
  return null
}

function DrainSensor() {
  return (
    <RigidBody
      type="fixed"
      colliders={false}
      onIntersectionEnter={() => {
        // Only a ball in play may drain; otherwise drainBall would consume a
        // ball without the phase change that triggers the respawn.
        if (useGame.getState().phase !== 'playing') return
        sfx.drain()
        useGame.getState().drainBall()
      }}
    >
      <CuboidCollider args={[0.4, 0.05, 0.03]} position={[0, 0.02, DRAIN_Z]} sensor />
    </RigidBody>
  )
}

export function Scene() {
  const ballRef = useRef<RapierRigidBody | null>(null)
  const debug = new URLSearchParams(location.search).has('debug')
  useEffect(() => {
    // Debug handle for automated playtesting (?debug only).
    if (debug) (window as unknown as { __ball: typeof ballRef }).__ball = ballRef
  }, [debug])
  return (
    <>
      <Lighting />
      <Physics gravity={GRAVITY} timeStep={1 / 120} debug={debug}>
        <Table />
        <Flipper side="left" pivot={[-0.105, 0.38]} />
        <Flipper side="right" pivot={[0.105, 0.38]} />
        <Slingshots />
        <Bumpers />
        <Lanes />
        <Targets />
        <Plunger ballRef={ballRef} />
        <Ball bodyRef={ballRef} />
        <DrainSensor />
        {debug && <ColliderDump />}
      </Physics>
      <CameraRig ballRef={ballRef} />
      <Effects />
    </>
  )
}
