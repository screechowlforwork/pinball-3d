import * as THREE from 'three'

// All units are meters, approximating a real pinball playfield (~0.56 m x ~1.05 m).
export const TABLE = {
  halfW: 0.28, // inner half width (x: -0.28 .. 0.28)
  top: -0.52,
  bottom: 0.52,
  laneX: 0.2225, // shooter-lane divider wall x
  wallH: 0.05,
  wallT: 0.02,
  ballR: 0.0135,
}

export const BALL_START = new THREE.Vector3(0.2525, TABLE.ballR + 0.001, 0.42)
export const DRAIN_Z = 0.55

// Table tilt expressed through the gravity vector (ball stays in the XZ plane).
export const GRAVITY: [number, number, number] = [0, -9.81, 1.05]

export const COLORS = {
  playfield: '#141828',
  rail: '#7ee0ff',
  railEmissive: '#3fd4ff',
  flipper: '#d0bcff',
  bumper: '#ffb7d5',
  bumperCap: '#ff5ea8',
  sling: '#8ff5d2',
  ball: '#e8ecf4',
  target: '#ffd479',
  lane: '#9ccfff',
  plunger: '#d0bcff',
} as const

export const SCORE = {
  bumper: 100,
  slingshot: 50,
  rollover: 250,
  target: 150,
  laneAllLit: 1000,
} as const
