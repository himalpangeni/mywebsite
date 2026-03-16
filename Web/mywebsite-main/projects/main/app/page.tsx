import { Canvas } from "@react-three/fiber"
import { Suspense } from "react"
import { Scene3D } from "@/components/scene-3d"
import { HeroText } from "@/components/hero-text"
import { Navigation } from "@/components/navigation"
import { About } from "@/components/about"
import { Skills } from "@/components/skills"
import { Projects } from "@/components/projects"
import { Contact } from "@/components/contact"

export default function Portfolio() {
  return (
    <div className="min-h-screen bg-black text-white overflow-x-hidden">
      <Navigation />

      {/* 3D Hero Section */}
      <section className="relative h-screen w-full">
        <Canvas camera={{ position: [0, 0, 5], fov: 75 }} className="absolute inset-0">
          <Suspense fallback={null}>
            <Scene3D />
          </Suspense>
        </Canvas>
        <HeroText />
      </section>

      {/* Other Sections */}
      <About />
      <Skills />
      <Projects />
      <Contact />
    </div>
  )
}
