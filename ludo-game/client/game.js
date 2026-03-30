const canvas = document.getElementById('board');
const ctx = canvas.getContext('2d');
const TS = canvas.width / 15; // Tile size = 40

const rollBtn = document.getElementById('roll');
const diceEl = document.getElementById('dice');
const turnIndicator = document.getElementById('turn-indicator');
const playersList = document.getElementById('players');

// Data structures
const PATH = [
  [1, 6], [2, 6], [3, 6], [4, 6], [5, 6],
  [6, 5], [6, 4], [6, 3], [6, 2], [6, 1], [6, 0],
  [7, 0], [8, 0],
  [8, 1], [8, 2], [8, 3], [8, 4], [8, 5],
  [9, 6], [10, 6], [11, 6], [12, 6], [13, 6], [14, 6],
  [14, 7], [14, 8],
  [13, 8], [12, 8], [11, 8], [10, 8], [9, 8],
  [8, 9], [8, 10], [8, 11], [8, 12], [8, 13], [8, 14],
  [7, 14], [6, 14],
  [6, 13], [6, 12], [6, 11], [6, 10], [6, 9],
  [5, 8], [4, 8], [3, 8], [2, 8], [1, 8], [0, 8],
  [0, 7], [0, 6]
];
const HOME_PATHS = [
  [[1, 7], [2, 7], [3, 7], [4, 7], [5, 7]], // Red
  [[7, 1], [7, 2], [7, 3], [7, 4], [7, 5]], // Green
  [[13, 7], [12, 7], [11, 7], [10, 7], [9, 7]], // Yellow
  [[7, 13], [7, 12], [7, 11], [7, 10], [7, 9]]  // Blue
];
const START_OFFSETS = [0, 13, 26, 39];
const SAFE_SPOTS = [0, 8, 13, 21, 26, 34, 39, 47];
const COLORS = ['#ef4444', '#22c55e', '#eab308', '#3b82f6']; // Tailwind Red, Green, Yellow, Blue
const BASE_COLORS = ['#fee2e2', '#dcfce7', '#fef9c3', '#dbeafe'];
const NAMES = ['Red', 'Green', 'Yellow', 'Blue'];
const DICE_FACES = ['⚀', '⚁', '⚂', '⚃', '⚄', '⚅'];

let players = [];
let tokens = []; // { id, player: 0-3, status: 'home'|'active'|'finished', step: -1..56 }
let currentPlayer = 0;
let currentDice = 0; // 1-6
let state = 'WAITING_ROLL'; // WAITING_ROLL, WAITING_MOVE, ANIMATING, GAME_OVER
let hasRolledSix = false;
let moveCandidates = [];
let consecutiveSixes = 0;

// Base spots mapping (4 per player)
const BASE_SPOTS = [
  [[2, 2], [3, 2], [2, 3], [3, 3]], // Red bases
  [[11, 2], [12, 2], [11, 3], [12, 3]], // Green bases
  [[11, 11], [12, 11], [11, 12], [12, 12]], // Yellow bases
  [[2, 11], [3, 11], [2, 12], [3, 12]] // Blue bases
];

function startGame(numHumans) {
  document.getElementById('startup-screen').style.display = 'none';
  document.getElementById('game-screen').style.display = 'block';

  players = [
    { id: 0, isBot: numHumans < 1 },
    { id: 1, isBot: numHumans < 2 },
    { id: 2, isBot: numHumans < 3 },
    { id: 3, isBot: numHumans < 4 },
  ];

  // Distribute humans properly if less than 4, usually 1st goes P1, 2nd goes P3 (Yellow) for opposite sides, but sequential is fine.

  tokens = [];
  for (let p = 0; p < 4; p++) {
    for (let t = 0; t < 4; t++) {
      tokens.push({ id: `t_${p}_${t}`, player: p, tokenIdx: t, status: 'home', step: -1 });
    }
  }

  currentPlayer = 0;
  consecutiveSixes = 0;
  updateUI();
  drawBoard();
  announceTurn(`${NAMES[currentPlayer]}'S TURN`, COLORS[currentPlayer]);
  
  if (players[currentPlayer].isBot) {
    setTimeout(playBot, 1500);
  }
}

function announceTurn(text, color) {
  const ann = document.getElementById('turn-announcer');
  ann.innerText = text;
  ann.style.color = color;
  ann.classList.add('show');
  setTimeout(() => { ann.classList.remove('show'); }, 1200);
}

