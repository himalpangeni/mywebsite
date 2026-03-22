import React, { Suspense, useRef, useState, useEffect } from 'react';
import { Canvas, useFrame } from '@react-three/fiber';
import { Environment, MeshDistortMaterial, OrbitControls, Sphere, Stars, Text, useTexture } from '@react-three/drei';
import { motion, AnimatePresence } from 'framer-motion';
import { projects } from './projectsData';
import { ChevronRight } from 'lucide-react';
import './index.css';

function MountainSphere({ activeProj }) {
  const texture = useTexture('mountain.jpg');
  const sphereRef = useRef();

  useFrame((state, delta) => {
    if (sphereRef.current) {
      sphereRef.current.rotation.y += delta * 0.1;
      sphereRef.current.rotation.x += delta * 0.05;
      
      const targetScale = 1.2 + Math.sin(state.clock.elapsedTime * 2) * 0.05;
      sphereRef.current.scale.lerp({x: targetScale, y: targetScale, z: targetScale}, 0.1);
    }
  });

  return (
    <Sphere args={[2, 64, 64]} ref={sphereRef} scale={1.2}>
      <MeshDistortMaterial map={texture} distort={0.4} speed={2} roughness={0.2} metalness={0.8} />
    </Sphere>
  );
}

function FloatingCards({ activeProj }) {
  const groupRef = useRef();
  
  useFrame((state, delta) => {
    if (groupRef.current) {
      groupRef.current.rotation.y = state.clock.elapsedTime * 0.05;
    }
  });

  return (
    <group ref={groupRef}>
      {projects.map((proj, i) => {
        const phi = Math.acos(-1 + (2 * i) / projects.length);
        const theta = Math.sqrt(projects.length * Math.PI) * phi;
        const r = 5.5;
        
        const x = r * Math.cos(theta) * Math.sin(phi);
        const y = r * Math.sin(theta) * Math.sin(phi);
        const z = r * Math.cos(phi);
        
        const isActive = activeProj.id === proj.id;

        return (
          <group position={[x, y, z]} key={proj.id}>
            <Text
              position={[0, 0, 0]}
              fontSize={isActive ? 0.35 : 0.15}
              color={isActive ? "#ff007f" : "white"}
              anchorX="center"
              anchorY="middle"
              outlineWidth={0.01}
              outlineColor="#000"
            >
              {proj.title}
            </Text>
          </group>
        );
      })}
    </group>
  );
}

function App() {
  const [activeProj, setActiveProj] = useState(projects[0]);

  return (
    <>
      <div className="canvas-wrapper">
        <Canvas camera={{ position: [0, 0, 9], fov: 60 }}>
          <ambientLight intensity={0.5} />
          <directionalLight position={[10, 10, 5]} intensity={1} />
          <Stars radius={100} depth={50} count={5000} factor={4} saturation={0} fade speed={1} />
          <Suspense fallback={null}>
            <MountainSphere activeProj={activeProj} />
            <FloatingCards activeProj={activeProj} />
            <Environment preset="city" />
          </Suspense>
          <OrbitControls enableZoom={true} maxDistance={15} minDistance={5} autoRotate autoRotateSpeed={0.5} />
        </Canvas>
      </div>

      <div className="ui-container">
        <header className="interactive">
          <h1>My 3D Portfolio</h1>
          <p className="subtitle">Showcasing the world's best logic, apps, and SaaS concepts.</p>
        </header>

        <main className="interactive slider-container">
          {projects.map((proj) => (
            <motion.div 
              className={`glass-panel project-card ${activeProj.id === proj.id ? 'active' : ''}`}
              key={proj.id}
              onClick={() => setActiveProj(proj)}
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
            >
              <div className="project-tag">{proj.type}</div>
              <h3 style={{ margin: '0' }}>{proj.title}</h3>
              <p style={{ margin: '0', fontSize: '0.9rem', color: '#ccc' }}>{proj.desc}</p>
            </motion.div>
          ))}
        </main>
      </div>
    </>
  );
}

export default App;
