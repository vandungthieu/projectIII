import { BadRequestException, ConflictException, ForbiddenException, Injectable, NotFoundException, UnauthorizedException } from "@nestjs/common";
import { PrismaService } from "src/prisma/prisma.service";
import { CreateDeviceDto } from "./dto/create-device.dto";
import { randomBytes } from "crypto";
import { Prisma } from "@prisma/client";
import { UpdateDeviceDto } from "./dto/update-device.dto";
import { haversineDistanceMeters, normalizeLocation } from "src/common/utils/location.util";

@Injectable()
export class DeviceService{
    constructor(
        private prisma: PrismaService,
        
    ){}

    //-----ADMIN-----

    // create device
    async createDevice(dto: CreateDeviceDto){
        const existingDevice = await this.prisma.device.findUnique({
            where: {deviceId: dto.deviceId}
        })

        if(existingDevice){
            throw new BadRequestException('Device ID already exists')
        }

        const deviceKey = randomBytes(16).toString('hex')

        return this.prisma.device.create({
            data:{

                deviceId: dto.deviceId,
                deviceKey: deviceKey
                
            }as Prisma.DeviceUncheckedCreateInput,
        });
    }

    // get all device
    async getAllDevice(){
        const device = await this.prisma.device.findMany()
        if(!device){
            throw new NotFoundException('not found device')
        }
        return device
    }

    // get device by id
    async getDeviceById(id: number){
        const device = await this.prisma.device.findUnique({where:{id}})
        if(!device){
            throw new NotFoundException(`not found device: ${id}`)
        }
        return device
    }

    // update device
    async updateDevice(id: number, dto: UpdateDeviceDto){
        const device = await this.prisma.device.findUnique({where:{id}})
        if(!device){
            throw new NotFoundException(`not found device: ${id}`)
        }
        return await this.prisma.device.update({
            where: {id},
            data: dto
        })
    }


    // search device
    async searchDevice(keyword: string) {
        if (!keyword || keyword.trim() === '') {
            return this.prisma.device.findMany({
                include: { user: true }, 
            });
        }

        return this.prisma.device.findMany({
            where: {
                OR: [
                { deviceId: { contains: keyword, mode: 'insensitive' } },
                {
                    user: {
                    OR: [
                        { username: { contains: keyword, mode: 'insensitive' } },
                    ],
                    },
                },
                ],
            },
            include: { user: true }, 
        });
    }

    // delete device
    async deleteDevice(id: number){
        const device = await this.prisma.device.findUnique({where:{id}})
        if(!device){
            throw new NotFoundException(`not found device: ${id}`)
        }

        await this.prisma.device.update({
            where: { id },
            data: { userId: null },
        });
        
        return {message : 'Xóa thành công'}
    }

    // xác thực thiết bị 
    async validateDevice(deviceId: string, deviceKey: string): Promise<boolean> {
        const device = await this.prisma.device.findUnique({ where: { deviceId } });
        if (!device) return false;
        return device.deviceKey === deviceKey;
    }


    // ----- USER ------

    //get my device
    async getMyDevice(userId: number) {
        const user = await this.prisma.user.findUnique({
            where: { id: userId },
        });

        if (!user) {
            throw new NotFoundException('Not found User');
        }

        // lấy device + sensorData mới nhất
        const devices = await this.prisma.device.findMany({
            where: { userId },
            include: {
                sensorData: {
                    orderBy: { createdAt: 'desc' },
                    take: 1,
                },
            },
        });

        if (!devices || devices.length === 0) {
            throw new NotFoundException('not found device');
        }

        // merge sensorData vào response
        return devices.map(d => ({
            ...d,
            location: d.sensorData[0]?.location ?? null,
            speed: d.sensorData[0]?.speed ?? null,
        }));
    }


    //get my device by id
    async getMyDeviceById(deviceId : number , userId : number){
        const device = await this.prisma.device.findUnique({where:{id:deviceId}})
        if(!device){
            throw new NotFoundException('not found device');
        }

        if(device.userId !== userId){
            throw new ForbiddenException('Bạn không có quyền truy cập thiết bị này')
        }

        return device
    }

    // active device
   async activeDevice(deviceId: string, deviceKey: string, userId: number) {
    // Tìm device theo ID
    const device = await this.prisma.device.findUnique({
        where: { deviceId },
    });

    // 1. Sai deviceId hoặc deviceKey → 400 BadRequest
    if (!device || device.deviceKey !== deviceKey) {
        throw new BadRequestException('Mã thiết bị hoặc khóa thiết bị không chính xác');
    }

    // 2. Device đã được kích hoạt → 409 Conflict
    if (device.userId) {
        throw new ConflictException('Thiết bị này đã được kích hoạt');
    }

    // 3. Cập nhật + kích hoạt
    await this.prisma.device.update({
        where: { deviceId },
        data: {
        userId,
        isActivated: true,
        activatedAt: new Date(),
        },
    });

    // 4. Trả kết quả chuẩn
    return {
        success: true,
        message: 'Kích hoạt thiết bị thành công',
        deviceId,
    };
}


