import { IsOptional, IsString } from "class-validator";

export class FcmTokenDto {
  @IsString()
  token: string;

  @IsOptional()
  @IsString()
  platform?: string;

  @IsOptional()
  @IsString()
  deviceName?: string;
}
