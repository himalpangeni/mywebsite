// server.js
const express = require('express');
const http = require('http');
const { Server } = require('socket.io');

const app = express();
const server = http.createServer(app);
const io = new Server(server);

app.use(express.static('public'));

let waitingQueue = [];
let rooms = {}; // socket.id -> roomName

io.on('connection', (socket) => {
  console.log('User connected:', socket.id);
  
  // Inform the user how many people are online
  io.emit('onlineCount', io.engine.clientsCount);

  socket.on('startSearch', () => {
    // Check if someone else is waiting
    if (waitingQueue.length > 0) {
      // It's a match!
      const partnerId = waitingQueue.shift();
      const roomName = `room_${partnerId}_${socket.id}`;
      
      // Join both to the room
      socket.join(roomName);
      io.sockets.sockets.get(partnerId)?.join(roomName);
      
      // Save room info
      rooms[socket.id] = roomName;
      rooms[partnerId] = roomName;
      
      // Notify both
      io.to(roomName).emit('matchFound', "You're now chatting with a random stranger.");
    } else {
      // Nobody waiting, put this user in queue
      waitingQueue.push(socket.id);
      socket.emit('waiting', "Waiting for a partner...");
    }
  });

  socket.on('sendMessage', (msg) => {
    const roomName = rooms[socket.id];
    if (roomName) {
      // Send message to the other person in the room
      socket.broadcast.to(roomName).emit('receiveMessage', msg);
    }
  });

  socket.on('typing', () => {
    const roomName = rooms[socket.id];
    if (roomName) socket.broadcast.to(roomName).emit('partnerTyping');
  });

  socket.on('stopTyping', () => {
    const roomName = rooms[socket.id];
    if (roomName) socket.broadcast.to(roomName).emit('partnerStoppedTyping');
  });

  socket.on('nextPerson', () => {
    const roomName = rooms[socket.id];
    if (roomName) {
      socket.broadcast.to(roomName).emit('partnerLeft', "Stranger has disconnected.");
      
      // Remove both from room
      const clients = io.sockets.adapter.rooms.get(roomName) || new Set();
      for (const clientId of clients) {
        const clientSocket = io.sockets.sockets.get(clientId);
        if (clientSocket) {
          clientSocket.leave(roomName);
          delete rooms[clientId];
        }
      }
    }
    
    // Remove if they were waiting
    waitingQueue = waitingQueue.filter(id => id !== socket.id);
  });

  socket.on('disconnect', () => {
    console.log('User disconnected:', socket.id);
    const roomName = rooms[socket.id];
    
    if (roomName) {
      socket.broadcast.to(roomName).emit('partnerLeft', "Stranger has disconnected.");
      delete rooms[socket.id];
    }
    
    waitingQueue = waitingQueue.filter(id => id !== socket.id);
    io.emit('onlineCount', io.engine.clientsCount);
  });
});

const PORT = 3005;
server.listen(PORT, () => {
  console.log(`Strangify running on http://localhost:${PORT}`);
});
