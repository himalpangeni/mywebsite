/* ============================================
   CYBER DEV TERMINAL PORTFOLIO - APP.JS
   Himal Pangeni | Flutter Dev / Cyber Sec
   ============================================ */

'use strict';

// ── 1. MATRIX RAIN ─────────────────────────────────────────
(function initMatrix() {
  const canvas = document.getElementById('matrix-canvas');
  if (!canvas) return;
  const ctx = canvas.getContext('2d');
  const chars = 'アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワン01アBCDEFGHIJKLMNOPQRSTUVWXYZ0123456789⌥⌘⇧✦◈▲▶';
  let cols, drops;

  function resize() {
    canvas.width  = window.innerWidth;
    canvas.height = window.innerHeight;
    cols  = Math.floor(canvas.width / 18);
    drops = Array(cols).fill(1);
  }

  resize();
  window.addEventListener('resize', resize);

  function draw() {
    ctx.fillStyle = 'rgba(5,7,10,0.05)';
    ctx.fillRect(0, 0, canvas.width, canvas.height);
    ctx.font = '14px "JetBrains Mono", monospace';

    drops.forEach((y, i) => {
      const char = chars[Math.floor(Math.random() * chars.length)];
      const brightness = Math.random();
      if (brightness > 0.97) {
        ctx.fillStyle = '#FFFFFF';
      } else if (brightness > 0.85) {
        ctx.fillStyle = '#00FF88';
      } else {
        ctx.fillStyle = '#003A1A';
      }
      ctx.fillText(char, i * 18, y * 18);
      if (y * 18 > canvas.height && Math.random() > 0.975) drops[i] = 0;
      drops[i]++;
    });
  }

  setInterval(draw, 55);
})();


// ── 2. BOOT SEQUENCE ────────────────────────────────────────
(function initBoot() {
  const bootScreen = document.getElementById('boot-screen');
  const mainSite   = document.getElementById('main-site');
  const nav        = document.getElementById('cmd-nav');
  const logEl      = document.getElementById('boot-log');
  const bar        = document.getElementById('boot-progress-bar');
  const accessEl   = document.getElementById('boot-access');
  const taskbar    = document.getElementById('os-taskbar');

  const lines = [
    { txt: '[ OK ] Initializing CYBER-OS v2.4.7...',             cls: 'ok',   pct: 10 },
    { txt: '[ OK ] Loading kernel modules...',                   cls: 'ok',   pct: 22 },
    { txt: '[ OK ] Mounting encrypted filesystem...',            cls: 'ok',   pct: 35 },
    { txt: '[ .. ] Scanning neural interface drivers...',        cls: '',     pct: 45 },
    { txt: '[ OK ] JetBrains Neural Engine: ONLINE',             cls: 'ok',   pct: 55 },
    { txt: '[ WARN] Intrusion detection: 3 attempts blocked',    cls: 'warn', pct: 63 },
    { txt: '[ OK ] Firewall: ACTIVE | Encryption: AES-256',      cls: 'ok',   pct: 72 },
    { txt: '[ OK ] Loading developer profile: himal.pangeni',   cls: 'ok',   pct: 82 },
    { txt: '[ OK ] Flutter Engine: ONLINE | Dart VM: LOADED',    cls: 'ok',   pct: 91 },
    { txt: '[ OK ] Cybersec modules: ARMED | VPN: TUNNELED',     cls: 'ok',   pct: 96 },
    { txt: '[ OK ] All systems nominal. ACCESS GRANTED ✔',       cls: 'ok',   pct: 100 },
  ];

  let i = 0;
  function addLine() {
    if (i >= lines.length) {
      setTimeout(() => {
        accessEl.style.display = 'block';
        setTimeout(revealSite, 1400);
      }, 300);
      return;
    }
    const { txt, cls, pct } = lines[i++];
    const span = document.createElement('span');
    span.className = 'log-line ' + cls;
    span.textContent = txt;
    logEl.appendChild(span);
    logEl.scrollTop = logEl.scrollHeight;
    bar.style.width = pct + '%';
    setTimeout(addLine, 240 + Math.random() * 200);
  }
  setTimeout(addLine, 600);

  function revealSite() {
    bootScreen.classList.add('hide');
    mainSite.classList.add('visible');
    nav.classList.add('open');
    taskbar.classList.add('show');
    setTimeout(() => { bootScreen.style.display = 'none'; }, 1000);
    setTimeout(startHeroSequence, 400);
    startGlitchAnomalies();
  }
})();


