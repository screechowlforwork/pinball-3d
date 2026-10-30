import { Environment, Lightformer } from '@react-three/drei'

export function Lighting() {
  return (
    <>
      <ambientLight intensity={0.25} />
      <directionalLight
        position={[0.4, 0.9, 0.35]}
        intensity={1.6}
        castShadow
        shadow-mapSize={[2048, 2048]}
        shadow-camera-left={-0.6}
        shadow-camera-right={0.6}
        shadow-camera-top={0.8}
        shadow-camera-bottom={-0.8}
      />
      <pointLight position={[-0.4, 0.4, -0.3]} intensity={0.5} color="#7ee0ff" />
      <pointLight position={[0.4, 0.3, 0.45]} intensity={0.4} color="#d0bcff" />
      {/* Locally rendered env map (no network fetch) for reflections on the ball/glass */}
      <Environment resolution={256}>
        <Lightformer intensity={2} position={[0, 1.5, 0]} rotation={[Math.PI / 2, 0, 0]} scale={[2, 2, 1]} color="#bcd7ff" />
        <Lightformer intensity={1.2} position={[-1.5, 0.6, 0]} rotation={[0, Math.PI / 2, 0]} scale={[3, 1, 1]} color="#7ee0ff" />
        <Lightformer intensity={1.2} position={[1.5, 0.6, 0]} rotation={[0, -Math.PI / 2, 0]} scale={[3, 1, 1]} color="#d0bcff" />
      </Environment>
    </>
  )
}
