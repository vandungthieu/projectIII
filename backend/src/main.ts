import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { Transport } from '@nestjs/microservices';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // // Tạo microservice với cấu hình MQTT
  // app.connectMicroservice({
  //   transport: Transport.MQTT,
  //   options: {
  //     url: 'mqtts://f275e90fe8454aed8c3d90e35c44fc09.s1.eu.hivemq.cloud:8883',
  //     username: 'dungthieu123',
  //     password: 'Dung.tv215547',
  //   },
  // });

  // // Khởi động ứng dụng
  // await app.startAllMicroservices();

  await app.listen(3000);
  console.log('Starting HTTP server...');
  console.log('Application is running on: http://localhost:3000');
  
}

bootstrap().catch(err => {
  console.error('Application bootstrap failed:', err);
  process.exit(1);
});
