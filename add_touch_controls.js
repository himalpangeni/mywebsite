const fs = require('fs');
const path = require('path');

const baseDir = '/home/user/Documents/Web_Launch';

// ── Shared mobile CSS injected into <style> ──────────────────────────────────
const mobileCSS = `
    /* ===== MOBILE TOUCH CONTROLS ===== */
    #touch-dpad {
      display: none;
      position: fixed;
      bottom: 25px;
      left: 50%;
      transform: translateX(-50%);
      z-index: 9999;
      user-select: none;
      -webkit-user-select: none;
      touch-action: none;
    }
    @media (max-width: 900px), (pointer: coarse) {
      #touch-dpad { display: grid; }
      /* Scope room for dpad at bottom of various game layouts */
      .card, .container, #ui-card, .game-area, .board-container { margin-bottom: 220px !important; }
      .nav, .controls { bottom: 130px !important; position: fixed !important; left: 50% !important; transform: translateX(-50%) !important; width: 100% !important; justify-content: center !important; }
      /* Ensure game buttons are above dpad if necessary */
      #startBtn, .btn, button, .roll-btn { position: relative; z-index: 10000; touch-action: manipulation; }
    }
    #touch-dpad.lr { grid-template-columns: 1fr 1fr; gap: 40px; }
    #touch-dpad.udlr { grid-template-columns: 1fr 1fr 1fr; grid-template-rows: 1fr 1fr; gap: 10px; width: 220px; }
    #touch-dpad.tap { grid-template-columns: 1fr; }
    .dpad-btn {
      width: 85px;
      height: 85px;
      border-radius: 50%;
      background: rgba(255,255,255,0.1);
      border: 2px solid rgba(255,255,255,0.3);
      color: white;
      font-size: 32px;
      display: flex;
      align-items: center;
      justify-content: center;
      cursor: pointer;
      backdrop-filter: blur(5px);
      -webkit-backdrop-filter: blur(5px);
      box-shadow: 0 4px 15px rgba(0,0,0,0.3);
      transition: background 0.1s;
      -webkit-tap-highlight-color: transparent;
    }
    .dpad-btn:active {
      background: rgba(0,210,255,0.4);
      border-color: #00d2ff;
    }
    .dpad-btn.tap-btn { width: 140px; height: 140px; font-size: 40px; background: rgba(0,210,255,0.1); border-color: #00d2ff; }
    #touch-hint { position: fixed; bottom: 5px; left: 50%; transform: translateX(-50%); color: rgba(255,255,255,0.4); font-size: 0.7rem; pointer-events: none; z-index: 9998; display: none; text-transform: uppercase; letter-spacing: 1px; }
    @media (max-width: 900px), (pointer: coarse) { #touch-hint { display: block; } canvas { touch-action: none; } }
    /* ===== END MOBILE TOUCH CONTROLS ===== */
`;

// ── D-pad HTML variants ───────────────────────────────────────────────────────
function lrDpad() {
  return `
  <div id="touch-dpad" class="lr">
    <div class="dpad-btn" id="btn-left"
         ontouchstart="touchKey('ArrowLeft',true)" ontouchend="touchKey('ArrowLeft',false)"
         onmousedown="touchKey('ArrowLeft',true)" onmouseup="touchKey('ArrowLeft',false)">◀</div>
    <div class="dpad-btn" id="btn-right"
         ontouchstart="touchKey('ArrowRight',true)" ontouchend="touchKey('ArrowRight',false)"
         onmousedown="touchKey('ArrowRight',true)" onmouseup="touchKey('ArrowRight',false)">▶</div>
  </div>
  <div id="touch-hint">Touch ◀ ▶ to move</div>`;
}

function udlrDpad() {
  return `
  <div id="touch-dpad" class="udlr">
    <div></div>
    <div class="dpad-btn" id="btn-up"
         ontouchstart="touchKey('ArrowUp',true)" ontouchend="touchKey('ArrowUp',false)"
         onmousedown="touchKey('ArrowUp',true)" onmouseup="touchKey('ArrowUp',false)">▲</div>
    <div></div>
    <div class="dpad-btn" id="btn-left"
         ontouchstart="touchKey('ArrowLeft',true)" ontouchend="touchKey('ArrowLeft',false)"
         onmousedown="touchKey('ArrowLeft',true)" onmouseup="touchKey('ArrowLeft',false)">◀</div>
    <div class="dpad-btn" id="btn-down"
         ontouchstart="touchKey('ArrowDown',true)" ontouchend="touchKey('ArrowDown',false)"
         onmousedown="touchKey('ArrowDown',true)" onmouseup="touchKey('ArrowDown',false)">▼</div>
    <div class="dpad-btn" id="btn-right"
         ontouchstart="touchKey('ArrowRight',true)" ontouchend="touchKey('ArrowRight',false)"
         onmousedown="touchKey('ArrowRight',true)" onmouseup="touchKey('ArrowRight',false)">▶</div>
  </div>
  <div id="touch-hint">Use the D-pad to move</div>`;
}

function tapBtn() {
  return `
  <div id="touch-dpad" class="tap">
    <div class="dpad-btn tap-btn"
         ontouchstart="touchTap()" onmousedown="touchTap()">TAP</div>
  </div>
  <div id="touch-hint">Tap to play</div>`;
}

