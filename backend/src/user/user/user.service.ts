import { BadRequestException, Injectable, NotFoundException, UnauthorizedException } from "@nestjs/common";
import { PrismaService } from "src/prisma/prisma.service";
import { UpdateProfileDto } from "../dto/update-profile.dto";
import * as bcrypt from "bcrypt"
import { FcmTokenDto } from "../dto/fcm-token.dto";

@Injectable()
export class UserService{
    constructor(private prisma: PrismaService){}

    // get profile
    async getProfile(userId: number){
        return await this.prisma.user.findUnique({
            where: {id: userId},
            select :{
                username: true,
                email: true,
                name: true,
                phone: true,
            }
        })
    }

    // update profile
    async updateProfile(userId: number, dto : UpdateProfileDto){
        console.log(dto);

        return await this.prisma.user.update({
            where:{id: userId},
            data: dto,
            select :{
                username: true,
                email: true,
                name: true,
                phone: true,
            }
        })
    }

    // change password
    async changePassword(userId: number, oldPassword: string, newPassword: string){
        const user = await this.prisma.user.findUnique({where:{id:userId}})

        if (!user) throw new BadRequestException('User not found');

        const check = await bcrypt.compare(oldPassword, user.password);
        
        if (!check) throw new UnauthorizedException('incorrect');

    
        const hashedPassword = await bcrypt.hash(newPassword, 10);

    
        await this.prisma.user.update({
            where: { id: userId },
            data: { password: hashedPassword },
        });

        return { message: 'success' };
    }

    // get my alert
    // async getMyAlert(userId: number) {
    //     const user = await this.prisma.user.findUnique({
    //         where: { id: userId },
    //     });
    
    //     if (!user) {
    //         throw new NotFoundException('Not found User');
    //     }
    
    //     // lấy device + sensorData mới nhất
    //      const alert = await this.prisma.alert.findMany({
    //         where: { userId },
    //         orderBy: { createdAt: 'desc' },
    //     });
    
    //     if (!alert || alert.length === 0) {
    //         throw new NotFoundException('not found device');
    //     }
    
    //     // merge sensorData vào response
    //     return alert
    // }

    async getMyAlert(
        userId: number,
        from?: string,
        to?: string,
        deviceId?: string,
    ) {
        // 1. Kiểm tra user tồn tại
        const user = await this.prisma.user.findUnique({
            where: { id: userId },
        });

        if (!user) {
            throw new NotFoundException('Not found User');
        }

        const fromDate = this.parseDateQuery(from, 'from');
        const toDate = this.parseDateQuery(to, 'to');
        const parsedDeviceId = this.parseDeviceId(deviceId);

        if (fromDate && toDate && fromDate >= toDate) {
            throw new BadRequestException('from must be before to');
        }

        // 2. Lấy alert + join device
        const alerts = await this.prisma.alert.findMany({
            where: {
                userId,
                ...(parsedDeviceId ? { deviceId: parsedDeviceId } : {}),
                createdAt: {
                    ...(fromDate ? { gte: fromDate } : {}),
                    ...(toDate ? { lt: toDate } : {}),
                },
            },
            orderBy: { createdAt: 'desc' },
            include: {
            device: {
                select: {
                deviceId: true,      // deviceCode (string)
                licensePlate: true,
                },
            },
            },
        });

        // 3. Map response (KHÔNG ghi đè deviceId)
        const result = alerts.map((alert) => ({
            id: alert.id,
            userId: alert.userId,
            deviceId: alert.deviceId,          // ✅ int (FK)
            message: alert.message,
            location: alert.location,
            createdAt: alert.createdAt,

            deviceCode: alert.device.deviceId, // ✅ string
            licensePlate: alert.device.licensePlate,
        }));

        return result;
    }

    private parseDateQuery(value: string | undefined, field: string): Date | undefined {
        if (!value) return undefined;

        const date = new Date(value);
        if (Number.isNaN(date.getTime())) {
            throw new BadRequestException(`${field} must be a valid ISO date`);
        }

        return date;
    }

    private parseDeviceId(value: string | undefined): number | undefined {
        if (!value) return undefined;

        const deviceId = Number(value);
        if (!Number.isInteger(deviceId) || deviceId <= 0) {
            throw new BadRequestException('deviceId must be a positive integer');
        }

        return deviceId;
    }

    async saveFcmToken(userId: number, dto: FcmTokenDto) {
        await this.prisma.fcmToken.upsert({
            where: { token: dto.token },
            create: {
                userId,
                token: dto.token,
                platform: dto.platform,
                deviceName: dto.deviceName,
            },
            update: {
                userId,
                platform: dto.platform,
                deviceName: dto.deviceName,
            },
        });

        return { message: 'success' };
    }

    async deleteFcmToken(userId: number, token: string) {
        if (!token) {
            return { message: 'success' };
        }

        await this.prisma.fcmToken.deleteMany({
            where: { userId, token },
        });

        return { message: 'success' };
    }
    




    
}
