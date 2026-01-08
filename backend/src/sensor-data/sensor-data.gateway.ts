import {
  WebSocketGateway,
  WebSocketServer,
  OnGatewayConnection,
  OnGatewayDisconnect,
  SubscribeMessage,
  MessageBody,
  ConnectedSocket
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import * as jwt from 'jsonwebtoken';

@WebSocketGateway({
  cors: {
    origin: '*',
  },
})
export class SensorDataGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  private connectedClients = new Map<string, { socket: Socket; userId?: number }>();

  handleConnection(client: Socket) {
    console.log(` Client connected: ${client.id}`);
    this.connectedClients.set(client.id, { socket: client });
  }

  handleDisconnect(client: Socket) {
    console.log(` Client disconnected: ${client.id}`);
    this.connectedClients.delete(client.id);
  }

  //  Nhận token từ client sau khi kết nối
  @SubscribeMessage('auth')
  async handleAuth(
    @MessageBody() data: { token: string },
    @ConnectedSocket() client: Socket,
  ) {
    try {
    console.log('Received data from client:', data);
      const decoded = jwt.verify(data.token, process.env.JWT_SECRET!) as unknown as { sub: number };
      const clientInfo = this.connectedClients.get(client.id);
      if (clientInfo) clientInfo.userId = decoded.sub;

      console.log(` Client ${client.id} authenticated as user ${decoded.sub}`);
      client.emit('receive', { message: 'Authenticated successfully' });
    } catch (err) {
      console.error(' Invalid token');
      client.emit('receive', { message: 'Invalid token' });
      client.disconnect();
    }
  }

  //  Gửi dữ liệu chỉ cho 1 user đã xác thực
  sendDataToUser(userId: number, data: any) {
    for (const [_, clientInfo] of this.connectedClients) {
      if (clientInfo.userId === userId) {
        clientInfo.socket.emit('sensorData', data);
      }
    }
  }

  // Gửi cảnh báo cho user đã xác thực
    sendAlertToUser(userId: number, alert: any) {
        for (const [_, clientInfo] of this.connectedClients) {
            if (clientInfo.userId === userId) {
                clientInfo.socket.emit('alert', alert);
            }
        }
  }
}