function updateUI() {
  const p = players[currentPlayer];
  turnIndicator.innerText = `${NAMES[p.id]}'s Turn ${p.isBot ? '(BOT)' : ''}`;
  turnIndicator.style.color = COLORS[p.id];

  playersList.innerHTML = '';
  players.forEach(pl => {
    let div = document.createElement('div');
    div.className = 'player-item' + (pl.id === currentPlayer ? ' active' : '');
    div.style.borderLeftColor = COLORS[pl.id];
    div.innerHTML = `<span>${NAMES[pl.id]} ${pl.isBot ? '🤖' : '👤'}</span> ` +
      `<span>${tokens.filter(t=>t.player===pl.id && t.status==='finished').length}/4</span>`;
    playersList.appendChild(div);
  });

  if (state === 'WAITING_ROLL' && !p.isBot) {
    rollBtn.disabled = false;
  } else {
    rollBtn.disabled = true;
  }
}

// Draw the board completely natively
function drawBoard() {
  ctx.clearRect(0, 0, canvas.width, canvas.height);

  // Background
  ctx.fillStyle = '#ffffff';
  ctx.fillRect(0, 0, canvas.width, canvas.height);

  // Draw 4 Base zones
  function drawBase(x, y, color, lightColor) {
    // Fill background
    ctx.fillStyle = color;
    ctx.fillRect(x * TS, y * TS, 6 * TS, 6 * TS);
    // Inner white box
    ctx.fillStyle = '#fff';
    ctx.fillRect((x + 1) * TS, (y + 1) * TS, 4 * TS, 4 * TS);
    // 4 token spots
    ctx.fillStyle = lightColor;
    [[x + 1.5, y + 1.5], [x + 3.5, y + 1.5], [x + 1.5, y + 3.5], [x + 3.5, y + 3.5]].forEach(c => {
      ctx.beginPath(); ctx.arc(c[0] * TS, c[1] * TS, TS * 0.6, 0, Math.PI * 2); ctx.fill();
    });
  }
  drawBase(0, 0, COLORS[0], BASE_COLORS[0]);
  drawBase(9, 0, COLORS[1], BASE_COLORS[1]);
  drawBase(9, 9, COLORS[2], BASE_COLORS[2]);
  drawBase(0, 9, COLORS[3], BASE_COLORS[3]);

  // Center Home Triangle
  const cx = 7.5 * TS, cy = 7.5 * TS;
  ctx.beginPath(); ctx.moveTo(6 * TS, 6 * TS); ctx.lineTo(9 * TS, 6 * TS); ctx.lineTo(cx, cy); ctx.fillStyle = COLORS[1]; ctx.fill(); ctx.stroke();
  ctx.beginPath(); ctx.moveTo(9 * TS, 6 * TS); ctx.lineTo(9 * TS, 9 * TS); ctx.lineTo(cx, cy); ctx.fillStyle = COLORS[2]; ctx.fill(); ctx.stroke();
  ctx.beginPath(); ctx.moveTo(9 * TS, 9 * TS); ctx.lineTo(6 * TS, 9 * TS); ctx.lineTo(cx, cy); ctx.fillStyle = COLORS[3]; ctx.fill(); ctx.stroke();
  ctx.beginPath(); ctx.moveTo(6 * TS, 9 * TS); ctx.lineTo(6 * TS, 6 * TS); ctx.lineTo(cx, cy); ctx.fillStyle = COLORS[0]; ctx.fill(); ctx.stroke();

  // Draw Path Cells
  ctx.lineWidth = 1;
  ctx.strokeStyle = '#cbd5e1';

  for (let i = 0; i < PATH.length; i++) {
    const [px, py] = PATH[i];
    ctx.fillStyle = '#fff';
    // Start squares are colored
    if (i === 0) ctx.fillStyle = COLORS[0];
    else if (i === 13) ctx.fillStyle = COLORS[1];
    else if (i === 26) ctx.fillStyle = COLORS[2];
    else if (i === 39) ctx.fillStyle = COLORS[3];
    else if (SAFE_SPOTS.includes(i)) ctx.fillStyle = '#e2e8f0'; // Gray for safe stars

    ctx.fillRect(px * TS, py * TS, TS, TS);
    ctx.strokeRect(px * TS, py * TS, TS, TS);

    // Draw little star for safe spots
    if (SAFE_SPOTS.includes(i) && ![0, 13, 26, 39].includes(i)) {
      ctx.fillStyle = '#94a3b8';
      ctx.font = '20px sans-serif';
      ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
      ctx.fillText('★', px * TS + TS / 2, py * TS + TS / 2);
    }
  }

  // Draw Home Paths
  for (let p = 0; p < 4; p++) {
    const hp = HOME_PATHS[p];
    for (let i = 0; i < 5; i++) {
      ctx.fillStyle = COLORS[p];
      ctx.fillRect(hp[i][0] * TS, hp[i][1] * TS, TS, TS);
      ctx.strokeRect(hp[i][0] * TS, hp[i][1] * TS, TS, TS);
    }
  }

  // Draw Tokens
  let positionsCounts = {}; // Track overlapping tokens on path

  tokens.forEach(t => {
    let bx, by;
    if (t.status === 'home') {
      [bx, by] = BASE_SPOTS[t.player][t.tokenIdx];
    } else if (t.status === 'finished') {
      return; // Dont draw finished explicitly, maybe in center
    } else {
      // Active
      if (t.step <= 50) {
        const globalIdx = (START_OFFSETS[t.player] + t.step) % 52;
        [bx, by] = PATH[globalIdx];
        bx += 0.5; by += 0.5;
        let key = `${bx},${by}`;
        positionsCounts[key] = (positionsCounts[key] || 0) + 1;
      } else {
        const homeIdx = t.step - 51;
        [bx, by] = HOME_PATHS[t.player][homeIdx];
        bx += 0.5; by += 0.5;
      }
    }

    t._drawX = bx * TS;
    t._drawY = by * TS;
  });

  // Second pass: apply offsets for overlapping tokens
  let processedCounts = {};
  tokens.forEach(t => {
    if (t.status !== 'active' || t.step > 50) {
      drawToken(t._drawX, t._drawY, COLORS[t.player], t);
      return;
    }
    const globalIdx = (START_OFFSETS[t.player] + t.step) % 52;
    const [bx, by] = PATH[globalIdx];
    let key = `${bx+0.5},${by+0.5}`;
    let totalAtSpot = positionsCounts[key];

    let ox = t._drawX, oy = t._drawY;
    if (totalAtSpot > 1) {
      processedCounts[key] = (processedCounts[key] || 0);
      let idx = processedCounts[key];
      // small offset grid for tokens sharing a square
      let shiftX = (idx % 2 === 0 ? -1 : 1) * TS * 0.2;
      let shiftY = (idx < 2 ? -1 : 1) * TS * 0.2;
      if (totalAtSpot > 4) shiftX /= 2;
      ox += shiftX; oy += shiftY;
      processedCounts[key]++;
    }
    drawToken(ox, oy, COLORS[t.player], t);
  });
}

