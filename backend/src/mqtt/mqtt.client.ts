import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import * as mqtt from 'mqtt';
import { DeviceService } from 'src/device/device.service';
import { SensorDataService } from 'src/sensor-data/sensor-data.service';

@Injectable()
export class MqttClientService implements OnModuleInit {
  private client: mqtt.MqttClient;
  private readonly logger = new Logger(MqttClientService.name);

   // Cache lưu các thiết bị đã xác thực (deviceId → Timeout để xóa sau TTL)
  private readonly deviceAuthCache = new Map<string, NodeJS.Timeout>();

  constructor(
    private sensorDataService: SensorDataService,
    private readonly deviceService: DeviceService,
  ) {}

  onModuleInit() {
    this.client = mqtt.connect('mqtts://f275e90fe8454aed8c3d90e35c44fc09.s1.eu.hivemq.cloud:8883', 
    {
        username: 'dungthieu123',
        password: 'Dung.tv215547',
    });

   this.client.on('connect', () => {
      console.log('Connected to MQTT broker');

      this.client.subscribe('device/#', (err) => {
        if (err) {
          console.error(' Subscribe error:', err.message);
        } else {
          console.log(' Subscribed to topic: device/#');
        }
      });

      
    });

    //  Khi có message gửi đến từ broker
    this.client.on('message', async (topic, message) => {
      try {
        const payload = JSON.parse(message.toString());
        const deviceId = topic.split('/')[1]; // tách deviceId từ topic

        // Xác thực thiết bị (nếu chưa xác thực)
        if (!this.deviceAuthCache.has(deviceId)) {
          const isValid = await this.deviceService.validateDevice(
            deviceId,
            payload.deviceKey,
          );

          if (!isValid) {
            this.logger.warn(` Device ${deviceId} failed authentication`);
            return;
          }

          //  Nếu xác thực thành công → lưu cache trong 1 giờ
          this.logger.log(` Device ${deviceId} authenticated`);
          const timeout = setTimeout(() => {
            this.deviceAuthCache.delete(deviceId);
            this.logger.log(` Cache expired for ${deviceId}`);
          }, 60 * 60 * 1000);

          this.deviceAuthCache.set(deviceId, timeout);
        }

        // Đến đây là thiết bị đã được xác thực
        this.logger.log(` Received from ${deviceId}: ${JSON.stringify(payload)}`);

        // Gọi service lưu dữ liệu sensor
        await this.sensorDataService.createFromMqtt(
          deviceId,
          payload
        );
      } catch (err) {
        console.error(' Error parsing MQTT message:', err.message);
      }
    });

    //  Bắt lỗi kết nối
    this.client.on('error', (err) => {
      console.error(' MQTT Error:', err.message);
    });
  }

  // Hàm publish dữ liệu lên broker 
  publish(topic: string, data: any) {
    this.client.publish(topic, JSON.stringify(data));
  }
  
}
