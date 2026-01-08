import { IsBoolean, IsEnum, IsOptional, IsString } from "class-validator";
import { VehicleStatus } from "generated/prisma";

export class UpdateDeviceDto{
    @IsString()
    @IsOptional()
    licensePlate ? : string

    @IsOptional()
    @IsBoolean()
    isActivated ? : boolean

    @IsOptional()
    @IsEnum(VehicleStatus)
    vehicleStatus ? : VehicleStatus

}