// ── 3. HERO TERMINAL SEQUENCE ────────────────────────────────
function startHeroSequence() {
  const logEl  = document.getElementById('hero-log');
  const nameEl = document.getElementById('hero-name');
  const roleEl = document.getElementById('hero-role');
  const ctaEl  = document.getElementById('hero-cta');

  const lines = [
    { txt: '$ ssh root@himal-pangeni.dev',                  cls: 'prompt' },
    { txt: '> Establishing secure connection...',            cls: '' },
    { txt: '> Authentication: RSA-4096 ✔',                  cls: 'ok' },
    { txt: '> Loading developer profile...',                 cls: '' },
    { txt: '> Status: ACTIVE | Location: Nepal Node',        cls: 'cyber' },
    { txt: '> Role: Developer + Cyber Researcher',    cls: 'cyber' },
    { txt: '▶ ACCESS GRANTED — Welcome to the system.',      cls: 'ok' },
  ];

  let i = 0;
  function addLine() {
    if (i >= lines.length) {
      setTimeout(() => {
        nameEl.classList.add('show');
        setTimeout(() => { roleEl.classList.add('show'); }, 400);
        setTimeout(() => { ctaEl.classList.add('show'); }, 900);
      }, 300);
      return;
    }
    const { txt, cls } = lines[i++];
    const span = document.createElement('span');
    span.className = cls || '';
    span.textContent = txt;
    logEl.appendChild(span);
    logEl.appendChild(document.createTextNode('\n'));
    setTimeout(addLine, 320 + Math.random() * 180);
  }
  addLine();
}


// ── 4. NAV ────────────────────────────────────────────────────
(function initNav() {
  const toggle = document.getElementById('nav-toggle');
  const nav    = document.getElementById('cmd-nav');
  const items  = nav.querySelectorAll('.nav-item');

  toggle.addEventListener('click', () => {
    nav.classList.toggle('open');
    toggle.textContent = nav.classList.contains('open') ? '[✕] CLOSE' : '[≡] MENU';
  });

  items.forEach(item => {
    item.addEventListener('click', () => {
      const target = item.getAttribute('data-target');
      if (target) {
        document.getElementById(target)?.scrollIntoView({ behavior: 'smooth' });
        items.forEach(i => i.classList.remove('active'));
        item.classList.add('active');
        if (window.innerWidth < 768) nav.classList.remove('open');
      }
    });
  });

  // Highlight active section on scroll
  const sections = ['hero','about','skills','projects','network','contact'];
  window.addEventListener('scroll', () => {
    const scrollY = window.scrollY + window.innerHeight / 2;
    sections.forEach(id => {
      const el = document.getElementById(id);
      if (!el) return;
      const top = el.offsetTop;
      const bot = top + el.offsetHeight;
      const navItem = nav.querySelector(`[data-target="${id}"]`);
      if (navItem) {
        if (scrollY >= top && scrollY <= bot) navItem.classList.add('active');
        else navItem.classList.remove('active');
      }
    });
  }, { passive: true });
})();


// ── 5. SCROLL ANIMATIONS ─────────────────────────────────────
(function initScrollAnimations() {
  // About profile lines
  const profileLines = document.querySelectorAll('.profile-line');
  const statItems    = document.querySelectorAll('.stat-item');
  const skillModules = document.querySelectorAll('.skill-module');
  const logCards     = document.querySelectorAll('.log-card');

  const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (!entry.isIntersecting) return;
      const el = entry.target;

      // Profile lines stagger
      if (el.classList.contains('profile-line')) {
        el.classList.add('visible');
      }

      // Stat bars
      if (el.classList.contains('stat-item')) {
        el.classList.add('visible');
        const fill = el.querySelector('.stat-fill');
        if (fill) {
          const target = fill.getAttribute('data-width');
          setTimeout(() => { fill.style.width = target; }, 200);
        }
      }

      // Skill modules
      if (el.classList.contains('skill-module')) {
        const delay = parseInt(el.getAttribute('data-delay') || '0');
        setTimeout(() => {
          el.classList.add('visible');
          const fill = el.querySelector('.skill-fill');
          if (fill) {
            const pct = fill.getAttribute('data-pct');
            setTimeout(() => { fill.style.width = pct; }, 100);
          }
        }, delay);
      }

      // Log cards
      if (el.classList.contains('log-card')) {
        const delay = parseInt(el.getAttribute('data-delay') || '0');
        setTimeout(() => { el.classList.add('visible'); }, delay);
      }

      observer.unobserve(el);
    });
  }, { threshold: 0.15 });

  [...profileLines, ...statItems, ...skillModules, ...logCards].forEach(el => observer.observe(el));
})();


