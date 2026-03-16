import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Textarea } from "@/components/ui/textarea"
import { Label } from "@/components/ui/label"
import { Mail, MapPin, Clock, DollarSign } from "lucide-react"

export function Contact() {
  return (
    <section id="contact" className="py-20 px-4 bg-black">
      <div className="container max-w-4xl">
        <h2 className="text-3xl md:text-4xl font-bold text-center mb-12 text-white">
          <span className="text-gray-400">{"// "}</span>Let's Work Together
        </h2>
        <div className="grid md:grid-cols-2 gap-8">
          <div className="space-y-6">
            <div>
              <h3 className="text-2xl font-semibold mb-4 text-white">Ready to start your project?</h3>
              <p className="text-gray-300 leading-relaxed">
                I'm currently available for freelance projects and remote collaborations. Whether you need a full-stack
                application, API development, or technical consulting, let's discuss how I can help bring your ideas to
                life.
              </p>
            </div>

            <div className="space-y-4">
              <div className="flex items-center gap-3">
                <Mail className="h-5 w-5 text-green-400" />
                <span className="text-gray-300">himalpangeni8849@gmail.com</span>
              </div>
              <div className="flex items-center gap-3">
                <MapPin className="h-5 w-5 text-green-400" />
                <span className="text-gray-300">Remote / Worldwide</span>
              </div>
              <div className="flex items-center gap-3">
                <Clock className="h-5 w-5 text-green-400" />
                <span className="text-gray-300">Available 40hrs/week</span>
              </div>
              <div className="flex items-center gap-3">
                <DollarSign className="h-5 w-5 text-green-400" />
                <span className="text-gray-300">Starting at $75/hour</span>
              </div>
            </div>

            <Card className="bg-gray-900 border-gray-700">
              <CardContent className="p-4">
                <div className="bg-black rounded p-4 font-mono text-sm">
                  <div className="text-gray-400 mb-2">// Quick response guaranteed</div>
                  <div className="text-green-400">
                    <span className="text-cyan-400">if</span> (project.isInteresting) {"{"}
                    <br />
                    <span className="ml-4 text-white">response.time = </span>
                    <span className="text-yellow-400">'within 24hrs'</span>
                    <br />
                    <span className="ml-4 text-white">quality = </span>
                    <span className="text-yellow-400">'exceptional'</span>
                    <br />
                    {"}"}
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>

          <Card className="bg-gray-900 border-gray-700">
            <CardHeader>
              <CardTitle className="text-white">Start Your Project</CardTitle>
              <CardDescription className="text-gray-400">
                Fill out the form below and I'll get back to you within 24 hours with a detailed proposal.
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label htmlFor="firstName" className="text-gray-300">
                    First Name
                  </Label>
                  <Input id="firstName" placeholder="John" className="bg-black border-gray-600 text-white" />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="lastName" className="text-gray-300">
                    Last Name
                  </Label>
                  <Input id="lastName" placeholder="Doe" className="bg-black border-gray-600 text-white" />
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
                  className="bg-black border-gray-600 text-white"
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="budget" className="text-gray-300">
                  Project Budget
                </Label>
                <Input id="budget" placeholder="$5,000 - $10,000" className="bg-black border-gray-600 text-white" />
              </div>
              <div className="space-y-2">
                <Label htmlFor="message" className="text-gray-300">
                  Project Details
                </Label>
                <Textarea
                  id="message"
                  placeholder="Tell me about your project, timeline, and requirements..."
                  className="min-h-[120px] bg-black border-gray-600 text-white"
                />
              </div>
              <Button className="w-full bg-green-600 hover:bg-green-700 text-black font-semibold">
                Send Project Brief
              </Button>
            </CardContent>
          </Card>
        </div>
      </div>
    </section>
  )
}
