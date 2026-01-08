import { IsEmail, IsEnum, IsNotEmpty, IsNumber, IsOptional, IsPhoneNumber, IsString, MinLength } from "class-validator";
import { Role } from "generated/prisma";

export class CreateUserDto{
    @IsString()
    @IsNotEmpty()
    username: string

    @IsEmail()
    @IsNotEmpty()
    email : string

    @IsString()
    @IsNotEmpty()
    @MinLength(6)
    password : string

    @IsString()
    @IsOptional()
    name ? : string

    @IsPhoneNumber()
    @IsOptional()
    phone ? : string

    @IsEnum(Role)
    @IsOptional()
    role ? : Role
}