// ── 6. NETWORK LAB SIMULATION ────────────────────────────────
(function initNetworkLab() {
  const output  = document.getElementById('net-output');
  const netInput = document.getElementById('net-input');

  const sequences = [
    // PING
    { delay: 500, lines: [
      { cls: 'cmd', txt: '$ ping -c 4 github.com' },
      { cls: 'info', txt: 'PING github.com (140.82.121.4) 56(84) bytes of data.' },
      { cls: 'ok', txt: '64 bytes from lb-140-82-121-4.github.com: icmp_seq=1 ttl=53 time=38.2 ms' },
      { cls: 'ok', txt: '64 bytes from lb-140-82-121-4.github.com: icmp_seq=2 ttl=53 time=36.7 ms' },
      { cls: 'ok', txt: '64 bytes from lb-140-82-121-4.github.com: icmp_seq=3 ttl=53 time=37.1 ms' },
      { cls: 'ok', txt: '64 bytes from lb-140-82-121-4.github.com: icmp_seq=4 ttl=53 time=38.9 ms' },
      { cls: 'info', txt: '--- github.com ping statistics ---' },
      { cls: 'ok', txt: '4 packets transmitted, 4 received, 0% packet loss, time 37.7ms avg' },
      { cls: 'empty', txt: '' },
    ]},
    // TRACEROUTE
    { delay: 3400, lines: [
      { cls: 'cmd', txt: '$ traceroute portfolio.himal.dev' },
      { cls: 'info', txt: 'traceroute to portfolio.himal.dev (195.14.22.11), 30 hops max' },
      { cls: 'ok', txt: ' 1  10.0.0.1 (router.local)           1.421 ms   1.311 ms   1.204 ms' },
      { cls: 'ok', txt: ' 2  103.195.250.1 (isp-gateway.np)    8.812 ms   8.991 ms   9.132 ms' },
      { cls: 'ok', txt: ' 3  72.14.203.196 (google-edge.net)  22.441 ms  22.512 ms  22.489 ms' },
      { cls: 'ok', txt: ' 4  195.14.22.11 (portfolio.host)    31.087 ms  30.991 ms  31.212 ms' },
      { cls: 'ok', txt: 'Destination reached in 4 hops. Latency: 31ms' },
      { cls: 'empty', txt: '' },
    ]},
    // PORT SCAN
    { delay: 7200, lines: [
      { cls: 'cmd', txt: '$ nmap -sV --open 195.14.22.11' },
      { cls: 'warn', txt: 'Starting Nmap 7.95 — Advanced port scanner' },
      { cls: 'info', txt: 'Scanning 195.14.22.11 [1000 ports]...' },
      { cls: 'ok', txt: 'PORT     STATE  SERVICE   VERSION' },
      { cls: 'ok', txt: '22/tcp   open   ssh       OpenSSH 8.9 (Ubuntu)' },
      { cls: 'ok', txt: '80/tcp   open   http      Nginx 1.24.0' },
      { cls: 'ok', txt: '443/tcp  open   ssl/https Nginx (TLS 1.3)' },
      { cls: 'info', txt: '997/tcp  closed (filtered by firewall)' },
      { cls: 'ok', txt: '\nNmap done: 1 IP address scanned in 2.38 seconds' },
      { cls: 'empty', txt: '' },
    ]},
    // DNS
    { delay: 11500, lines: [
      { cls: 'cmd', txt: '$ dig +short A flutter.dev' },
      { cls: 'cyan', txt: '142.250.77.196' },
      { cls: 'cyan', txt: '142.250.77.164' },
      { cls: 'empty', txt: '' },
      { cls: 'cmd', txt: '$ whois himal-dev.np (simulated)' },
      { cls: 'info', txt: 'Domain: himal-dev.np' },
      { cls: 'info', txt: 'Registrant: Himal Pangeni' },
      { cls: 'info', txt: 'Country: NP | Status: Active' },
      { cls: 'ok', txt: 'DNSSEC: Enabled | SSL: Valid until 2027-01-01' },
      { cls: 'empty', txt: '' },
    ]},
  ];

  function addNetLine(cls, txt) {
    const span = document.createElement('span');
    span.className = 'net-line ' + cls;
    span.textContent = txt;
    output.appendChild(span);
    output.scrollTop = output.scrollHeight;
  }

  let autoRunning = false;

  function runSequence(seq) {
    let lineDelay = 0;
    seq.lines.forEach(line => {
      lineDelay += 180 + Math.random() * 100;
      setTimeout(() => addNetLine(line.cls, line.txt), lineDelay);
    });
  }

  // Start auto-play when section is visible
  const netSection = document.getElementById('network');
  if (netSection) {
    const obs = new IntersectionObserver((entries) => {
      if (entries[0].isIntersecting && !autoRunning) {
        autoRunning = true;
        sequences.forEach(seq => setTimeout(() => runSequence(seq), seq.delay));
        obs.unobserve(netSection);
      }
    }, { threshold: 0.3 });
    obs.observe(netSection);
  }

  // Manual input
  if (netInput) {
    netInput.addEventListener('keydown', (e) => {
      if (e.key !== 'Enter') return;
      const cmd = netInput.value.trim();
      if (!cmd) return;
      netInput.value = '';
      addNetLine('cmd', '$ ' + cmd);

      const lower = cmd.toLowerCase();
      if (lower.startsWith('ping ')) {
        const host = cmd.slice(5).trim() || 'host.net';
        addNetLine('info', `PING ${host}: 56 bytes of data.`);
        for (let i = 1; i <= 4; i++) {
          const ms = (30 + Math.random() * 20).toFixed(1);
          setTimeout(() => addNetLine('ok', `64 bytes from ${host}: icmp_seq=${i} time=${ms} ms`), i * 300);
        }
        setTimeout(() => addNetLine('ok', 'Ping complete. 0% packet loss.'), 1500);
      } else if (lower.startsWith('nmap') || lower.startsWith('scan')) {
        const host = cmd.split(' ').pop() || 'target';
        addNetLine('warn', `Scanning ${host}...`);
        setTimeout(() => { addNetLine('ok','PORT 22  OPEN  ssh'); addNetLine('ok','PORT 80  OPEN  http'); addNetLine('ok','PORT 443 OPEN  https'); }, 800);
      } else if (lower === 'clear') {
        output.innerHTML = '';
      } else if (lower === 'help') {
        addNetLine('cyan', 'Available: ping <host> | nmap <host> | scan <host> | clear');
      } else {
        addNetLine('err', `Command not found: ${cmd}. Type 'help' for available commands.`);
      }
    });
  }
})();


