import { IsEmail, IsNotEmpty, IsNumber, IsOptional, IsPhoneNumber, IsString, MinLength } from "class-validator";

export class RegisterDto{
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

}

