// Simple Omegle-style anonymous chat server
// Run: npm init -y && npm install express socket.io
// Then: node server.js

const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const path = require('path');

const app = express();
const server = http.createServer(app);
const io = new Server(server, { cors: { origin: '*' } });

// Optionally serve a static client from services/chat/public if you place one there
app.use('/chat', express.static(path.join(__dirname, 'public')));

// Waiting queue of sockets looking for a partner
const waiting = [];

io.on('connection', socket => {
  console.log('Chat: socket connected', socket.id);

  socket.on('findPartner', () => {
    console.log('Chat: findPartner', socket.id);
    // If there's someone waiting, pair them
    if(waiting.length > 0){
      const partnerSocket = waiting.shift();
      if(!partnerSocket.connected){
        // Partner disconnected, try again
        socket.emit('partnerNotFound');
        return;
      }
      const room = `chat_${socket.id}_${partnerSocket.id}`;
      socket.join(room);
      partnerSocket.join(room);
      // notify both
      socket.emit('partnerFound', {room, partnerId: partnerSocket.id});
      partnerSocket.emit('partnerFound', {room, partnerId: socket.id});
      console.log(`Chat: paired ${socket.id} with ${partnerSocket.id} in ${room}`);
    } else {
      // add to waiting list
      waiting.push(socket);
      socket.emit('waiting');
    }
  });

  socket.on('message', ({room, text}) => {
    // broadcast to room excluding sender
    socket.to(room).emit('message', {from: socket.id, text});
  });

  socket.on('typing', ({room, typing}) => {
    socket.to(room).emit('typing', {from: socket.id, typing});
  });

  socket.on('leave', ({room}) => {
    socket.to(room).emit('partnerLeft');
    socket.leave(room);
  });

  socket.on('disconnect', () => {
    console.log('Chat: disconnect', socket.id);
    // remove from waiting if present
    const idx = waiting.findIndex(s => s.id === socket.id);
    if(idx !== -1) waiting.splice(idx,1);
    // notify rooms about partner leaving
    const rooms = Object.keys(socket.rooms).filter(r => r.startsWith('chat_'));
    rooms.forEach(r => socket.to(r).emit('partnerLeft'));
  });
});

const PORT = process.env.PORT || 3001;
server.listen(PORT, () => console.log('Chat server listening on', PORT));
