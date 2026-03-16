const express = require('express');
const http = require('http');
const { Server } = require('socket.io');

const app = express();
const server = http.createServer(app);
const io = new Server(server, { cors: { origin: '*' } });

app.use(express.static(__dirname + '/..'));

// Game constants
const MAX_PLAYERS = 4;
const TOKENS_PER_PLAYER = 4;
const TOTAL_STEPS = 52; // main path length

// Rooms state
const rooms = {};

function createRoomIfNotExists(room){
  if(!rooms[room]){
    rooms[room] = {
      players: [], // {id, socketId, color, name, ready}
      state: null, // game state when started
      host: null
    };
  }
}

function newGameState(room){
  const r = rooms[room];
  const playerIds = r.players.map(p=>p.id);
  const colors = ['red','green','yellow','blue'];
  const state = {
    playerOrder: playerIds.slice(0,MAX_PLAYERS),
    positions: {}, // playerId -> array of token positions (-1 = home, 0..TOTAL_STEPS)
    turnIndex: 0,
    dice: 0,
    finished: []
  };
  playerIds.forEach((id,idx)=>{
    state.positions[id] = Array(TOKENS_PER_PLAYER).fill(-1);
  });
  return state;
}

io.on('connection', socket => {
  console.log('socket connected', socket.id);

  socket.on('joinRoom', ({room, name}) => {
    room = room || 'room1';
    createRoomIfNotExists(room);
    const rm = rooms[room];
    if(rm.players.length >= MAX_PLAYERS){
      socket.emit('roomFull');
      return;
    }
    const playerId = socket.id; // use socket id as player id to keep it unique
    const color = ['red','green','yellow','blue'][rm.players.length];
    rm.players.push({id: playerId, socketId: socket.id, color, name: name || ('Player'+(rm.players.length+1)), ready:false});
    if(!rm.host) rm.host = playerId;
    socket.join(room);
    io.to(room).emit('roomUpdate', {players: rm.players});
    console.log(`player joined ${room}`, playerId);
  });

  socket.on('leaveRoom', ({room}) => {
    const rm = rooms[room];
    if(!rm) return;
    rm.players = rm.players.filter(p=>p.socketId !== socket.id);
    io.to(room).emit('roomUpdate', {players: rm.players});
    socket.leave(room);
  });

  socket.on('startGame', ({room}) => {
    const rm = rooms[room];
    if(!rm) return;
    rm.state = newGameState(room);
    io.to(room).emit('gameStarted', {state: rm.state, players: rm.players});
  });

  socket.on('rollDice', ({room}) => {
    const rm = rooms[room];
    if(!rm || !rm.state) return;
    const state = rm.state;
    const playerId = socket.id;
    // check turn
    const currentPlayerId = state.playerOrder[state.turnIndex];
    if(playerId !== currentPlayerId){
      socket.emit('notYourTurn');
      return;
    }
    const dice = Math.floor(Math.random()*6)+1;
    state.dice = dice;
    io.to(room).emit('diceRolled', {playerId, dice});
    // server does not move automatically — clients request move
  });

  socket.on('moveToken', ({room, playerId, tokenIndex}) => {
    const rm = rooms[room];
    if(!rm || !rm.state) return;
    const state = rm.state;
    const currentPlayerId = state.playerOrder[state.turnIndex];
    if(playerId !== currentPlayerId){
      socket.emit('notYourTurn');
      return;
    }
    const dice = state.dice;
    if(!dice) return;
    const tokens = state.positions[playerId];
    if(!tokens) return;
    const pos = tokens[tokenIndex];
    if(pos === -1 && dice !== 6){
      socket.emit('invalidMove');
      return;
    }
    if(pos === -1) tokens[tokenIndex] = 0; else tokens[tokenIndex] = Math.min(pos + dice, TOTAL_STEPS);
    // capture logic: if any other player's token at same step and not safe, send that token home
    for(const otherId of Object.keys(state.positions)){
      if(otherId === playerId) continue;
      state.positions[otherId].forEach((op,oi)=>{
        if(op === tokens[tokenIndex]){
          // send home
          state.positions[otherId][oi] = -1;
          io.to(room).emit('tokenCaptured', {by: playerId, victim: otherId, tokenIndex: oi});
        }
      });
    }
    io.to(room).emit('tokenMoved', {playerId, tokenIndex, step: tokens[tokenIndex], positions: state.positions});
    // if dice was 6, same player's turn, else advance
    if(dice !== 6){
      state.turnIndex = (state.turnIndex + 1) % state.playerOrder.length;
    }
    state.dice = 0;
    io.to(room).emit('turnUpdate', {turnIndex: state.turnIndex});
  });

  socket.on('addBots', ({room, count}) => {
    const rm = rooms[room];
    if(!rm) return;
    for(let i=0;i<count;i++){
      if(rm.players.length >= MAX_PLAYERS) break;
      const botId = 'bot-' + Math.random().toString(36).slice(2,8);
      const color = ['red','green','yellow','blue'][rm.players.length];
      rm.players.push({id: botId, socketId: null, color, name: 'Bot', ready:true, bot:true});
    }
    io.to(room).emit('roomUpdate', {players: rm.players});
  });

  socket.on('disconnecting', () => {
    console.log('disconnecting', socket.id);
    // remove from rooms
    for(const [rname, rm] of Object.entries(rooms)){
      const prevLen = rm.players.length;
      rm.players = rm.players.filter(p => p.socketId !== socket.id);
      if(rm.players.length !== prevLen){
        io.to(rname).emit('roomUpdate', {players: rm.players});
      }
    }
  });

});

const PORT = process.env.PORT || 3000;
server.listen(PORT, ()=>console.log('Ludo server listening on', PORT));
