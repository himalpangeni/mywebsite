// Multiplayer Snake server
// Run:
// cd services/snake
// npm init -y
// npm install express socket.io
// node server.js

const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const path = require('path');

const app = express();
const server = http.createServer(app);
const io = new Server(server, { cors: { origin: '*' } });

app.use('/', express.static(path.join(__dirname, 'public')));

const TICK_RATE = 100; // ms
const ROOM_SIZE = 6;

const rooms = {}; // room -> {players: {id, socketId, dir, snake}, food}

function createRoom(name){ if(!rooms[name]) rooms[name] = {players:{}, food:randomFood(), width:40, height:30}; }
function randomFood(){ return {x: Math.floor(Math.random()*40), y: Math.floor(Math.random()*30)}; }

io.on('connection', socket => {
  console.log('Snake connected', socket.id);
  socket.on('join', ({room, name})=>{
    room = room || 'snake1'; createRoom(room);
    const r = rooms[room];
    r.players[socket.id] = {id: socket.id, socketId: socket.id, name: name||'Player', dir: {x:1,y:0}, snake: [{x:5,y:5}], alive:true};
    socket.join(room);
    io.to(room).emit('state', r);
  });

  socket.on('dir', ({room, dir})=>{
    const r = rooms[room]; if(!r) return; if(r.players[socket.id]) r.players[socket.id].dir = dir;
  });

  socket.on('leave', ({room})=>{ const r = rooms[room]; if(!r) return; delete r.players[socket.id]; socket.leave(room); });

  socket.on('disconnect', ()=>{ for(const rm of Object.values(rooms)){ if(rm.players[socket.id]) delete rm.players[socket.id]; } });
});

// game loop per room
setInterval(()=>{
  for(const [name, room] of Object.entries(rooms)){
    // advance each player's snake
    for(const p of Object.values(room.players)){
      if(!p.alive) continue;
      const head = {x: p.snake[0].x + p.dir.x, y: p.snake[0].y + p.dir.y};
      // wrap
      if(head.x < 0) head.x = room.width-1; if(head.x >= room.width) head.x = 0;
      if(head.y < 0) head.y = room.height-1; if(head.y >= room.height) head.y = 0;
      // collision with food
      let ate = false;
      if(head.x === room.food.x && head.y === room.food.y){ ate = true; room.food = randomFood(); }
      p.snake.unshift(head);
      if(!ate) p.snake.pop();
      // check self collision
      for(let i=1;i<p.snake.length;i++){ if(p.snake[i].x === head.x && p.snake[i].y === head.y){ p.alive = false; break; }}
    }
    io.to(name).emit('state', room);
  }
}, TICK_RATE);

const PORT = process.env.PORT || 3004; server.listen(PORT, ()=>console.log('Snake server listening on', PORT));