    // update my device
    async updateMyDevice(id: number, dto: UpdateDeviceDto, userId: number){
        const device = await this.prisma.device.findUnique({where:{id}})
        if(!device){
            throw new NotFoundException(`not found device: ${id}`)
        }

        if(device.userId !== userId ){
            throw new ForbiddenException('You are not allowed to update this device');
        }

        const updateData: any = {
            ...dto,
        };

        if (dto.vehicleStatus === 'Parked') {
            const parkedLocation = await this.getLatestSensorLocation(id);
            if (parkedLocation) {
                updateData.parkedLocation = parkedLocation;
            } else if (device.parkedLocation) {
                updateData.parkedLocation = device.parkedLocation;
            }
            updateData.suspiciousCount = 0;
            updateData.lastSpeedAlert = false;
        }

        if (dto.vehicleStatus && dto.vehicleStatus !== 'Parked') {
            updateData.suspiciousCount = 0;
            updateData.lastSpeedAlert = false;
        }

        await this.prisma.device.update({
            where: {id},
            data: updateData
        })
        return {message:'Suscess'}
    }


    // delete my device
    async deleteMyDevice(id: number, userId: number){
        const device = await this.prisma.device.findUnique({where:{id}})
        if(!device){
            throw new NotFoundException(`not found device: ${id}`)
        }

        if(device.userId !== userId){
            throw new ForbiddenException('Bạn không có quyền truy cập thiết bị này')
        }

        await this.prisma.device.update({
            where: { id },
            data: { userId: null },
        });
        
        return {message : 'Xóa thành công'}
    }

    private async getLatestSensorLocation(deviceId: number) {
        const latest = await this.prisma.sensorData.findFirst({
            where: { deviceId },
            orderBy: { createdAt: 'desc' },
            select: { location: true },
        });

        if (!latest?.location) {
            return null;
        }

        return normalizeLocation(latest.location);
    }

    // get alert by device
    async getAlertByDevice(id: number, userId: number){
        const device = await this.prisma.device.findUnique({where:{id}})

        if(!device){
            throw new NotFoundException(`not found device: ${id}`)
        }

        if(device.userId !== userId){
            throw new ForbiddenException('Bạn không có quyền truy cập thiết bị này')
        }

        return this.prisma.alert.findMany({
            where:{deviceId : id}
        })
    }

    //get sensorData by device
    async getSensorDataByDevice(
        id: number,
        userId: number,
        from?: string,
        to?: string,
    ){
        const device = await this.prisma.device.findUnique({where:{id}})

        if(!device){
            throw new NotFoundException(`not found device: ${id}`)
        }

        if(device.userId !== userId){
            throw new ForbiddenException('Bạn không có quyền truy cập thiết bị này')
        }

        const fromDate = this.parseJourneyDate(from, 'from')
        const toDate = this.parseJourneyDate(to, 'to')

        if (fromDate && toDate && fromDate >= toDate) {
            throw new BadRequestException('from must be before to')
        }

        return this.prisma.sensorData.findMany({
            where:{
                deviceId : id,
                createdAt: {
                    ...(fromDate ? { gte: fromDate } : {}),
                    ...(toDate ? { lt: toDate } : {}),
                },
            },
            orderBy: { createdAt: 'desc' },
        })
    }

    async getJourneyByDevice(
        id: number,
        userId: number,
        from?: string,
        to?: string,
    ) {
        const device = await this.prisma.device.findUnique({ where: { id } })

        if (!device) {
            throw new NotFoundException(`not found device: ${id}`)
        }

        if (device.userId !== userId) {
            throw new ForbiddenException('Ban khong co quyen truy cap thiet bi nay')
        }

        const fromDate = this.parseJourneyDate(from, 'from')
        const toDate = this.parseJourneyDate(to, 'to')

        if (fromDate && toDate && fromDate > toDate) {
            throw new BadRequestException('from must be before to')
        }

        const records = await this.prisma.sensorData.findMany({
            where: {
                deviceId: id,
                createdAt: {
                    ...(fromDate ? { gte: fromDate } : {}),
                    ...(toDate ? { lte: toDate } : {}),
                },
            },
            orderBy: { createdAt: 'asc' },
            select: {
                id: true,
                location: true,
                speed: true,
                createdAt: true,
            },
        })

        const points: Array<{
            id: number
            lat: number
            lng: number
            speed: number | null
            createdAt: Date
        }> = []
        let distanceMeters = 0
        let ignoredPointCount = 0

        for (const record of records) {
            const location = normalizeLocation(record.location)
            if (!location || Math.abs(location.lat) > 90 || Math.abs(location.lng) > 180) {
                ignoredPointCount++
                continue
            }

            const point = { ...location, id: record.id, speed: record.speed, createdAt: record.createdAt }
            const previous = points.at(-1)

            if (previous) {
                const segmentMeters = haversineDistanceMeters(previous, point)
                const elapsedSeconds = (point.createdAt.getTime() - previous.createdAt.getTime()) / 1000
                const impliedSpeedKmh = elapsedSeconds > 0
                    ? (segmentMeters / elapsedSeconds) * 3.6
                    : 0

                // Ignore stationary GPS drift and impossible jumps.
                if (segmentMeters < 3 || (elapsedSeconds > 0 && impliedSpeedKmh > 200)) {
                    ignoredPointCount++
                    continue
                }

                distanceMeters += segmentMeters
            }

            points.push(point)
        }

        return {
            points,
            distanceMeters: Math.round(distanceMeters),
            rawPointCount: records.length,
            ignoredPointCount,
        }
    }

    private parseJourneyDate(value: string | undefined, field: string): Date | undefined {
        if (!value) return undefined

        const date = new Date(value)
        if (Number.isNaN(date.getTime())) {
            throw new BadRequestException(`${field} must be a valid ISO date`)
        }

        return date
    }

}
