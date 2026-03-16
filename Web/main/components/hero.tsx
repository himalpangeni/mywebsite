import { Button } from "@/components/ui/button"
import { ArrowDown, Github, Linkedin, Mail } from "lucide-react"
import Link from "next/link"

export function Hero() {
  return (
    <section className="min-h-screen flex items-center justify-center px-4 bg-black relative overflow-hidden">
      {/* Background grid pattern */}
      <div className="absolute inset-0 bg-[linear-gradient(rgba(255,255,255,.02)_1px,transparent_1px),linear-gradient(90deg,rgba(255,255,255,.02)_1px,transparent_1px)] bg-[size:50px_50px]"></div>

      <div className="container max-w-4xl text-center relative z-10">
        <div className="space-y-8">
          <div className="flex justify-center mb-6">
            <div className="bg-gray-900 border border-gray-700 rounded-lg p-4 font-mono text-sm">
              <div className="flex items-center space-x-2 mb-2">
                <div className="w-3 h-3 bg-red-500 rounded-full"></div>
                <div className="w-3 h-3 bg-yellow-500 rounded-full"></div>
                <div className="w-3 h-3 bg-green-500 rounded-full"></div>
              </div>
              <div className="text-green-400">
                <span className="text-gray-500">$</span> whoami
              </div>
            </div>
          </div>

          <h1 className="text-4xl md:text-6xl lg:text-7xl font-bold tracking-tight">
            <span className="text-gray-400">{"const"}</span>{" "}
            <span className="bg-gradient-to-r from-green-400 to-cyan-400 bg-clip-text text-transparent">developer</span>{" "}
            <span className="text-gray-400">{"="}</span> <span className="text-white">{"{"}</span>
          </h1>

          <div className="font-mono text-lg md:text-xl text-gray-300 max-w-2xl mx-auto space-y-2">
            <div className="text-left max-w-lg mx-auto">
              <div className="ml-4">
                <span className="text-cyan-400">name</span>: <span className="text-green-400">'Your Name'</span>,
              </div>
              <div className="ml-4">
                <span className="text-cyan-400">role</span>:{" "}
                <span className="text-green-400">'Freelance Developer'</span>,
              </div>
              <div className="ml-4">
                <span className="text-cyan-400">skills</span>:{" "}
                <span className="text-yellow-400">['React', 'Node.js', 'Python']</span>,
              </div>
              <div className="ml-4">
                <span className="text-cyan-400">available</span>: <span className="text-green-400">true</span>
              </div>
            </div>
            <div className="text-white">{"}"}</div>
          </div>

          <p className="text-xl text-gray-400 max-w-2xl mx-auto">
            Full-Stack Developer specializing in modern web technologies. Available for freelance projects and remote
            collaborations.
          </p>

          <div className="flex flex-col sm:flex-row gap-4 justify-center items-center mt-8">
            <Button size="lg" className="bg-green-600 hover:bg-green-700 text-black font-semibold" asChild>
              <Link href="#projects">View My Work</Link>
            </Button>
            <Button
              variant="outline"
              size="lg"
              className="border-gray-600 text-white hover:bg-gray-800 bg-transparent"
              asChild
            >
              <Link href="#contact">Hire Me</Link>
            </Button>
          </div>

          <div className="flex justify-center space-x-6 mt-8">
            <Link href="https://github.com" className="text-gray-400 hover:text-green-400 transition-colors">
              <Github className="h-6 w-6" />
            </Link>
            <Link href="https://linkedin.com" className="text-gray-400 hover:text-green-400 transition-colors">
              <Linkedin className="h-6 w-6" />
            </Link>
            <Link href="mailto:dev@example.com" className="text-gray-400 hover:text-green-400 transition-colors">
              <Mail className="h-6 w-6" />
            </Link>
          </div>
        </div>

        <div className="absolute bottom-8 left-1/2 transform -translate-x-1/2 animate-bounce">
          <ArrowDown className="h-6 w-6 text-gray-400" />
        </div>
      </div>
    </section>
  )
}
