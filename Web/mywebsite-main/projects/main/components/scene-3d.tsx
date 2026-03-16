"use client"

import { useRef, useMemo } from "react"
import { useFrame } from "@react-three/fiber"
import { Points, PointMaterial, Environment, Float, Sphere, Box, Torus } from "@react-three/drei"
import type * as THREE from "three"
import { useEffect, useState } from "react"

function AnimatedBackground() {
  const ref = useRef<THREE.Points>(null!)
  const [colorIndex, setColorIndex] = useState(0)

  const colors = ["#ff6b6b", "#4ecdc4", "#45b7d1", "#96ceb4", "#feca57", "#ff9ff3", "#54a0ff"]

  const particles = useMemo(() => {
    const temp = new Float32Array(5000 * 3)
    for (let i = 0; i < 5000; i++) {
      temp.set([(Math.random() - 0.5) * 100, (Math.random() - 0.5) * 100, (Math.random() - 0.5) * 100], i * 3)
    }
    return temp
  }, [])

  useFrame((state) => {
    if (ref.current) {
      ref.current.rotation.x = state.clock.elapsedTime * 0.1
      ref.current.rotation.y = state.clock.elapsedTime * 0.15
    }
  })

  useEffect(() => {
    const interval = setInterval(() => {
      setColorIndex((prev) => (prev + 1) % colors.length)
    }, 2000)
    return () => clearInterval(interval)
  }, [colors.length])

  return (
    <Points ref={ref} positions={particles} stride={3} frustumCulled={false}>
      <PointMaterial transparent color={colors[colorIndex]} size={0.5} sizeAttenuation={true} depthWrite={false} />
    </Points>
  )
}

function FloatingShapes() {
  return (
    <>
      <Float speed={1.5} rotationIntensity={1} floatIntensity={2}>
        <Box position={[-4, 2, -2]} args={[1, 1, 1]}>
          <meshStandardMaterial color="#ff6b6b" wireframe />
        </Box>
      </Float>

      <Float speed={2} rotationIntensity={2} floatIntensity={1}>
        <Sphere position={[4, -2, -3]} args={[0.8]}>
          <meshStandardMaterial color="#4ecdc4" wireframe />
        </Sphere>
      </Float>

      <Float speed={1.8} rotationIntensity={1.5} floatIntensity={1.5}>
        <Torus position={[0, 3, -4]} args={[1, 0.3, 16, 32]}>
          <meshStandardMaterial color="#45b7d1" wireframe />
        </Torus>
      </Float>

      <Float speed={1.2} rotationIntensity={0.8} floatIntensity={2.5}>
        <Box position={[-3, -3, -1]} args={[0.5, 2, 0.5]}>
          <meshStandardMaterial color="#feca57" wireframe />
        </Box>
      </Float>
    </>
  )
}

export function Scene3D() {
  return (
    <>
      <ambientLight intensity={0.5} />
      <pointLight position={[10, 10, 10]} />
      <Environment preset="night" />
      <AnimatedBackground />
      <FloatingShapes />
    </>
  )
}
