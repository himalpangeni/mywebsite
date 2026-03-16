// Ludo service (separate microservice)
// Run:
// cd services/ludo
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

const MAX_PLAYERS = 4;
const TOKENS = 4;
const TOTAL_STEPS = 52;

const rooms = {}; // room -> {players: [{id,socketId,name,color}], state}

function createRoom(room){ if(!rooms[room]) rooms[room] = {players: [], state: null}; }

function newGameState(playerIds){
  const state = { playerOrder: playerIds.slice(), positions: {}, turnIndex: 0, dice: 0, finished: [] };
  playerIds.forEach(id => state.positions[id] = Array(TOKENS).fill(-1));
  return state;
}

io.on('connection', socket => {
  console.log('Ludo svc: connected', socket.id);

  socket.on('join', ({room, name}) => {
    room = room || 'room1'; createRoom(room);
    const rm = rooms[room];
    if(rm.players.length >= MAX_PLAYERS){ socket.emit('roomFull'); return; }
    const pid = socket.id;
    const color = ['red','green','yellow','blue'][rm.players.length];
    rm.players.push({id: pid, socketId: socket.id, name: name || 'Player', color});
    socket.join(room);
    io.to(room).emit('roomUpdate', {players: rm.players});
  });

  socket.on('start', ({room}) => {
    const rm = rooms[room]; if(!rm) return;
    const ids = rm.players.map(p=>p.id);
    rm.state = newGameState(ids);
    io.to(room).emit('started', {state: rm.state, players: rm.players});
  });

  socket.on('roll', ({room}) => {
    const rm = rooms[room]; if(!rm || !rm.state) return;
    const st = rm.state;
    const pid = socket.id;
    if(st.playerOrder[st.turnIndex] !== pid){ socket.emit('notYourTurn'); return; }
    const dice = Math.floor(Math.random()*6)+1; st.dice = dice;
    io.to(room).emit('rolled', {playerId: pid, dice});
  });

  socket.on('move', ({room, tokenIndex}) => {
    const rm = rooms[room]; if(!rm || !rm.state) return;
    const st = rm.state; const pid = socket.id;
    if(st.playerOrder[st.turnIndex] !== pid){ socket.emit('notYourTurn'); return; }
    const dice = st.dice; if(!dice){ socket.emit('noDice'); return; }
    const toks = st.positions[pid]; const pos = toks[tokenIndex];
    if(pos === -1 && dice !== 6){ socket.emit('invalid'); return; }
    toks[tokenIndex] = (pos===-1)?0:Math.min(pos + dice, TOTAL_STEPS);
    // capture simplistic
    for(const otherId of Object.keys(st.positions)){
      if(otherId === pid) continue;
      st.positions[otherId].forEach((op,oi)=>{ if(op === toks[tokenIndex]){ st.positions[otherId][oi] = -1; io.to(room).emit('captured',{by:pid,victim:otherId,tokenIndex:oi}); } });
    }
    io.to(room).emit('moved',{playerId:pid,tokenIndex,step:toks[tokenIndex],positions: st.positions});
    if(dice !== 6) st.turnIndex = (st.turnIndex + 1) % st.playerOrder.length; st.dice = 0; io.to(room).emit('turn', {turnIndex: st.turnIndex});
  });

  socket.on('addBot', ({room}) => {
    const rm = rooms[room]; if(!rm) return; const botId = 'bot-'+Math.random().toString(36).slice(2,8); const color = ['red','green','yellow','blue'][rm.players.length]; rm.players.push({id:botId,socketId:null,name:'Bot',color,bot:true}); io.to(room).emit('roomUpdate',{players:rm.players});
  });

  socket.on('disconnect', ()=>{
    for(const [room,rm] of Object.entries(rooms)){
      const prev = rm.players.length; rm.players = rm.players.filter(p=>p.socketId !== socket.id); if(rm.players.length !== prev) io.to(room).emit('roomUpdate',{players:rm.players});
    }
  });
});

const PORT = process.env.PORT || 3003; server.listen(PORT, ()=>console.log('Ludo service listening on', PORT));
