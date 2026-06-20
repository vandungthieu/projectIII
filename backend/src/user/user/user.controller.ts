import { Body, Controller, Delete, Get, Patch, Post, Query, Request, UseGuards } from "@nestjs/common";
import { UserService } from "./user.service";
import { JwtAuthGuard } from "src/auth/guards/jwt-auth.guard";
import { UpdateProfileDto } from "../dto/update-profile.dto";
import { ChangePasswordDto } from "../dto/change-password.dto";
import { FcmTokenDto } from "../dto/fcm-token.dto";

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
    getMyDeviceById(
        @Request() req : any,
        @Query('from') from?: string,
        @Query('to') to?: string,
        @Query('deviceId') deviceId?: string,
    ){
        return this.userService.getMyAlert(req.user.id, from, to, deviceId)
    }

    @Post('fcm-token')
    @UseGuards(JwtAuthGuard)
    saveFcmToken(@Request() req: any, @Body() dto: FcmTokenDto) {
        return this.userService.saveFcmToken(req.user.id, dto);
    }

    @Delete('fcm-token')
    @UseGuards(JwtAuthGuard)
    deleteFcmToken(@Request() req: any, @Body('token') token: string) {
        return this.userService.deleteFcmToken(req.user.id, token);
    }

}
