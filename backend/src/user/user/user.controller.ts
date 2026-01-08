import { Body, Controller, Get, Param, ParseIntPipe, Patch, Put, Request, UseGuards } from "@nestjs/common";
import { UserService } from "./user.service";
import { JwtAuthGuard } from "src/auth/guards/jwt-auth.guard";
import { UpdateProfileDto } from "../dto/update-profile.dto";
import { ChangePasswordDto } from "../dto/change-password.dto";

@Controller('user')
export class UserController{
    constructor(private readonly userService : UserService){}

    // get profile
    @Get('profile')
    @UseGuards(JwtAuthGuard)
    getProfile(@Request() req){
        return this.userService.getProfile(req.user.id)
    }

    // update profile
    @Patch('profile')
    @UseGuards(JwtAuthGuard)
    updateProgfile(@Request() req,@Body() dto: UpdateProfileDto){
        return this.userService.updateProfile(req.user.id, dto)
    }

    // change password
    @Patch('change-password')
    @UseGuards(JwtAuthGuard)
    changePassword(@Request() req, @Body() dto: ChangePasswordDto){
        return this.userService.changePassword(req.user.id, dto.oldPassword, dto.newPassword)
    }

    //get my alert
    @Get('my-alert')
    @UseGuards(JwtAuthGuard)
    getMyDeviceById(@Request() req : any){
        return this.userService.getMyAlert(req.user.id)
    }


}