// ── 7. PROJECT LOG OVERLAY ────────────────────────────────────
(function initProjectLogs() {
  const overlay = document.getElementById('log-overlay');
  const closeBtn = document.getElementById('log-overlay-close');
  const content  = document.getElementById('log-file-content');
  const cards    = document.querySelectorAll('.log-card');

  const projects = [
    {
      id: 'LOG_001',
      title: 'Journal App — LifeLog',
      lines: [
        ['TYPE', 'Production Application'],
        ['STACK', 'Flutter + Firebase + Dart'],
        ['STATUS', '✔ DEPLOYED — Google Play Store'],
        ['PLATFORM', 'Android / iOS'],
        ['IMPACT', '500+ active users | 4.7★ rating'],
        ['FEATURES', 'Encrypted diary, mood tracking, AI insights'],
        ['SEC_AUDIT', 'Passed — AES-256 data encryption'],
        ['REPO', 'github.com/himalpangeni/journal-app'],
      ]
    },
    {
      id: 'LOG_002',
      title: 'Aether AI — Intelligence Module',
      lines: [
        ['TYPE', 'AI Integration Platform'],
        ['STACK', 'Flutter + OpenAI API + Python FastAPI'],
        ['STATUS', '⚡ ACTIVE DEVELOPMENT'],
        ['PLATFORM', 'Cross-platform (Mobile + Web)'],
        ['TARGET', 'Personalized AI assistant for developers'],
        ['MODULES', 'NLP engine, code review bot, chat interface'],
        ['PROGRESS', '▓▓▓▓▓▓▓░░░ 70%'],
        ['ETA', 'Q3 2025'],
      ]
    },
    {
      id: 'LOG_003',
      title: 'Strangify — Stranger Chat',
      lines: [
        ['TYPE', 'Real-time Communication App'],
        ['STACK', 'Flutter + WebRTC + Firebase + Dart'],
        ['STATUS', '✔ DEPLOYED — Production'],
        ['PLATFORM', 'Android + Web (Hybrid)'],
        ['FEATURES', 'Anonymous matching, video/text/voice chat'],
        ['SECURITY', 'E2E encrypted, no data retention'],
        ['INFRA', 'WebRTC P2P + Firebase Signaling'],
        ['USERS', 'Beta: 200+ concurrent users tested'],
      ]
    },
    {
      id: 'LOG_004',
      title: 'Cyber Recon Toolkit',
      lines: [
        ['TYPE', 'Ethical Hacking / Research Tool'],
        ['STACK', 'Python + Scapy + Nmap + Flutter UI'],
        ['STATUS', '🔒 PRIVATE / RESEARCH'],
        ['PURPOSE', 'Network reconnaissance & vulnerability assessment'],
        ['MODULES', 'Port scanner, DNS enum, ARP spoofing (lab only)'],
        ['COMPLIANCE', 'CEH lab environment — educational use'],
        ['DISCLAIMER', 'For authorized testing only'],
        ['SDK', 'Python 3.11 | Kali Linux compatible'],
      ]
    },
    {
      id: 'LOG_005',
      title: 'Retro Fun Crate — Games Hub',
      lines: [
        ['TYPE', 'Multi-game Arcade App'],
        ['STACK', 'Flutter + Flame Engine + AdMob'],
        ['STATUS', '✔ DEPLOYED — Google Play'],
        ['PLATFORM', 'Android'],
        ['GAMES', 'Chess, Ludo, Snake, Solitaire, Paddle Clash + more'],
        ['MONETIZATION', 'AdMob rewarded + banner integration'],
        ['VERSION', '1.1.2+10'],
        ['RATING', '4.5★ | 1000+ downloads'],
      ]
    },
    {
      id: 'LOG_006',
      title: 'Portfolio OS — This Site',
      lines: [
        ['TYPE', 'Interactive Portfolio Website'],
        ['STACK', 'HTML5 + CSS3 + Vanilla JS + GSAP'],
        ['STATUS', '✨ ACTIVE — Live Deployment'],
        ['DESIGN', 'Cyber Terminal / Hacker OS aesthetic'],
        ['FEATURES', 'Matrix rain, draggable windows, interactive terminal'],
        ['HOSTED', 'GitHub Pages — himalpangeni.github.io'],
        ['PERF', 'Lighthouse score: 98/100'],
        ['LICENSE', 'MIT — Open source'],
      ]
    },
  ];

  function openLog(idx) {
    const proj = projects[idx];
    if (!proj) return;
    let html = `<div class="log-file-content">`;
    html += `<span class="c-sep">╔══════════════════════════════════════════════╗</span>\n`;
    html += `<span class="c-green">  [${proj.id}] — ${proj.title}</span>\n`;
    html += `<span class="c-sep">╚══════════════════════════════════════════════╝</span>\n\n`;
    proj.lines.forEach(([key, val]) => {
      html += `<span class="c-key">${key.padEnd(14)}</span><span class="c-sep"> : </span><span class="c-val">${val}</span>\n`;
    });
    html += `\n<span class="c-sep">─────────────────────────────────────────────</span>\n`;
    html += `<span class="c-cyan">&gt; End of log file. Press [ESC] or close to exit.</span>`;
    html += `</div>`;
    content.innerHTML = html;
    overlay.classList.add('show');
  }

  cards.forEach((card, idx) => {
    card.addEventListener('click', () => openLog(idx));
  });

  closeBtn.addEventListener('click', () => overlay.classList.remove('show'));
  overlay.addEventListener('click', (e) => { if (e.target === overlay) overlay.classList.remove('show'); });
  document.addEventListener('keydown', (e) => { if (e.key === 'Escape') overlay.classList.remove('show'); });
})();


