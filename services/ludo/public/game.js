const socket = io();
const joinBtn = document.getElementById('join');
const startBtn = document.getElementById('start');
const addBotBtn = document.getElementById('addBot');
const roomInput = document.getElementById('room');
const nameInput = document.getElementById('name');
const playersDiv = document.getElementById('players');
const canvas = document.getElementById('board');
const ctx = canvas.getContext('2d');
const rollBtn = document.getElementById('roll');
const diceEl = document.getElementById('dice');

let room = 'room1';
let players = [];
let state = null;

joinBtn.addEventListener('click', ()=>{room = roomInput.value||'room1'; const name = nameInput.value||'Player'; socket.emit('join',{room,name});});
startBtn.addEventListener('click', ()=>{socket.emit('start',{room});});
addBotBtn.addEventListener('click', ()=>{socket.emit('addBot',{room});});
rollBtn.addEventListener('click', ()=>{socket.emit('roll',{room});});

socket.on('roomUpdate', data=>{players=data.players; renderPlayers();});
socket.on('started', data=>{state=data.state; players=data.players; renderPlayers(); drawBoard();});
socket.on('rolled', d=>{diceEl.innerText = d.dice; state.dice = d.dice;});
socket.on('moved', d=>{state.positions = d.positions; drawBoard();});
socket.on('turn', d=>{if(state) state.turnIndex = d.turnIndex; renderPlayers();});

function renderPlayers(){ playersDiv.innerHTML=''; players.forEach((p,idx)=>{const d=document.createElement('div');d.innerText=`${p.name} (${p.color}) ${state&&state.playerOrder&&state.playerOrder[state.turnIndex]===p.id?'<- turn':''}`;playersDiv.appendChild(d)});}

canvas.addEventListener('click', ()=>{
  if(!state) return; const pid = socket.id; const current = state.playerOrder[state.turnIndex]; if(current !== pid) return; const movable = findMovableTokens(pid, state.dice); if(movable.length>0){ socket.emit('move',{room, tokenIndex:movable[0]}); }
});

function findMovableTokens(pid,dice){ if(!state) return []; const toks = state.positions[pid]; const res=[]; for(let i=0;i<toks.length;i++){ const pos=toks[i]; if(pos===-1 && dice===6) res.push(i); else if(pos!==-1 && pos + dice <= 52) res.push(i); } return res; }

function drawBoard(){ ctx.clearRect(0,0,canvas.width,canvas.height); ctx.fillStyle='#fff'; ctx.fillRect(0,0,canvas.width,canvas.height); const cx=canvas.width/2, cy=canvas.height/2; ctx.beginPath(); ctx.arc(cx,cy,200,0,Math.PI*2); ctx.stroke(); if(state && state.positions){ const mapping = buildPathMapping(); for(const pid of Object.keys(state.positions)){ const p = players.find(x=>x.id===pid) || {color:'gray'}; const toks = state.positions[pid]; toks.forEach((pos,ti)=>{ let x,y; if(pos===-1){ const home = homeTokenCoord(pid,ti); x=home.x; y=home.y; } else { const coord = mapping[pos%52]; x=coord.x; y=coord.y; } ctx.beginPath(); ctx.fillStyle = p.color; ctx.arc(x,y,12,0,Math.PI*2); ctx.fill(); ctx.stroke(); }); } } }

function buildPathMapping(){ const coords=[]; const cx=canvas.width/2; const cy=canvas.height/2; const r=180; for(let i=0;i<52;i++){ const a = (i/52)*Math.PI*2 - Math.PI/2; coords.push({x:cx+Math.cos(a)*r, y:cy+Math.sin(a)*r}); } return coords; }

function homeTokenCoord(pid, tokenIndex){ const idx = players.findIndex(p=>p.id===pid); const pad=40; if(idx===0) return {x:pad+tokenIndex*20, y:pad}; if(idx===1) return {x:canvas.width-pad-tokenIndex*20, y:pad}; if(idx===2) return {x:pad+tokenIndex*20, y:canvas.height-pad}; return {x:canvas.width-pad-tokenIndex*20, y:canvas.height-pad}; }

setInterval(()=>{ if(state) drawBoard(); },500);