function drawToken(x, y, color, t) {
  ctx.beginPath();
  ctx.arc(x, y, TS * 0.35, 0, Math.PI * 2);
  ctx.fillStyle = color;
  ctx.fill();
  ctx.lineWidth = 2;
  ctx.strokeStyle = '#fff';
  if (moveCandidates.includes(t)) {
    ctx.strokeStyle = '#000';
    ctx.setLineDash([5, 3]);
    ctx.lineWidth = 3;
    // highlight pulsing
    if (Math.floor(Date.now() / 200) % 2 === 0) ctx.strokeStyle = '#fff';
  } else {
    ctx.setLineDash([]);
  }
  ctx.stroke();
  ctx.setLineDash([]);

  // inner ring
  ctx.beginPath();
  ctx.arc(x, y, TS * 0.2, 0, Math.PI * 2);
  ctx.strokeStyle = 'rgba(255,255,255,0.4)';
  ctx.stroke();
}

rollBtn.addEventListener('click', () => {
  if (state !== 'WAITING_ROLL') return;
  rollDiceAction();
});

function rollDiceAction() {
  state = 'ANIMATING';
  rollBtn.disabled = true;
  diceEl.classList.add('rolling');

  let ticks = 0;
  let animTimer = setInterval(() => {
    diceEl.innerText = DICE_FACES[Math.floor(Math.random() * 6)];
    ticks++;
    if (ticks > 15) {
      clearInterval(animTimer);
      diceEl.classList.remove('rolling');

      currentDice = Math.floor(Math.random() * 6) + 1;
      diceEl.innerText = DICE_FACES[currentDice - 1];

      evaluateBoard();
    }
  }, 50);
}

function evaluateBoard() {
  if (currentDice === 6) {
    consecutiveSixes++;
    if (consecutiveSixes === 3) {
      announceTurn('3 SIXES - TURN LOST!', '#ff0055');
      consecutiveSixes = 0;
      hasRolledSix = false;
      setTimeout(nextTurn, 1500);
      return;
    }
  } else {
    consecutiveSixes = 0;
  }

  hasRolledSix = (currentDice === 6);
  moveCandidates = [];

  const myTokens = tokens.filter(t => t.player === currentPlayer);

  myTokens.forEach(t => {
    if (t.status === 'home' && (currentDice === 6 || currentDice === 1)) {
      moveCandidates.push(t);
    } else if (t.status === 'active') {
      if (t.step + currentDice <= 56) {
        moveCandidates.push(t);
      }
    }
  });

  if (moveCandidates.length === 0) {
    // No possible moves
    setTimeout(nextTurn, 1000);
    return;
  }

  state = 'WAITING_MOVE';
  drawBoard();

  if (players[currentPlayer].isBot) {
    setTimeout(botChooseMove, 800);
  } else if (moveCandidates.length === 1 && moveCandidates[0].status === 'home') {
    // auto move if only 1 choice and it's getting out
    setTimeout(() => executeMove(moveCandidates[0]), 300);
  }
}

