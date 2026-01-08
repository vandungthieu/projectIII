import { Body, Controller, ForbiddenException, Logger, Post, Request, UseGuards } from '@nestjs/common';
import { EventPattern, Payload, Ctx, MqttContext } from '@nestjs/microservices';
import { SensorDataService } from '../sensor-data/sensor-data.service';
import { MqttClientService } from './mqtt.client';
import { PrismaService } from 'src/prisma/prisma.service';
import { AuthGuard } from '@nestjs/passport';
import { JwtAuthGuard } from 'src/auth/guards/jwt-auth.guard';

@Controller('buzzer')
export class MqttController {
  private readonly logger = new Logger(MqttController.name);

  constructor(
    private readonly mqttService: MqttClientService,
    private readonly prisma: PrismaService,
  ) {}

  @Post()
  @UseGuards(JwtAuthGuard)
  async controlBuzzer(@Body() body: { deviceId: string; action: 'on' | 'off' }, @Request() req : any) {
      const { deviceId, action } = body;

      // kiểm tra thiết bị có tồn tại không
      const device = await this.prisma.device.findUnique({
        where: { deviceId },
      });

      if (!device) {
        return { success: false, message: 'Thiết bị không tồn tại' };
      }

      if(device.userId !== req.user.id){
         throw new ForbiddenException('Bạn không có quyền truy cập thiết bị này')
      }

      // publish lệnh MQTT đến thiết bị
      const topic = `buzzer/${deviceId}`;
      const payload = { action };

      this.mqttService.publish(topic, payload);

      await this.prisma.device.update({
        where: { deviceId },
        data: { buzzerStatus: action === 'on' },
      });

      return {
        success: true,
        message: `Đã gửi lệnh ${action} tới thiết bị ${deviceId}`,
      };
  }
  
}
