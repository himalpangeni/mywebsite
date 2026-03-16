import { Card, CardContent } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Code, Palette, Zap, Globe } from "lucide-react"

export function About() {
  return (
    <section id="about" className="py-20 px-4 bg-gradient-to-b from-black to-gray-900">
      <div className="container max-w-4xl">
        <h2 className="text-4xl md:text-5xl font-bold text-center mb-16 bg-gradient-to-r from-purple-400 to-pink-400 bg-clip-text text-transparent">
          About Me
        </h2>

        <div className="grid md:grid-cols-2 gap-12 items-center">
          <div className="space-y-6">
            <p className="text-lg text-gray-300 leading-relaxed">
              I'm a passionate full-stack developer and designer with expertise in creating immersive digital
              experiences. I combine technical proficiency in JavaScript, PHP, and HTML with creative 3D design skills
              to build innovative solutions.
            </p>

            <p className="text-lg text-gray-300 leading-relaxed">
              My approach blends cutting-edge technology with artistic vision, resulting in applications that are not
              only functional but visually stunning. I specialize in creating interactive 3D experiences and modern web
              applications.
            </p>

            <div className="grid grid-cols-2 gap-4 mt-8">
              <div className="flex items-center space-x-3 text-gray-300">
                <Code className="h-6 w-6 text-purple-400" />
                <span>Full-Stack Developer</span>
              </div>
              <div className="flex items-center space-x-3 text-gray-300">
                <Palette className="h-6 w-6 text-pink-400" />
                <span>3D Designer</span>
              </div>
              <div className="flex items-center space-x-3 text-gray-300">
                <Zap className="h-6 w-6 text-yellow-400" />
                <span>Creative Coder</span>
              </div>
              <div className="flex items-center space-x-3 text-gray-300">
                <Globe className="h-6 w-6 text-cyan-400" />
                <span>Web Innovator</span>
              </div>
            </div>

            <div className="flex flex-wrap gap-3 mt-8">
              <Badge className="bg-purple-600/20 text-purple-300 border-purple-500/30">JavaScript</Badge>
              <Badge className="bg-pink-600/20 text-pink-300 border-pink-500/30">PHP</Badge>
              <Badge className="bg-blue-600/20 text-blue-300 border-blue-500/30">HTML/CSS</Badge>
              <Badge className="bg-green-600/20 text-green-300 border-green-500/30">React</Badge>
              <Badge className="bg-yellow-600/20 text-yellow-300 border-yellow-500/30">3D Design</Badge>
            </div>
          </div>

          <Card className="bg-gradient-to-br from-gray-800/50 to-gray-900/50 border-gray-700/50 backdrop-blur-sm">
            <CardContent className="p-8">
              <div className="space-y-6">
                <div className="text-center">
                  <div className="w-32 h-32 mx-auto bg-gradient-to-br from-purple-500 to-pink-500 rounded-full flex items-center justify-center mb-4">
                    <Code className="h-16 w-16 text-white" />
                  </div>
                  <h3 className="text-2xl font-bold text-white mb-2">Creative Developer</h3>
                  <p className="text-gray-400">Bringing ideas to life through code</p>
                </div>

                <div className="grid grid-cols-2 gap-4 text-center">
                  <div>
                    <div className="text-2xl font-bold text-purple-400">50+</div>
                    <div className="text-sm text-gray-400">Projects</div>
                  </div>
                  <div>
                    <div className="text-2xl font-bold text-pink-400">5+</div>
                    <div className="text-sm text-gray-400">Years</div>
                  </div>
                  <div>
                    <div className="text-2xl font-bold text-cyan-400">100%</div>
                    <div className="text-sm text-gray-400">Passion</div>
                  </div>
                  <div>
                    <div className="text-2xl font-bold text-yellow-400">24/7</div>
                    <div className="text-sm text-gray-400">Learning</div>
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>
      </div>
    </section>
  )
}