// ── touch JS injected before </script> ────────────────────────────────────────
function lrTouchJS() {
  return `
    // ===== MOBILE: robust touch handling =====
    function touchKey(k, down) {
      // 1. Dispatch event for games using addEventListener
      window.dispatchEvent(new KeyboardEvent(down ? 'keydown' : 'keyup', { key: k, code: k, bubbles: true }));
      
      // 2. Direct update for games using a 'keys' object (like Neon Dodge)
      if (typeof keys !== 'undefined') {
        if (keys.hasOwnProperty(k)) keys[k] = down;
      }

      // 3. Special case for Snake (direct direction update)
      if (down && typeof dir !== 'undefined' && typeof running !== 'undefined' && running) {
        if (k === 'ArrowUp' && dir.y === 0) dir = { x: 0, y: -1 };
        else if (k === 'ArrowDown' && dir.y === 0) dir = { x: 0, y: 1 };
        else if (k === 'ArrowLeft' && dir.x === 0) dir = { x: -1, y: 0 };
        else if (k === 'ArrowRight' && dir.x === 0) dir = { x: 1, y: 0 };
      }
    }
    const canv = document.querySelector('canvas');
    if (canv) canv.addEventListener('touchmove', e => e.preventDefault(), { passive: false });
    // ===== END MOBILE =====
`;
}

function udlrTouchJS() { return lrTouchJS(); }

function tapTouchJS() {
  return `
    // ===== MOBILE: tap handling =====
    function touchTap() {
      window.dispatchEvent(new KeyboardEvent('keydown', { code: 'Space', key: ' ', bubbles: true }));
      // Direct jump for runner games
      if (typeof isGameOver !== 'undefined' && isGameOver) {
         if (typeof initGame === 'function') initGame();
      }
    }
    const canv = document.querySelector('canvas');
    if (canv) canv.addEventListener('touchmove', e => e.preventDefault(), { passive: false });
    // ===== END MOBILE =====
`;
}

// ── Per-game config ───────────────────────────────────────────────────────────
// type: 'lr' = left/right only, 'udlr' = all 4, 'tap' = space/tap only, 'skip' = already fully mobile-friendly
const gameConfig = {
  'game/neon-dodge/index.html':         { type: 'lr' },
  'game/ice-slide-puzzle/index.html':   { type: 'lr' },
  'game/shape-shift-escape/index.html': { type: 'lr' },
  'game/gravity-flip-runner/index.html':{ type: 'tap' },
  'game/color-match-breaker/index.html':{ type: 'tap' },
  'game/wind-archer/index.html':        { type: 'tap' },
  'game/one-tap-sword-duel/index.html': { type: 'tap' },
  'game/perfect-shot/index.html':       { type: 'tap' },
  'game/spiral-fall/index.html':        { type: 'tap' },
  'game/memory-flash-grid/index.html':  { type: 'tap' },
  'c/snake-game/index.html':            { type: 'udlr' },
};

let updated = 0;
let skipped = 0;

for (const [rel, cfg] of Object.entries(gameConfig)) {
  const full = path.join(baseDir, rel);
  if (!fs.existsSync(full)) { console.log(`SKIP (not found): ${rel}`); skipped++; continue; }

  let content = fs.readFileSync(full, 'utf8');

  // Strip previous mobile-controls if they exist to allow clean re-injection
  content = content.replace(/\/\* ===== MOBILE TOUCH CONTROLS ===== \*\/[\s\S]*?\/\* ===== END MOBILE TOUCH CONTROLS ===== \*\//g, '');
  content = content.replace(/<div id="touch-dpad"[\s\S]*?<div id="touch-hint">.*?<\/div>/g, '');
  content = content.replace(/\/\/ ===== MOBILE: dispatch[\s\S]*?\/\/ ===== END MOBILE =====/g, '');
  content = content.replace(/\/\/ ===== MOBILE: tap[\s\S]*?\/\/ ===== END MOBILE =====/g, '');

  // 1. Inject CSS into <style> block (before </style>)
  if (content.includes('</style>')) {
    content = content.replace('</style>', mobileCSS + '\n  </style>');
  } else {
    content = content.replace('</head>', '<style>' + mobileCSS + '</style>\n</head>');
  }

  // 2. Inject HTML before </body>
  let html = '';
  if (cfg.type === 'lr') html = lrDpad();
  else if (cfg.type === 'udlr') html = udlrDpad();
  else html = tapBtn();
  content = content.replace('</body>', html + '\n</body>');

  // 3. Inject JS before closing </script> (the LAST one)
  let js = '';
  if (cfg.type === 'lr') js = lrTouchJS();
  else if (cfg.type === 'udlr') js = udlrTouchJS();
  else js = tapTouchJS();
  
  const lastScriptClose = content.lastIndexOf('</script>');
  if (lastScriptClose >= 0) {
    content = content.slice(0, lastScriptClose) + js + '\n  </script>' + content.slice(lastScriptClose + 9);
  } else {
    content = content.replace('</body>', '<script>' + js + '</script>\n</body>');
  }

  fs.writeFileSync(full, content, 'utf8');
  console.log(`✅ UPDATED (${cfg.type}): ${rel}`);
  updated++;
}

console.log(`\nDone! Updated: ${updated} | Skipped: ${skipped}`);
