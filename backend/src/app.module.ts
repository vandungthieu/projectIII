import { MiddlewareConsumer, Module, RequestMethod } from '@nestjs/common';
import { PrismaModule } from './prisma/prisma.module';
import { AuthModule } from './auth/auth.module';
import { LoggerMiddleware } from './middleware/logger.middleware';
import { UserModule } from './user/user.module';
import { DeviceModule } from './device/device.module';
import { MqttModule } from './mqtt/mqtt.module';
import { SensorDataModule } from './sensor-data/sensor-data.module';
import { MqttClientService } from './mqtt/mqtt.client';

@Module({
  imports: [PrismaModule, AuthModule, UserModule, DeviceModule, MqttModule, SensorDataModule],
  
})
export class AppModule {
  configure(consumer: MiddlewareConsumer){
    consumer
    .apply(LoggerMiddleware)
    .forRoutes({path:'*', method: RequestMethod.ALL})
  }
}

