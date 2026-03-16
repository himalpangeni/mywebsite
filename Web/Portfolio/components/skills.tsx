import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Code, Database, Globe, Smartphone } from "lucide-react"

export function Skills() {
  const skillCategories = [
    {
      title: "Frontend",
      icon: <Code className="h-6 w-6" />,
      skills: [
        { name: "React/Next.js", level: 95 },
        { name: "TypeScript", level: 90 },
        { name: "Tailwind CSS", level: 85 },
        { name: "Vue.js", level: 80 },
      ],
    },
    {
      title: "Backend",
      icon: <Database className="h-6 w-6" />,
      skills: [
        { name: "Node.js", level: 90 },
        { name: "Python", level: 85 },
        { name: "PostgreSQL", level: 80 },
        { name: "MongoDB", level: 75 },
      ],
    },
    {
      title: "DevOps",
      icon: <Globe className="h-6 w-6" />,
      skills: [
        { name: "AWS", level: 80 },
        { name: "Docker", level: 75 },
        { name: "CI/CD", level: 70 },
        { name: "Vercel", level: 90 },
      ],
    },
    {
      title: "Mobile",
      icon: <Smartphone className="h-6 w-6" />,
      skills: [
        { name: "React Native", level: 80 },
        { name: "Flutter", level: 70 },
        { name: "PWA", level: 85 },
        { name: "Expo", level: 75 },
      ],
    },
  ]

  return (
    <section id="skills" className="py-20 px-4 bg-black">
      <div className="container max-w-6xl">
        <h2 className="text-3xl md:text-4xl font-bold text-center mb-12 text-white">
          <span className="text-gray-400">{"// "}</span>Technical Skills
        </h2>
        <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-6">
          {skillCategories.map((category, index) => (
            <Card key={index} className="bg-gray-900 border-gray-700 hover:border-green-400 transition-colors">
              <CardHeader>
                <CardTitle className="flex items-center gap-2 text-white">
                  <span className="text-green-400">{category.icon}</span>
                  {category.title}
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                {category.skills.map((skill, skillIndex) => (
                  <div key={skillIndex} className="space-y-2">
                    <div className="flex justify-between text-sm">
                      <span className="text-gray-300">{skill.name}</span>
                      <span className="text-green-400">{skill.level}%</span>
                    </div>
                    <div className="w-full bg-gray-700 rounded-full h-2">
                      <div
                        className="bg-gradient-to-r from-green-400 to-cyan-400 h-2 rounded-full transition-all duration-1000"
                        style={{ width: `${skill.level}%` }}
                      ></div>
                    </div>
                  </div>
                ))}
              </CardContent>
            </Card>
          ))}
        </div>
      </div>
    </section>
  )
}