// ── 8. INTERACTIVE TERMINAL WINDOW ────────────────────────────
(function initTerminal() {
  const output   = document.getElementById('term-output');
  const termInput = document.getElementById('term-input');
  const history  = [];
  let histIdx    = -1;

  const responses = {
    help: () => [
      { cls: 'info', txt: '╔═══════════════════════════════════════╗' },
      { cls: 'info', txt: '  CYBER-OS HELP SYSTEM v2.4.7' },
      { cls: 'info', txt: '╚═══════════════════════════════════════╝' },
      { cls: 'success', txt: '  whoami         → User profile info' },
      { cls: 'success', txt: '  about          → About Himal Pangeni' },
      { cls: 'success', txt: '  skills         → List skill modules' },
      { cls: 'success', txt: '  projects       → List project logs' },
      { cls: 'success', txt: '  contact        → Contact information' },
      { cls: 'success', txt: '  ls             → List all sections' },
      { cls: 'success', txt: '  cat about.md   → Read about file' },
      { cls: 'success', txt: '  ping <host>    → Ping simulation' },
      { cls: 'success', txt: '  clear          → Clear terminal' },
      { cls: 'success', txt: '  exit           → Close terminal' },
      { cls: 'info',    txt: '' },
    ],
    whoami: () => [
      { cls: 'output-line', txt: 'himal_pangeni@cyber-os:~$' },
      { cls: 'output-line', txt: 'uid=1000(himal) gid=1000(devcore) groups=flutter,cybersec,nepal-devs' },
    ],
    about: () => [
      { cls: 'info', txt: '┌─ USER PROFILE ────────────────────────────┐' },
      { cls: 'output-line', txt: '  Name     : Himal Pangeni' },
      { cls: 'output-line', txt: '  Role     : Flutter Developer' },
      { cls: 'output-line', txt: '  Focus    : Mobile Apps + Cybersecurity' },
      { cls: 'output-line', txt: '  Location : Kathmandu, Nepal' },
      { cls: 'output-line', txt: '  Status   : ACTIVE | Open to opportunities' },
      { cls: 'output-line', txt: '  Github   : github.com/himalpangeni' },
      { cls: 'info', txt: '└───────────────────────────────────────────┘' },
    ],
    skills: () => [
      { cls: 'info', txt: '[ SKILL MATRIX OUTPUT ]' },
      { cls: 'success', txt: '  FLUTTER ENGINE    ██████████ 95%' },
      { cls: 'success', txt: '  DART CORE         █████████░ 90%' },
      { cls: 'success', txt: '  FIREBASE          ████████░░ 80%' },
      { cls: 'success', txt: '  UI/UX ENGINEERING ████████░░ 80%' },
      { cls: 'success', txt: '  NETWORKING        ███████░░░ 70%' },
      { cls: 'success', txt: '  ETHICAL HACKING   ██████░░░░ 60%' },
      { cls: 'success', txt: '  PYTHON            ███████░░░ 70%' },
      { cls: 'info', txt: '' },
    ],
    projects: () => [
      { cls: 'info', txt: '[ PROJECT LOGS — All Deployments ]' },
      { cls: 'output-line', txt: '  LOG_001  Journal App      → DEPLOYED' },
      { cls: 'output-line', txt: '  LOG_002  Aether AI        → IN DEVELOPMENT' },
      { cls: 'output-line', txt: '  LOG_003  Strangify        → DEPLOYED' },
      { cls: 'output-line', txt: '  LOG_004  Cyber Recon Kit  → PRIVATE/RESEARCH' },
      { cls: 'output-line', txt: '  LOG_005  Retro Fun Crate  → DEPLOYED' },
      { cls: 'output-line', txt: '  LOG_006  Portfolio OS     → LIVE' },
      { cls: 'info', txt: '  → Click any project card to view full log' },
    ],
    contact: () => [
      { cls: 'info', txt: '[ CONTACT NODE — Access Channels ]' },
      { cls: 'output-line', txt: '  EMAIL    : himal.pangeni.dev@gmail.com' },
      { cls: 'output-line', txt: '  GITHUB   : github.com/himalpangeni' },
      { cls: 'output-line', txt: '  LINKEDIN : linkedin.com/in/himal-pangeni' },
      { cls: 'output-line', txt: '  LOCATION : Kathmandu, NP (NPT +5:45)' },
      { cls: 'success', txt: '  Status   : ONLINE — Responding within 24h' },
    ],
    ls: () => [
      { cls: 'output-line', txt: 'drwxr-xr-x  hero/       → Landing Terminal' },
      { cls: 'output-line', txt: 'drwxr-xr-x  about/      → System Profile' },
      { cls: 'output-line', txt: 'drwxr-xr-x  skills/     → Skill Matrix' },
      { cls: 'output-line', txt: 'drwxr-xr-x  projects/   → System Logs' },
      { cls: 'output-line', txt: 'drwxr-xr-x  network/    → Network Lab' },
      { cls: 'output-line', txt: 'drwxr-xr-x  contact/    → Access Terminal' },
    ],
  };

  function catFile(args) {
    const file = args[0] || '';
    if (file === 'about.md' || file === 'about') return responses.about();
    if (file === 'skills.md' || file === 'skills') return responses.skills();
    if (file.startsWith('log')) return [{ cls: 'info', txt: 'Use "projects" command or click a project card.' }];
    return [{ cls: 'error-line', txt: `cat: ${file}: No such file or directory` }];
  }

  function pingCmd(args) {
    const host = args[0] || 'localhost';
    const lines = [{ cls: 'output-line', txt: `PING ${host}: 56 bytes` }];
    for (let i = 1; i <= 4; i++) {
      lines.push({ cls: 'success', txt: `  64 bytes from ${host}: seq=${i} time=${(25+Math.random()*20).toFixed(1)} ms` });
    }
    lines.push({ cls: 'success', txt: '  4 packets transmitted, 0% packet loss' });
    return lines;
  }

  function addOutput(lines) {
    lines.forEach(({ cls, txt }) => {
      const span = document.createElement('span');
      span.className = 'term-line ' + cls;
      span.textContent = txt;
      output.appendChild(span);
    });
    output.scrollTop = output.scrollHeight;
  }

  function processCmd(raw) {
    const parts  = raw.trim().split(/\s+/);
    const cmd    = parts[0].toLowerCase();
    const args   = parts.slice(1);

    // Echo the command
    const pLine = document.createElement('span');
    pLine.className = 'term-line prompt-line';
    pLine.textContent = `himal@cyber-os:~$ ${raw}`;
    output.appendChild(pLine);

    if (cmd === 'clear') { output.innerHTML = ''; return; }
    if (cmd === 'exit')  { closeWindow('terminal-window'); return; }
    if (cmd === 'cat')   { addOutput(catFile(args)); return; }
    if (cmd === 'ping')  { addOutput(pingCmd(args)); return; }
    if (responses[cmd])  { addOutput(responses[cmd]()); return; }

    addOutput([{ cls: 'error-line', txt: `bash: ${cmd}: command not found. Type 'help' for available commands.` }]);
  }

  if (termInput) {
    termInput.addEventListener('keydown', (e) => {
      if (e.key === 'Enter') {
        const val = termInput.value.trim();
        if (!val) return;
        history.unshift(val);
        histIdx = -1;
        termInput.value = '';
        processCmd(val);
      }
      if (e.key === 'ArrowUp') {
        histIdx = Math.min(histIdx + 1, history.length - 1);
        termInput.value = history[histIdx] || '';
        e.preventDefault();
      }
      if (e.key === 'ArrowDown') {
        histIdx = Math.max(histIdx - 1, -1);
        termInput.value = histIdx >= 0 ? history[histIdx] : '';
        e.preventDefault();
      }
    });
  }

  // Initial welcome message
  const welcome = [
    { cls: 'info', txt: '╔══════════════════════════════════════════════╗' },
    { cls: 'info', txt: '  CYBER-OS TERMINAL v2.4.7 — Himal Pangeni' },
    { cls: 'info', txt: '  Type "help" to see available commands' },
    { cls: 'info', txt: '╚══════════════════════════════════════════════╝' },
    { cls: 'output-line', txt: '' },
  ];
  addOutput(welcome);
})();


