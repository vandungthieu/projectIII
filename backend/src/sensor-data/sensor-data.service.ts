import { Injectable } from "@nestjs/common";
import { PrismaService } from "src/prisma/prisma.service";
import { SensorDataGateway } from "./sensor-data.gateway";

@Injectable()
export class SensorDataService{
    constructor(
        private prisma : PrismaService,
        private gateway: SensorDataGateway,
    ){}

    // xử lý dữ liệu từ mqtt
    async createFromMqtt(deviceId : string, payload: any) {
        const device = await this.prisma.device.findUnique({
            where: { deviceId },
        });

        if (!device) {
            console.warn(`Thiết bị ${deviceId} không tồn tại`);
            return;
        }

         //  Kiểm tra trạng thái kích hoạt
        if (!device.isActivated) {
            console.warn(` Thiết bị ${deviceId} đang bị khóa, bỏ qua dữ liệu`);
            return;
        }
          
        // Cập nhật thời gian "lastseen"
        await this.prisma.device.update({
            where: { id: device.id },
            data: { lastSeen: new Date() },
        });

        // lưu dữ liệu 
        const sensor = await this.prisma.sensorData.create({
            data: {
                deviceId: device.id, 
                speed: payload.speed,
                location: payload.location,
            },
        });

        console.log(`Lưu dữ liệu thành công cho device: ${deviceId}`);

        // Gọi hàm kiểm tra cảnh báo
        await this.checkAndCreateAlert(device, payload.speed, payload.location);

        //  Gửi dữ liệu real-time cho client
        // this.gateway.sendSensorData({
        //     deviceId: deviceId,
        //     speed: payload.speed,
        //     location: payload.location,
        //     createdAt: new Date(),
        // });

       if (device.userId) {
        this.gateway.sendDataToUser(device.userId, {
            id: sensor.id,
            deviceId: sensor.deviceId,   // ✅ INT
            speed: sensor.speed,
            location: sensor.location,
            createdAt: sensor.createdAt,
        });
        } else {
            console.warn(`⚠️ Device ${deviceId} has no user assigned — skipping WebSocket send.`);
        }
    }

    
    private async checkAndCreateAlert(device: any, speed: number, location: any) {
    const exceedSpeed = device.vehicleStatus === "Parked" && speed > 10;

    // Nếu không vượt quá 10 km/h thì reset trạng thái
    if (!exceedSpeed) {
        if (device.lastSpeedAlert) {
            await this.prisma.device.update({
                where: { id: device.id },
                data: { lastSpeedAlert: false },
            });
        }
        return;
    }

    // Nếu đã gửi cảnh báo rồi → không gửi nữa
    if (device.lastSpeedAlert) {
        return;
    }

    // Đánh dấu đã gửi cảnh báo
    await this.prisma.device.update({
        where: { id: device.id },
        data: { lastSpeedAlert: true },
    });

    const alert = await this.prisma.alert.create({
        data: {
            deviceId: device.id,
            userId: device.userId,
            message: `Xe đang di chuyển với tốc độ (${speed} km/h)!`,
            location,
        },
    });


        this.gateway.sendAlertToUser(device.userId, {
            id: alert.id,
            deviceId: alert.deviceId,            
            deviceCode: device.deviceId,          
            licensePlate: device.licensePlate,    
            userId: alert.userId,
            message: alert.message,
            location: alert.location,
            createdAt: alert.createdAt,
        });
    }

}

// {
// "deviceId": "device3",
//   "deviceKey": "413d6b176257eaca25077811bca3217d",
//   "speed": 30,
//   "location": {
//     "lat": 10.76,
//     "lng": 106.66
//   }
// }
