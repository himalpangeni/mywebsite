import { Card, CardContent } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Terminal, Coffee, Code2, Zap } from "lucide-react"

export function About() {
  return (
    <section id="about" className="py-20 px-4 bg-gray-950">
      <div className="container max-w-4xl">
        <h2 className="text-3xl md:text-4xl font-bold text-center mb-12 text-white">
          <span className="text-gray-400">{"// "}</span>About Me
        </h2>
        <div className="grid md:grid-cols-2 gap-8 items-center">
          <div className="space-y-6">
            <p className="text-lg text-gray-300 leading-relaxed">
             Hey My name is Himal Pangeni-I'm a passionate freelance developer with 5+ years of experience building scalable web applications. I
              specialize in modern JavaScript frameworks and love turning complex problems into elegant solutions.
            </p>
            <p className="text-lg text-gray-300 leading-relaxed">
              Currently available for freelance projects, I work with startups and established companies to bring their
              digital ideas to life. I believe in clean code, user-centered design, and delivering results that exceed
              expectations.
            </p>

            <div className="grid grid-cols-2 gap-4 mt-8">
              <div className="flex items-center space-x-3 text-gray-300">
                <Terminal className="h-5 w-5 text-green-400" />
                <span>5+ Years Experience</span>
              </div>
              <div className="flex items-center space-x-3 text-gray-300">
                <Code2 className="h-5 w-5 text-green-400" />
                <span>50+ Projects Completed</span>
              </div>
              <div className="flex items-center space-x-3 text-gray-300">
                <Zap className="h-5 w-5 text-green-400" />
                <span>Available for Hire</span>
              </div>
              <div className="flex items-center space-x-3 text-gray-300">
                <Coffee className="h-5 w-5 text-green-400" />
                <span>Remote Friendly</span>
              </div>
            </div>

            <div className="flex flex-wrap gap-2 mt-6">
              <Badge variant="secondary" className="bg-gray-800 text-green-400 border-gray-700">
                Freelancer
              </Badge>
              <Badge variant="secondary" className="bg-gray-800 text-green-400 border-gray-700">
                Problem Solver
              </Badge>
              <Badge variant="secondary" className="bg-gray-800 text-green-400 border-gray-700">
                Fast Learner
              </Badge>
              <Badge variant="secondary" className="bg-gray-800 text-green-400 border-gray-700">
                Team Player
              </Badge>
            </div>
          </div>

          <Card className="bg-gray-900 border-gray-700">
            <CardContent className="p-6">
              <div className="bg-black rounded-lg p-6 font-mono text-sm">
                <div className="flex items-center space-x-2 mb-4">
                  <div className="w-3 h-3 bg-red-500 rounded-full"></div>
                  <div className="w-3 h-3 bg-yellow-500 rounded-full"></div>
                  <div className="w-3 h-3 bg-green-500 rounded-full"></div>
                  <span className="text-gray-400 ml-2">developer-stats.js</span>
                </div>
                <div className="space-y-2 text-gray-300">
                  <div>
                    <span className="text-cyan-400">const</span> <span className="text-white">stats</span> = {"{"}
                  </div>
                  <div className="ml-4">
                    <span className="text-green-400">experience</span>:{" "}
                    <span className="text-yellow-400">'5+ years'</span>,
                  </div>
                  <div className="ml-4">
                    <span className="text-green-400">projects</span>: <span className="text-yellow-400">50+</span>,
                  </div>
                  <div className="ml-4">
                    <span className="text-green-400">coffee</span>: <span className="text-yellow-400">'unlimited'</span>
                    ,
                  </div>
                  <div className="ml-4">
                    <span className="text-green-400">status</span>: <span className="text-yellow-400">'available'</span>
                  </div>
                  <div>{"}"}</div>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>
      </div>
    </section>
  )
}
