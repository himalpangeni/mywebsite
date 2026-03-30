const fs = require('fs');
const path = require('path');

const baseDir = '/home/user/Documents/Web_Launch';

// ── Shared mobile CSS injected into <style> ──────────────────────────────────
const mobileCSS = `
    /* ===== MOBILE TOUCH CONTROLS ===== */
    #touch-dpad {
      display: none;
      position: fixed;
      bottom: 30px;
      left: 50%;
      transform: translateX(-50%);
      z-index: 9999;
      user-select: none;
      -webkit-user-select: none;
      touch-action: none;
    }
    @media (max-width: 900px), (pointer: coarse) {
      #touch-dpad { display: grid; }
    }
    #touch-dpad.lr { grid-template-columns: 1fr 1fr; gap: 20px; }
    #touch-dpad.udlr { grid-template-columns: 1fr 1fr 1fr; grid-template-rows: 1fr 1fr; gap: 6px; width: 180px; }
    #touch-dpad.tap { grid-template-columns: 1fr; }
    .dpad-btn {
      width: 75px;
      height: 75px;
      border-radius: 50%;
      background: rgba(255,255,255,0.12);
      border: 2px solid rgba(255,255,255,0.35);
      color: white;
      font-size: 28px;
      display: flex;
      align-items: center;
      justify-content: center;
      cursor: pointer;
      backdrop-filter: blur(8px);
      -webkit-backdrop-filter: blur(8px);
      box-shadow: 0 4px 20px rgba(0,0,0,0.4);
      transition: background 0.1s, transform 0.1s;
      -webkit-tap-highlight-color: transparent;
    }
    .dpad-btn:active, .dpad-btn.pressed {
      background: rgba(0,210,255,0.4);
      border-color: #00d2ff;
      transform: scale(0.9);
    }
    .dpad-btn.tap-btn {
      width: 120px;
      height: 120px;
      font-size: 40px;
      background: rgba(0,210,255,0.15);
      border-color: #00d2ff;
    }
    #touch-hint {
      position: fixed;
      bottom: 10px;
      left: 50%;
      transform: translateX(-50%);
      color: rgba(255,255,255,0.4);
      font-size: 0.75rem;
      pointer-events: none;
      z-index: 9998;
      display: none;
    }
    @media (max-width: 900px), (pointer: coarse) {
      #touch-hint { display: block; }
      canvas { touch-action: none; }
    }
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
    // ===== MOBILE: dispatch keyboard events from touch buttons =====
    function touchKey(k, down) {
      window.dispatchEvent(new KeyboardEvent(down ? 'keydown' : 'keyup', { key: k, code: k, bubbles: true }));
    }
    // Prevent default touch scroll on game canvas
    document.addEventListener('touchmove', e => e.preventDefault(), { passive: false });
    // ===== END MOBILE =====
`;
}

function udlrTouchJS() { return lrTouchJS(); }

function tapTouchJS() {
  return `
    // ===== MOBILE: tap button dispatches Space =====
    function touchTap() {
      window.dispatchEvent(new KeyboardEvent('keydown', { code: 'Space', key: ' ', bubbles: true }));
    }
    document.addEventListener('touchmove', e => e.preventDefault(), { passive: false });
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

  // Skip if already has our marker
  if (content.includes('MOBILE TOUCH CONTROLS')) {
    console.log(`ALREADY DONE: ${rel}`);
    skipped++;
    continue;
  }

  // 1. Inject CSS into <style> block (before </style>)
  content = content.replace('</style>', mobileCSS + '\n  </style>');

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
  // Inject before the last </script>
  const lastScriptClose = content.lastIndexOf('</script>');
  if (lastScriptClose >= 0) {
    content = content.slice(0, lastScriptClose) + js + '\n  </script>' + content.slice(lastScriptClose + 9);
  }

  fs.writeFileSync(full, content, 'utf8');
  console.log(`✅ UPDATED (${cfg.type}): ${rel}`);
  updated++;
}

console.log(`\nDone! Updated: ${updated} | Skipped: ${skipped}`);
