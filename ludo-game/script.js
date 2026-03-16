const board=document.getElementById("board");

let cells=[];

for(let i=0;i<225;i++){

let cell=document.createElement("div");
cell.classList.add("cell");

board.appendChild(cell);

cells.push(cell);

}

const path=[
6,7,8,23,38,53,68,83,98,113,128,127,126,125,
124,109,94,79,64,49,34,19,20,21,22,37,52,
67,82,97,112,111,110,95,80,65,50,35
];

let players=[
{name:"Red",color:"red",pos:0,score:0},
{name:"Green",color:"green",pos:0,score:0},
{name:"Yellow",color:"yellow",pos:0,score:0},
{name:"Blue",color:"blue",pos:0,score:0}
];

let turn=0;

function drawTokens(){

document.querySelectorAll(".token").forEach(t=>t.remove());

players.forEach(p=>{

let token=document.createElement("div");

token.classList.add("token",p.color);

cells[path[p.pos]].appendChild(token);

});

}

function rollDice(){

let dice=Math.floor(Math.random()*6)+1;

document.getElementById("dice").innerText="Dice: "+dice;

movePlayer(dice);

}

function movePlayer(dice){

let player=players[turn];

player.pos+=dice;

if(player.pos>=path.length){

player.score++;

player.pos=0;

updateScore();

}

drawTokens();

turn++;

if(turn>=players.length)turn=0;

document.getElementById("turn").innerText="Turn: "+players[turn].name;

}

function updateScore(){

document.getElementById("redScore").innerText=players[0].score;
document.getElementById("greenScore").innerText=players[1].score;
document.getElementById("yellowScore").innerText=players[2].score;
document.getElementById("blueScore").innerText=players[3].score;

}

drawTokens();