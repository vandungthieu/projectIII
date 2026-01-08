import { IsEmail, IsNumber, IsOptional, IsPhoneNumber, IsString } from "class-validator"

export class UpdateUserDto{
        @IsString()
        @IsOptional()
        password ? : string

        @IsOptional()
        @IsEmail()
        email?: string;
    
        @IsString()
        @IsOptional()
        name ? : string
    
        @IsPhoneNumber()
        @IsOptional()
        phone? : string
    
    
}