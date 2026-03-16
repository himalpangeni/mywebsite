const socket = io();
const joinBtn = document.getElementById('join');
const roomInput = document.getElementById('room');
const nameInput = document.getElementById('name');
const canvas = document.getElementById('c');
const ctx = canvas.getContext('2d');
let room = 'snake1';
joinBtn.addEventListener('click', ()=>{room = roomInput.value||'snake1'; socket.emit('join',{room, name:nameInput.value||'Player'});});

window.addEventListener('keydown', (e)=>{
  let dir = null;
  if(e.key==='ArrowLeft') dir={x:-1,y:0};
  if(e.key==='ArrowRight') dir={x:1,y:0};
  if(e.key==='ArrowUp') dir={x:0,y:-1};
  if(e.key==='ArrowDown') dir={x:0,y:1};
  if(dir){ socket.emit('dir',{room, dir}); }
});

socket.on('state', (state)=>{ draw(state); });

function draw(state){ ctx.clearRect(0,0,canvas.width,canvas.height); const w = state.width, h = state.height; const cellW = canvas.width / w, cellH = canvas.height / h; // draw food
 ctx.fillStyle='red'; ctx.fillRect(state.food.x*cellW, state.food.y*cellH, cellW, cellH); // draw players
 for(const p of Object.values(state.players)){ ctx.fillStyle = p.alive ? '#0f0' : '#555'; for(const s of p.snake){ ctx.fillRect(s.x*cellW, s.y*cellH, cellW-1, cellH-1); } }
}

