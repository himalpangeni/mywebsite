import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { ExternalLink, Github, Star } from "lucide-react"
import Link from "next/link"
import Image from "next/image"

export function Projects() {
  const projects = [
    {
      title: "E-Commerce Platform",
      description:
        "Full-stack e-commerce solution with React, Node.js, and Stripe integration. Features real-time inventory, user authentication, and admin dashboard.",
      image: "/placeholder.svg?height=300&width=400",
      technologies: ["React", "Node.js", "MongoDB", "Stripe"],
      liveUrl: "https://example.com",
      githubUrl: "https://github.com/example/ecommerce",
      featured: true,
    },
    {
      title: "SaaS Analytics Dashboard",
      description:
        "Real-time analytics dashboard for SaaS companies with data visualization, user tracking, and automated reporting features.",
      image: "/placeholder.svg?height=300&width=400",
      technologies: ["Next.js", "TypeScript", "PostgreSQL", "Chart.js"],
      liveUrl: "https://example.com",
      githubUrl: "https://github.com/example/analytics",
      featured: true,
    },
    {
      title: "AI Chat Application",
      description:
        "Modern chat application with AI integration, real-time messaging, and smart conversation features using OpenAI API.",
      image: "/placeholder.svg?height=300&width=400",
      technologies: ["React", "Socket.io", "OpenAI", "Redis"],
      liveUrl: "https://example.com",
      githubUrl: "https://github.com/example/ai-chat",
      featured: false,
    },
    {
      title: "Crypto Trading Bot",
      description:
        "Automated cryptocurrency trading bot with backtesting, risk management, and real-time market analysis capabilities.",
      image: "/placeholder.svg?height=300&width=400",
      technologies: ["Python", "FastAPI", "PostgreSQL", "WebSocket"],
      liveUrl: "https://example.com",
      githubUrl: "https://github.com/example/crypto-bot",
      featured: false,
    },
    {
      title: "Project Management Tool",
      description:
        "Collaborative project management platform with kanban boards, time tracking, and team collaboration features.",
      image: "/placeholder.svg?height=300&width=400",
      technologies: ["Vue.js", "Express", "MongoDB", "Socket.io"],
      liveUrl: "https://example.com",
      githubUrl: "https://github.com/example/project-mgmt",
      featured: false,
    },
    {
      title: "API Gateway Service",
      description:
        "Microservices API gateway with rate limiting, authentication, load balancing, and comprehensive monitoring.",
      image: "/placeholder.svg?height=300&width=400",
      technologies: ["Node.js", "Docker", "Redis", "Nginx"],
      liveUrl: "https://example.com",
      githubUrl: "https://github.com/example/api-gateway",
      featured: false,
    },
  ]

  return (
    <section id="projects" className="py-20 px-4 bg-gray-950">
      <div className="container max-w-6xl">
        <h2 className="text-3xl md:text-4xl font-bold text-center mb-12 text-white">
          <span className="text-gray-400">{"// "}</span>Featured Projects
        </h2>
        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
          {projects.map((project, index) => (
            <Card
              key={index}
              className="group bg-gray-900 border-gray-700 hover:border-green-400 transition-all duration-300 hover:shadow-lg hover:shadow-green-400/10"
            >
              <div className="relative overflow-hidden rounded-t-lg">
                {project.featured && (
                  <div className="absolute top-3 left-3 z-10">
                    <Badge className="bg-green-600 text-black font-semibold">
                      <Star className="h-3 w-3 mr-1" />
                      Featured
                    </Badge>
                  </div>
                )}
                <Image
                  src={project.image || "/placeholder.svg"}
                  alt={project.title}
                  width={400}
                  height={300}
                  className="w-full h-48 object-cover group-hover:scale-105 transition-transform duration-300"
                />
                <div className="absolute inset-0 bg-black/20 group-hover:bg-black/10 transition-colors"></div>
              </div>
              <CardHeader>
                <CardTitle className="text-xl text-white">{project.title}</CardTitle>
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
                      className="text-xs bg-gray-800 text-green-400 border-gray-700"
                    >
                      {tech}
                    </Badge>
                  ))}
                </div>
                <div className="flex gap-2">
                  <Button size="sm" className="bg-green-600 hover:bg-green-700 text-black" asChild>
                    <Link href={project.liveUrl} target="_blank" rel="noopener noreferrer">
                      <ExternalLink className="h-4 w-4 mr-2" />
                      Live Demo
                    </Link>
                  </Button>
                  <Button
                    size="sm"
                    variant="outline"
                    className="border-gray-600 text-gray-300 hover:bg-gray-800 bg-transparent"
                    asChild
                  >
                    <Link href={project.githubUrl} target="_blank" rel="noopener noreferrer">
                      <Github className="h-4 w-4 mr-2" />
                      Code
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
