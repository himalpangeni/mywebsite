import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Textarea } from "@/components/ui/textarea"
import { Label } from "@/components/ui/label"
import { Mail, MapPin, Phone, Send } from "lucide-react"

export function Contact() {
  return (
    <section id="contact" className="py-20 px-4 bg-gradient-to-b from-gray-900 to-black">
      <div className="container max-w-4xl">
        <h2 className="text-4xl md:text-5xl font-bold text-center mb-16 bg-gradient-to-r from-purple-400 to-pink-400 bg-clip-text text-transparent">
          Let's Create Together
        </h2>

        <div className="grid md:grid-cols-2 gap-12">
          <div className="space-y-8">
            <div>
              <h3 className="text-3xl font-semibold mb-6 text-white">Ready to bring your vision to life?</h3>
              <p className="text-lg text-gray-300 leading-relaxed">
                I specialize in creating immersive digital experiences that combine cutting-edge technology with
                stunning visual design. Let's collaborate on your next project and create something extraordinary.
              </p>
            </div>

            <div className="space-y-6">
              <div className="flex items-center gap-4">
                <div className="p-3 rounded-lg bg-gradient-to-r from-purple-500 to-pink-500">
                  <Mail className="h-6 w-6 text-white" />
                </div>
                <div>
                  <div className="text-white font-semibold">Email</div>
                  <div className="text-gray-400">himalpangeni8849@gmail.com</div>
                </div>
              </div>

              <div className="flex items-center gap-4">
                <div className="p-3 rounded-lg bg-gradient-to-r from-blue-500 to-cyan-500">
                  <Phone className="h-6 w-6 text-white" />
                </div>
                <div>
                  <div className="text-white font-semibold">Phone</div>
                  <div className="text-gray-400">Currently Not available</div>
                </div>
              </div>

              <div className="flex items-center gap-4">
                <div className="p-3 rounded-lg bg-gradient-to-r from-green-500 to-emerald-500">
                  <MapPin className="h-6 w-6 text-white" />
                </div>
                <div>
                  <div className="text-white font-semibold">Location</div>
                  <div className="text-gray-400">Available Worldwide For Remote Tasks</div>
                </div>
              </div>
            </div>

            <Card className="bg-gradient-to-br from-gray-800/50 to-gray-900/50 border-gray-700/50 backdrop-blur-sm">
              <CardContent className="p-6">
                <div className="text-center">
                  <div className="text-2xl font-bold text-white mb-2">Let's Build Something Amazing</div>
                  <p className="text-gray-400">
                    From concept to deployment, I'll help you create digital experiences that captivate and engage.
                  </p>
                </div>
              </CardContent>
            </Card>
          </div>

          <Card className="bg-gradient-to-br from-gray-800/50 to-gray-900/50 border-gray-700/50 backdrop-blur-sm">
            <CardHeader>
              <CardTitle className="text-white text-2xl">Start Your Project</CardTitle>
              <CardDescription className="text-gray-400">
                Tell me about your project and let's discuss how we can bring it to life.
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-6">
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label htmlFor="firstName" className="text-gray-300">
                    First Name
                  </Label>
                  <Input
                    id="firstName"
                    placeholder="John"
                    className="bg-black/50 border-gray-600 text-white placeholder:text-gray-500 focus:border-purple-500"
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="lastName" className="text-gray-300">
                    Last Name
                  </Label>
                  <Input
                    id="lastName"
                    placeholder="Doe"
                    className="bg-black/50 border-gray-600 text-white placeholder:text-gray-500 focus:border-purple-500"
                  />
                </div>
              </div>

              <div className="space-y-2">
                <Label htmlFor="email" className="text-gray-300">
                  Email
                </Label>
                <Input
                  id="email"
                  type="email"
                  placeholder="john@company.com"
                  className="bg-black/50 border-gray-600 text-white placeholder:text-gray-500 focus:border-purple-500"
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="project" className="text-gray-300">
                  Project Type
                </Label>
                <Input
                  id="project"
                  placeholder="3D Website, Web App, E-commerce..."
                  className="bg-black/50 border-gray-600 text-white placeholder:text-gray-500 focus:border-purple-500"
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="message" className="text-gray-300">
                  Project Details
                </Label>
                <Textarea
                  id="message"
                  placeholder="Describe your project, goals, and timeline..."
                  className="min-h-[120px] bg-black/50 border-gray-600 text-white placeholder:text-gray-500 focus:border-purple-500"
                />
              </div>

              <Button className="w-full bg-gradient-to-r from-purple-600 to-pink-600 hover:from-purple-700 hover:to-pink-700 text-white font-semibold py-3">
                <Send className="h-4 w-4 mr-2" />
                Send Message
              </Button>
            </CardContent>
          </Card>
        </div>
      </div>
    </section>
  )
}
