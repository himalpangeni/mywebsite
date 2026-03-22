import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Code, Database, Palette, Globe } from "lucide-react"

export function Skills() {
  const skillCategories = [
    {
      title: "Frontend",
      icon: <Code className="h-6 w-6" />,
      color: "from-purple-500 to-pink-500",
      skills: [
        { name: "JavaScript", level: 95 },
        { name: "React/Next.js", level: 90 },
        { name: "HTML/CSS", level: 95 },
        { name: "Three.js", level: 85 },
      ],
    },
    {
      title: "Backend",
      icon: <Database className="h-6 w-6" />,
      color: "from-blue-500 to-cyan-500",
      skills: [
        { name: "PHP", level: 90 },
        { name: "Node.js", level: 85 },
        { name: "MySQL", level: 80 },
        { name: "MongoDB", level: 75 },
      ],
    },
    {
      title: "Design",
      icon: <Palette className="h-6 w-6" />,
      color: "from-pink-500 to-rose-500",
      skills: [
        { name: "3D Modeling", level: 90 },
        { name: "UI/UX Design", level: 85 },
        { name: "Blender", level: 80 },
        { name: "Adobe Suite", level: 75 },
      ],
    },
    {
      title: "Tools",
      icon: <Globe className="h-6 w-6" />,
      color: "from-green-500 to-emerald-500",
      skills: [
        { name: "Git/GitHub", level: 90 },
        { name: "Docker", level: 75 },
        { name: "AWS", level: 70 },
        { name: "Figma", level: 85 },
      ],
    },
  ]

  return (
    <section id="skills" className="py-20 px-4 bg-gradient-to-b from-gray-900 to-black">
      <div className="container max-w-6xl">
        <h2 className="text-4xl md:text-5xl font-bold text-center mb-16 bg-gradient-to-r from-purple-400 to-pink-400 bg-clip-text text-transparent">
          Technical Skills
        </h2>

        <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-6">
          {skillCategories.map((category, index) => (
            <Card
              key={index}
              className="bg-gradient-to-br from-gray-800/50 to-gray-900/50 border-gray-700/50 backdrop-blur-sm hover:scale-105 transition-transform duration-300"
            >
              <CardHeader>
                <CardTitle className="flex items-center gap-3 text-white">
                  <div className={`p-2 rounded-lg bg-gradient-to-r ${category.color}`}>{category.icon}</div>
                  {category.title}
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                {category.skills.map((skill, skillIndex) => (
                  <div key={skillIndex} className="space-y-2">
                    <div className="flex justify-between text-sm">
                      <span className="text-gray-300">{skill.name}</span>
                      <span className="text-gray-400">{skill.level}%</span>
                    </div>
                    <div className="w-full bg-gray-700 rounded-full h-2">
                      <div
                        className={`bg-gradient-to-r ${category.color} h-2 rounded-full transition-all duration-1000 ease-out`}
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
