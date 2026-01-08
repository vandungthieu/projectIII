// src/mqtt/mqtt.module.ts
import { Module } from '@nestjs/common';

import { PrismaModule } from 'src/prisma/prisma.module';
import { SensorDataModule } from 'src/sensor-data/sensor-data.module';
import { MqttController } from './mqtt.controller';
import { DeviceModule } from 'src/device/device.module';
import { MqttClientService } from './mqtt.client';

@Module({
  imports:[PrismaModule, SensorDataModule, DeviceModule],
  controllers:[MqttController],
  providers:[MqttClientService],
  exports:[MqttClientService]
})
export class MqttModule {}
