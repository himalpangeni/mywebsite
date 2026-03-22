import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { ExternalLink, Github, Eye } from "lucide-react"
import Link from "next/link"
import Image from "next/image"

export function Projects() {
  const projects = [
    {
      title: "3D Interactive Portfolio",
      description:
        "A stunning 3D portfolio website built with Three.js and React, featuring interactive animations and immersive user experience.",
      image: "/placeholder.svg?height=300&width=400",
      technologies: ["Three.js", "React", "JavaScript", "GLSL"],
      liveUrl: "https://example.com",
      githubUrl: "https://github.com/example/3d-portfolio",
      featured: true,
    },
    {
      title: "E-Commerce Platform",
      description:
        "Full-stack e-commerce solution with PHP backend, MySQL database, and modern JavaScript frontend with 3D product previews.",
      image: "/placeholder.svg?height=300&width=400",
      technologies: ["PHP", "MySQL", "JavaScript", "HTML/CSS"],
      liveUrl: "https://example.com",
      githubUrl: "https://github.com/example/ecommerce",
      featured: true,
    },
    {
      title: "3D Game Engine",
      description:
        "Custom 3D game engine built from scratch using JavaScript and WebGL, featuring physics simulation and particle systems.",
      image: "/placeholder.svg?height=300&width=400",
      technologies: ["JavaScript", "WebGL", "Canvas", "Physics"],
      liveUrl: "https://example.com",
      githubUrl: "https://github.com/example/game-engine",
      featured: false,
    },
    {
      title: "Real-time Chat App",
      description:
        "Modern chat application with real-time messaging, file sharing, and 3D avatar customization using WebRTC and Socket.io.",
      image: "/placeholder.svg?height=300&width=400",
      technologies: ["Node.js", "Socket.io", "React", "WebRTC"],
      liveUrl: "https://example.com",
      githubUrl: "https://github.com/example/chat-app",
      featured: false,
    },
    {
      title: "AR Product Visualizer",
      description:
        "Augmented reality web application for product visualization using WebXR and Three.js, allowing customers to preview products in their space.",
      image: "/placeholder.svg?height=300&width=400",
      technologies: ["WebXR", "Three.js", "JavaScript", "AR.js"],
      liveUrl: "https://example.com",
      githubUrl: "https://github.com/example/ar-visualizer",
      featured: false,
    },
    {
      title: "CMS with 3D Editor",
      description:
        "Content management system with built-in 3D model editor, allowing users to create and modify 3D content directly in the browser.",
      image: "/placeholder.svg?height=300&width=400",
      technologies: ["PHP", "MySQL", "Three.js", "React"],
      liveUrl: "https://example.com",
      githubUrl: "https://github.com/example/3d-cms",
      featured: false,
    },
  ]

  return (
    <section id="projects" className="py-20 px-4 bg-gradient-to-b from-black to-gray-900">
      <div className="container max-w-6xl">
        <h2 className="text-4xl md:text-5xl font-bold text-center mb-16 bg-gradient-to-r from-purple-400 to-pink-400 bg-clip-text text-transparent">
          Featured Projects
        </h2>

        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-8">
          {projects.map((project, index) => (
            <Card
              key={index}
              className="group bg-gradient-to-br from-gray-800/50 to-gray-900/50 border-gray-700/50 backdrop-blur-sm hover:scale-105 transition-all duration-300 hover:shadow-2xl hover:shadow-purple-500/20"
            >
              <div className="relative overflow-hidden rounded-t-lg">
                {project.featured && (
                  <div className="absolute top-3 left-3 z-10">
                    <Badge className="bg-gradient-to-r from-purple-500 to-pink-500 text-white font-semibold">
                      <Eye className="h-3 w-3 mr-1" />
                      Featured
                    </Badge>
                  </div>
                )}
                <Image
                  src={project.image || "/placeholder.svg"}
                  alt={project.title}
                  width={400}
                  height={300}
                  className="w-full h-48 object-cover group-hover:scale-110 transition-transform duration-300"
                />
                <div className="absolute inset-0 bg-gradient-to-t from-black/60 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-300"></div>
              </div>

              <CardHeader>
                <CardTitle className="text-xl text-white group-hover:text-purple-300 transition-colors">
                  {project.title}
                </CardTitle>
                <CardDescription className="text-sm leading-relaxed text-gray-400">
                  {project.description}
                </CardDescription>
              </CardHeader>

              <CardContent className="space-y-4">
                <div className="flex flex-wrap gap-2">
                  {project.technologies.map((tech, techIndex) => (
                    <Badge
                      key={techIndex}
                      variant="secondary"
                      className="text-xs bg-gray-700/50 text-gray-300 border-gray-600/50"
                    >
                      {tech}
                    </Badge>
                  ))}
                </div>

                <div className="flex gap-2">
                  <Button
                    size="sm"
                    className="bg-gradient-to-r from-purple-600 to-pink-600 hover:from-purple-700 hover:to-pink-700 text-white flex-1"
                    asChild
                  >
                    <Link href={project.liveUrl} target="_blank" rel="noopener noreferrer">
                      <ExternalLink className="h-4 w-4 mr-2" />
                      Live Demo
                    </Link>
                  </Button>
                  <Button
                    size="sm"
                    variant="outline"
                    className="border-gray-600 text-gray-300 hover:bg-gray-700/50 bg-transparent"
                    asChild
                  >
                    <Link href={project.githubUrl} target="_blank" rel="noopener noreferrer">
                      <Github className="h-4 w-4" />
                    </Link>
                  </Button>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      </div>
    </section>
  )
}
