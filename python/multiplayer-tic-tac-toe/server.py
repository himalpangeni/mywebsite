import asyncio
import websockets

async def handler(websocket, path):
    await websocket.send('Tic Tac Toe Server')

if __name__ == '__main__':
    print('Starting websocket server...')
    # asyncio.get_event_loop().run_until_complete(websockets.serve(handler, 'localhost', 8765))