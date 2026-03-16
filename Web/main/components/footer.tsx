import Link from "next/link"
import { Github, Linkedin, Mail, Twitter, Code } from "lucide-react"

export function Footer() {
  return (
    <footer className="border-t border-gray-800 py-8 px-4 bg-gray-950">
      <div className="container max-w-4xl">
        <div className="flex flex-col md:flex-row justify-between items-center gap-4">
          <div className="flex items-center space-x-2">
            <Code className="h-5 w-5 text-green-400" />
            <span className="text-gray-400 font-mono">© 2024 Built with ❤️ and lots of ☕</span>
          </div>
          <div className="flex space-x-6">
            <Link href="https://github.com" className="text-gray-400 hover:text-green-400 transition-colors">
              <Github className="h-5 w-5" />
            </Link>
            <Link href="https://linkedin.com" className="text-gray-400 hover:text-green-400 transition-colors">
              <Linkedin className="h-5 w-5" />
            </Link>
            <Link href="https://twitter.com" className="text-gray-400 hover:text-green-400 transition-colors">
              <Twitter className="h-5 w-5" />
            </Link>
            <Link href="mailto:dev@example.com" className="text-gray-400 hover:text-green-400 transition-colors">
              <Mail className="h-5 w-5" />
            </Link>
          </div>
        </div>
        <div className="mt-4 text-center">
          <p className="text-gray-500 text-sm font-mono">
            {"// Available for freelance projects • Remote work • Full-stack development"}
          </p>
        </div>
      </div>
    </footer>
  )
}