// ── 9. DRAGGABLE WINDOWS ─────────────────────────────────────
function makeDraggable(winEl) {
  const bar = winEl.querySelector('.win-title-bar');
  if (!bar) return;
  let dragging = false, ox = 0, oy = 0;

  bar.addEventListener('mousedown', (e) => {
    dragging = true;
    const rect = winEl.getBoundingClientRect();
    ox = e.clientX - rect.left;
    oy = e.clientY - rect.top;
    winEl.style.transition = 'none';
    winEl.style.zIndex = 4100;
    document.body.style.userSelect = 'none';
  });

  document.addEventListener('mousemove', (e) => {
    if (!dragging) return;
    let x = e.clientX - ox;
    let y = e.clientY - oy;
    x = Math.max(0, Math.min(window.innerWidth - winEl.offsetWidth, x));
    y = Math.max(0, Math.min(window.innerHeight - winEl.offsetHeight, y));
    winEl.style.left = x + 'px';
    winEl.style.top  = y + 'px';
    winEl.style.right = 'auto';
    winEl.style.bottom = 'auto';
  });

  document.addEventListener('mouseup', () => {
    dragging = false;
    document.body.style.userSelect = '';
    winEl.style.zIndex = 4050;
  });
}

// Touch drag
function makeDraggableTouch(winEl) {
  const bar = winEl.querySelector('.win-title-bar');
  if (!bar) return;
  let ox = 0, oy = 0;
  bar.addEventListener('touchstart', (e) => {
    const t = e.touches[0];
    const rect = winEl.getBoundingClientRect();
    ox = t.clientX - rect.left;
    oy = t.clientY - rect.top;
  }, { passive: true });
  bar.addEventListener('touchmove', (e) => {
    const t = e.touches[0];
    let x = t.clientX - ox, y = t.clientY - oy;
    x = Math.max(0, Math.min(window.innerWidth - winEl.offsetWidth, x));
    y = Math.max(0, Math.min(window.innerHeight - winEl.offsetHeight, y));
    winEl.style.left = x + 'px'; winEl.style.top = y + 'px';
    winEl.style.right = 'auto'; winEl.style.bottom = 'auto';
    e.preventDefault();
  }, { passive: false });
}

