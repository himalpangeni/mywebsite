# Portfolio Workspace — Himal Pangeni

This repository contains a portfolio site and multiple demo microservices (Ludo, Chat, Resume Analyzer, Multiplayer Snake) along with static portfolio pages. The setup is designed so you can run services locally or deploy them individually.

Contents
- Root static site (index.html, about.html, skills.html, projects/)
- projects/ — static project demos (snake single-player, puzzle, art, ideas)
- services/
  - chat/ — Omegle-style anonymous chat (server + public client)
  - ludo/ — Ludo game service (server + public client)
  - resume/ — Resume Analyzer (server + public client)
  - snake/ — Multiplayer Snake (server + public client)

Requirements
- Node.js (14+ recommended)
- npm
- Optional: Docker & docker-compose

Quick start — run everything locally

This checklist will get all services running locally on your machine. Run each step in a separate terminal tab/window.

1) Serve the static site (optional, for browsing index locally)

  npx http-server -c-1 . -p 8080
  # open http://localhost:8080

2) Start Chat service

  cd services/chat
  npm install
  node server.js
  # open http://localhost:3001/chat/

3) Start Resume Analyzer

  cd services/resume
  npm install
  node server.js
  # open http://localhost:3002/

4) Start Ludo service

  cd services/ludo
  npm install
  node server.js
  # open http://localhost:3003/

5) Start Multiplayer Snake

  cd services/snake
  npm install
  node server.js
  # open http://localhost:3004/

Run multiple services concurrently
- Use separate terminals for each service, or use a process manager like `pm2`.
- For a single-command approach, create a small shell script or use `concurrently` npm package.

Docker (optional)
- If you prefer Docker, I can generate Dockerfiles for each service and a `docker-compose.yml` that runs them together. Tell me if you want this and I will create them.

GitHub Pages (static site)
- The root static pages (index.html, about.html, skills.html, projects/*) are GitHub Pages compatible. To publish:
  1. Create a new GitHub repository.
  2. Push the repository.
  3. In GitHub repo Settings → Pages, choose branch `main` (or `gh-pages`) and root folder `/`.
  4. Wait for the site to publish. Links to services will only work if those services are hosted publicly (GitHub Pages only hosts static files).

Connecting AI APIs (OpenAI example)

1) Get an API key at https://platform.openai.com
2) Export the key in your shell before running the server that will call it:

  export OPENAI_KEY="your_api_key_here"

3) Example server call (Resume Analyzer): see `services/resume/server.js` and add an `/analyze-ai` endpoint using fetch or axios to call the OpenAI API. Do not commit your key.

Example code snippet to call OpenAI from Node:

```js
const fetch = require('node-fetch');
const resp = await fetch('https://api.openai.com/v1/chat/completions', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + process.env.OPENAI_KEY },
  body: JSON.stringify({ model: 'gpt-4o-mini', messages: [{role:'user', content: `Analyze this resume: ${text}`}], max_tokens: 500 })
});
const data = await resp.json();
```

Security and deployment notes
- Do not commit API keys or secrets. Use environment variables or a secrets manager.
- For production, host Node services on platforms like Render, Fly, Heroku, or a VPS. Use Nginx to reverse-proxy and secure with TLS.

Example nginx proxy snippet

```
server {
  listen 80;
  server_name example.com;

  location / {
    root /var/www/your-static-site;
    try_files $uri $uri/ =404;
  }

  location /ludo/ { proxy_pass http://127.0.0.1:3003/; }
  location /chat/ { proxy_pass http://127.0.0.1:3001/; }
  location /snake/ { proxy_pass http://127.0.0.1:3004/; }
  location /resume/ { proxy_pass http://127.0.0.1:3002/; }
}
```

Troubleshooting
- "Port already in use" — change port in server.js or stop other services.
- Socket.io connection errors — ensure the server is running, correct port, and firewall allows traffic.
- Missing modules — run `npm install` in the service folder.

What I will implement next (automatic)
- Finish the Classic Ludo client UI (exact board layout, token selection, safe squares, home stretch, capture visuals).
- Generate Dockerfiles + docker-compose to run all services together.
- Build the Portfolio Builder (client-side generator) and AI demo placeholders.

If you want me to stop or change priorities, tell me which feature to focus on first (Ludo UI, Docker setup, Portfolio Builder, AI demos, or deploy configs).