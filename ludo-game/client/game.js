// Ludo client: classic board, online sync via socket.io and local bots
const socket = io();
const canvas = document.getElementById('board');
const ctx = canvas.getContext('2d');
const rollBtn = document.getElementById('roll');
const diceEl = document.getElementById('dice');
const playersEl = document.getElementById('players');
const joinBtn = document.getElementById('join');
const roomInput = document.getElementById('room');
const addBotsCheckbox = document.getElementById('addBots');

let room = 'room1';
let playerId = null;
let players = []; // {id, socketId, color, name, bot}
let state = null; // authoritative state from server

const COLORS = ['red','green','yellow','blue'];
const TOKENS = 4;
const PATH_LEN = 52;

function joinRoom(){
  room = roomInput.value || 'room1';
  socket.emit('joinRoom',{room, name: 'Player'});
}
joinBtn.addEventListener('click', joinRoom);

socket.on('connect', ()=>{ playerId = socket.id; console.log('connected', playerId); });
socket.on('roomUpdate', data=>{ players = data.players; renderPlayers(); });
socket.on('gameStarted', data=>{ state = data.state; players = data.players; renderPlayers(); drawBoard(); });
socket.on('diceRolled', data=>{ diceEl.innerText = data.dice; });
socket.on('tokenMoved', data=>{ state.positions = data.positions; drawBoard(); });
socket.on('turnUpdate', data=>{ if(state) state.turnIndex = data.turnIndex; renderPlayers(); });
socket.on('tokenCaptured', data=>{ // show capture briefly
  console.log('token captured', data);
});

function renderPlayers(){
  playersEl.innerHTML = '';
  players.forEach((p, idx)=>{
    const div = document.createElement('div');
    div.className = 'player-item';
    const isTurn = state && state.playerOrder && state.playerOrder[state.turnIndex]===p.id;
    div.innerHTML = `${p.name} (${p.color}) ${isTurn?'<strong>← turn</strong>':''}`;
    playersEl.appendChild(div);
  });
}

rollBtn.addEventListener('click', ()=>{
  socket.emit('rollDice',{room});
});

// token selection and move
canvas.addEventListener('click', (e)=>{
  if(!state) return;
  const rect = canvas.getBoundingClientRect();
  const x = e.clientX - rect.left; const y = e.clientY - rect.top;
  // find clicked token if any belonging to current player
  const currentPlayerId = state.playerOrder[state.turnIndex];
  if(currentPlayerId !== socket.id) return; // only allow move on your turn
  // simple selection: choose first movable token and send move to server
  const dice = state.dice;
  if(!dice) return;
  const movable = findMovableTokens(currentPlayerId, dice);
  if(movable.length>0){
    socket.emit('moveToken',{room, playerId: currentPlayerId, tokenIndex: movable[0]});
  }
});

function findMovableTokens(pid, dice){
  const toks = state.positions[pid];
  const res = [];
  for(let i=0;i<TOKENS;i++){
    const pos = toks[i];
    if(pos===-1){ if(dice===6) res.push(i); }
    else if(pos + dice <= PATH_LEN) res.push(i);
  }
  return res;
}

// draw classic ludo board grid 15x15 with colored homes
function drawBoard(){
  ctx.clearRect(0,0,canvas.width,canvas.height);
  // board background
  ctx.fillStyle = '#fff'; ctx.fillRect(0,0,canvas.width,canvas.height);

  // simple representation: center cross and 4 homes
  // draw homes
  const size = canvas.width/15;
  function rect(x,y,w,h,fill){ ctx.fillStyle = fill; ctx.fillRect(x*size,y*size,w*size,h*size); ctx.strokeRect(x*size,y*size,w*size,h*size); }

  rect(0,0,6,6,'#ff9999'); // red home
  rect(9,0,6,6,'#99ff99'); // green home (top-right in typical rotated boards)
  rect(0,9,6,6,'#ffff99'); // yellow
  rect(9,9,6,6,'#99ccff'); // blue

  // draw main path cells as small squares around the center cross
  ctx.strokeStyle = '#ccc';
  for(let i=0;i<15;i++){
    for(let j=0;j<15;j++){
      ctx.strokeRect(i*size,j*size,size,size);
    }
  }

  // draw tokens from state if available
  if(state && state.positions){
    const mapping = buildPathMapping(size);
    for(const pid of Object.keys(state.positions)){
      const toks = state.positions[pid];
      const color = players.find(p=>p.id===pid)?.color || 'gray';
      toks.forEach((pos,ti)=>{
        let cx,cy;
        if(pos===-1){ // home pockets: find free spot in home area
          const homeCoords = homeTokenCoord(pid, ti, size);
          cx = homeCoords.x; cy = homeCoords.y;
        } else {
          const coord = mapping[pos%PATH_LEN];
          cx = coord.x; cy = coord.y;
        }
        // draw circle
        ctx.beginPath(); ctx.fillStyle = color; ctx.arc(cx,cy, size*0.5,0,Math.PI*2); ctx.fill(); ctx.stroke();
      });
    }
  }
}

function buildPathMapping(size){
  // Returns array of 52 coordinates around the board (simplified)
  const coords = [];
  // for simplicity, create points around the center in a loop (not exactly Ludo layout but functional)
  const cx = canvas.width/2; const cy = canvas.height/2;
  const r = size*3.5;
  for(let i=0;i<PATH_LEN;i++){
    const angle = (i/ PATH_LEN) * Math.PI*2 - Math.PI/2;
    coords.push({x: cx + Math.cos(angle)*r, y: cy + Math.sin(angle)*r});
  }
  return coords;
}

function homeTokenCoord(pid, tokenIndex, size){
  // place tokens in corners depending on player id order
  const idx = players.findIndex(p=>p.id===pid);
  const pad = size * 1.5;
  if(idx === 0) return {x: pad + tokenIndex*size, y: pad};
  if(idx === 1) return {x: canvas.width - pad - tokenIndex*size, y: pad};
  if(idx === 2) return {x: pad + tokenIndex*size, y: canvas.height - pad};
  return {x: canvas.width - pad - tokenIndex*size, y: canvas.height - pad};
}

// redraw loop
setInterval(()=>{ drawBoard(); }, 600);

// local start: if no server, allow local bots too
socket.on('disconnect', ()=>{
  console.log('disconnected from server — local-only mode');
});

// add bots on client side: request server to add bots as players
addBotsCheckbox.addEventListener('change', ()=>{
  if(addBotsCheckbox.checked){ socket.emit('addBots',{room, count:3}); }
});