// Bot logic
function playBot() {
  if (state !== 'WAITING_ROLL') return;
  rollDiceAction();
}

function botChooseMove() {
  if (state !== 'WAITING_MOVE') return;

  // Priority: 
  // 1. Capture opponent 
  // 2. Finish token
  // 3. Move out of base
  // 4. Move token closest to winning

  let chosen = null;
  let bestScore = -1;

  for (let t of moveCandidates) {
    let score = 0;
    if (t.status === 'home') {
      score = 50; // Priority: get out
    } else {
      let nextStep = t.step + currentDice;
      if (nextStep === 56) score = 100; // Finish! priority 1
      else {
        // Check capture
        if (nextStep <= 50) {
          const globalIdx = (START_OFFSETS[currentPlayer] + nextStep) % 52;
          if (!SAFE_SPOTS.includes(globalIdx)) {
            let enemies = tokens.filter(o => o.status === 'active' && o.player !== currentPlayer && o.step <= 50 && ((START_OFFSETS[o.player] + o.step) % 52 === globalIdx));
            if (enemies.length > 0) score = 90; // Big priority!
          }
        }
        score += t.step; // Furthest token is better
      }
    }
    if (score > bestScore) {
      bestScore = score;
      chosen = t;
    }
  }

  executeMove(chosen);
}

canvas.addEventListener('click', (e) => {
  if (state !== 'WAITING_MOVE' || players[currentPlayer].isBot) return;

  const rect = canvas.getBoundingClientRect();
  const scaleX = canvas.width / rect.width;
  const scaleY = canvas.height / rect.height;
  const clickX = (e.clientX - rect.left) * scaleX;
  const clickY = (e.clientY - rect.top) * scaleY;

  // find clicked token
  for (let t of moveCandidates) {
    const dist = Math.hypot(t._drawX - clickX, t._drawY - clickY);
    if (dist < TS * 0.6) {
      executeMove(t);
      return;
    }
  }
});

function executeMove(token) {
  state = 'ANIMATING';
  moveCandidates = [];
  drawBoard(); // Remove highlights

  let captured = false;

  if (token.status === 'home') {
    token.status = 'active';
    token.step = 0;
  } else {
    token.step += currentDice;
    if (token.step === 56) {
      token.status = 'finished';
      hasRolledSix = true; // Extra turn for finishing
    } else if (token.step <= 50) {
      // Check capture
      const globalIdx = (START_OFFSETS[currentPlayer] + token.step) % 52;
      if (!SAFE_SPOTS.includes(globalIdx)) {
        tokens.forEach(o => {
          if (o.status === 'active' && o.player !== currentPlayer && o.step <= 50) {
            const oGlobal = (START_OFFSETS[o.player] + o.step) % 52;
            if (oGlobal === globalIdx) {
              o.status = 'home';
              o.step = -1;
              captured = true;
            }
          }
        });
      }
    }
  }

  if (captured) hasRolledSix = true; // Extra turn for capturing

  checkWinCondition();

  drawBoard();
  setTimeout(nextTurn, 500);
}

function nextTurn() {
  if (state === 'GAME_OVER') return;

  if (!hasRolledSix) {
    currentPlayer = (currentPlayer + 1) % 4;
    consecutiveSixes = 0;
  }
  
  const wasExtraTurn = hasRolledSix;
  hasRolledSix = false;
  state = 'WAITING_ROLL';
  updateUI();

  if (!wasExtraTurn) {
    announceTurn(`${NAMES[players[currentPlayer].id]}'S TURN`, COLORS[players[currentPlayer].id]);
  } else {
    announceTurn(`EXTRA TURN!`, COLORS[players[currentPlayer].id]);
  }

  if (players[currentPlayer].isBot) {
    setTimeout(playBot, 1500);
  }
}

function checkWinCondition() {
  const pTokens = tokens.filter(t => t.player === currentPlayer && t.status === 'finished');
  if (pTokens.length === 4) {
    state = 'GAME_OVER';
    turnIndicator.innerText = `\${NAMES[currentPlayer]} WINS!`;
    document.getElementById('players').innerHTML = `<h2>\${NAMES[currentPlayer]} is the Winner!</h2>`;
  }
}

// Ensure pulsing outline updates visually frame to frame
setInterval(() => {
  if (state === 'WAITING_MOVE' && !players[currentPlayer].isBot && moveCandidates.length > 0) {
    drawBoard();
  }
}, 200);

// Kickstart
drawBoard();