document.querySelectorAll('.os-window').forEach(w => { makeDraggable(w); makeDraggableTouch(w); });

function openWindow(id) {
  const win = document.getElementById(id);
  if (!win) return;
  const osDesktop = document.getElementById('os-desktop');
  osDesktop.style.display = 'block';
  win.classList.add('open');
  const btn = document.querySelector(`[data-win="${id}"]`);
  if (btn) btn.classList.add('active');
}

function closeWindow(id) {
  const win = document.getElementById(id);
  if (!win) return;
  win.classList.remove('open');
  const btn = document.querySelector(`[data-win="${id}"]`);
  if (btn) btn.classList.remove('active');
  // Hide desktop layer if no windows open
  const anyOpen = document.querySelectorAll('.os-window.open').length > 0;
  if (!anyOpen) document.getElementById('os-desktop').style.display = 'none';
}

// Close buttons
document.querySelectorAll('.win-close').forEach(btn => {
  btn.addEventListener('click', () => {
    const win = btn.closest('.os-window');
    if (win) closeWindow(win.id);
  });
});

// Taskbar buttons
document.querySelectorAll('.taskbar-btn[data-win]').forEach(btn => {
  btn.addEventListener('click', () => {
    const id = btn.getAttribute('data-win');
    const win = document.getElementById(id);
    if (!win) return;
    if (win.classList.contains('open')) closeWindow(id);
    else openWindow(id);
  });
});

