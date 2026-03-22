"use client"

import { useState, useEffect } from "react"
import { Button } from "@/components/ui/button"
import { ArrowDown, Github, Linkedin, Mail } from "lucide-react"
import Link from "next/link"

export function HeroText() {
  const [currentText, setCurrentText] = useState(0)
  const [isVisible, setIsVisible] = useState(true)

  const texts = ["I AM A PROGRAMMER", "I AM A DEVELOPER", "I AM A DESIGNER", "I AM A CREATOR", "I BUILD THE FUTURE"]

  const skills = [
    "JavaScript • PHP • HTML",
    "React • Node.js • MySQL",
    "3D Design • UI/UX",
    "Full-Stack Development",
    "Creative Solutions",
  ]

  useEffect(() => {
    const interval = setInterval(() => {
      setIsVisible(false)
      setTimeout(() => {
        setCurrentText((prev) => (prev + 1) % texts.length)
        setIsVisible(true)
      }, 300)
    }, 3000)

    return () => clearInterval(interval)
  }, [texts.length])

  return (
    <div className="absolute inset-0 flex items-center justify-center z-10">
      <div className="text-center space-y-8 px-4">
        {/* Animated Main Text */}
        <div className="relative h-32 flex items-center justify-center">
          <h1
            className={`text-4xl md:text-6xl lg:text-8xl font-black tracking-wider transition-all duration-300 ${
              isVisible ? "opacity-100 transform translate-y-0" : "opacity-0 transform translate-y-8"
            }`}
            style={{
              background: "linear-gradient(45deg, #ff6b6b, #4ecdc4, #45b7d1, #96ceb4, #feca57)",
              backgroundSize: "400% 400%",
              WebkitBackgroundClip: "text",
              WebkitTextFillColor: "transparent",
              backgroundClip: "text",
              animation: "gradientShift 3s ease infinite",
            }}
          >
            {texts[currentText]}
          </h1>
        </div>

        {/* Skills Text */}
        <div className="relative h-16 flex items-center justify-center">
          <p
            className={`text-xl md:text-2xl font-bold text-white/90 transition-all duration-300 ${
              isVisible ? "opacity-100 transform translate-y-0" : "opacity-0 transform translate-y-4"
            }`}
          >
            {skills[currentText]}
          </p>
        </div>

        {/* Description */}
        <p className="text-lg md:text-xl text-white/80 max-w-2xl mx-auto leading-relaxed">
          Crafting digital experiences with cutting-edge technology and creative design. Specializing in full-stack
          development and 3D interactive solutions.
        </p>

        {/* Action Buttons */}
        <div className="flex flex-col sm:flex-row gap-4 justify-center items-center mt-12">
          <Button
            size="lg"
            className="bg-gradient-to-r from-purple-600 to-pink-600 hover:from-purple-700 hover:to-pink-700 text-white font-bold px-8 py-4 text-lg"
            asChild
          >
            <Link href="#projects">View My Work</Link>
          </Button>
          <Button
            variant="outline"
            size="lg"
            className="border-2 border-white/30 text-white hover:bg-white/10 backdrop-blur-sm px-8 py-4 text-lg bg-transparent"
            asChild
          >
            <Link href="#contact">Let's Collaborate</Link>
          </Button>
        </div>

        {/* Social Links */}
        <div className="flex justify-center space-x-8 mt-8">
          <Link
            href="https://github.com"
            className="text-white/70 hover:text-white hover:scale-110 transition-all duration-300"
          >
            <Github className="h-8 w-8" />
          </Link>
          <Link
            href="https://linkedin.com"
            className="text-white/70 hover:text-white hover:scale-110 transition-all duration-300"
          >
            <Linkedin className="h-8 w-8" />
          </Link>
          <Link
            href="mailto:dev@example.com"
            className="text-white/70 hover:text-white hover:scale-110 transition-all duration-300"
          >
            <Mail className="h-8 w-8" />
          </Link>
        </div>

        {/* Scroll Indicator */}
        <div className="absolute bottom-8 left-1/2 transform -translate-x-1/2 animate-bounce">
          <ArrowDown className="h-8 w-8 text-white/60" />
        </div>
      </div>
    </div>
  )
}