// Launch desktop button
const launchBtn = document.getElementById('launch-desktop-btn');
if (launchBtn) {
  launchBtn.addEventListener('click', () => {
    openWindow('terminal-window');
    const termInput = document.getElementById('term-input');
    if (termInput) termInput.focus();
  });
}


// ── 10. TASKBAR CLOCK ───────────────────────────────────────
function updateClock() {
  const clk = document.getElementById('taskbar-clock');
  if (!clk) return;
  const now = new Date();
  const hh = String(now.getHours()).padStart(2,'0');
  const mm = String(now.getMinutes()).padStart(2,'0');
  const ss = String(now.getSeconds()).padStart(2,'0');
  clk.textContent = `${hh}:${mm}:${ss} NPT`;
}
setInterval(updateClock, 1000);
updateClock();


// ── 11. GLITCH ANOMALIES ────────────────────────────────────
function startGlitchAnomalies() {
  const el = document.getElementById('glitch-overlay');
  if (!el) return;

  const messages = [
    '> ANOMALY DETECTED IN SYSTEM CORE...',
    '> WARNING: UNAUTHORIZED ACCESS ATTEMPT',
    '> FIREWALL: 1 THREAT NEUTRALIZED',
    '> SCANNING FOR VULNERABILITIES...',
    '> ENCRYPTION KEY: ROTATING...',
    '> NEURAL NETWORK: RECALIBRATING',
    '> DARK WEB: MONITORING ACTIVE',
    '> INTRUSION DETECTED — BLOCKING...',
    '> VPN TUNNEL: RE-ESTABLISHED',
    '> 0xDEADBEEF: MEMORY FAULT CAUGHT',
  ];

  function trigger() {
    const msg = messages[Math.floor(Math.random() * messages.length)];
    el.textContent = msg;
    el.classList.add('show');
    setTimeout(() => el.classList.remove('show'), 1800);
    setTimeout(trigger, 5000 + Math.random() * 8000);
  }

  setTimeout(trigger, 4000);
}


// ── 12. CONTACT FORM ────────────────────────────────────────
(function initContact() {
  const form   = document.getElementById('contact-form');
  const status = document.getElementById('contact-status');
  if (!form) return;

  form.addEventListener('submit', async (e) => {
    e.preventDefault();
    const name    = document.getElementById('c-name').value.trim();
    const email   = document.getElementById('c-email').value.trim();
    const message = document.getElementById('c-message').value.trim();

    if (!name || !email || !message) {
      status.textContent = '> ERROR: All fields required. Please retry.';
      status.className = 'err';
      return;
    }

    status.textContent = '> Establishing secure channel...';
    status.className = '';

    // Simulate async send
    await new Promise(r => setTimeout(r, 800));
    status.textContent = '> Encrypting payload...';
    await new Promise(r => setTimeout(r, 600));
    status.textContent = '> Transmitting to himal.pangeni.dev@gmail.com...';
    await new Promise(r => setTimeout(r, 900));
    status.textContent = '> MESSAGE EXECUTED SUCCESSFULLY. Himal will respond within 24h. ✔';
    status.className = 'ok';
    form.reset();
  });
})();


// ── 13. GSAP SCROLL STORY (if GSAP loaded) ──────────────────
window.addEventListener('load', () => {
  if (typeof gsap !== 'undefined' && typeof ScrollTrigger !== 'undefined') {
    gsap.registerPlugin(ScrollTrigger);

    // Section unlock animations
    gsap.utils.toArray('.section').forEach(sec => {
      gsap.from(sec, {
        opacity: 0,
        y: 40,
        duration: 0.9,
        ease: 'power3.out',
        scrollTrigger: {
          trigger: sec,
          start: 'top 80%',
          toggleActions: 'play none none none',
        }
      });
    });

    // Section headers glide in
    gsap.utils.toArray('.section-title').forEach(el => {
      gsap.from(el, {
        x: -30,
        opacity: 0,
        duration: 0.7,
        ease: 'power2.out',
        scrollTrigger: { trigger: el, start: 'top 85%' }
      });
    });
  }
});
