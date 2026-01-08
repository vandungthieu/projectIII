import { Body, Controller, Delete, Get, Param, ParseIntPipe, Post, Put, Query, UseGuards } from "@nestjs/common";
import { AdminUserService } from "./admin-user.service";
import { JwtAuthGuard } from "src/auth/guards/jwt-auth.guard";
import { RolesGuard } from "src/auth/guards/roles.guards";
import { Roles } from "src/common/decorator/roles.decorator";
import { Role } from "generated/prisma";
import { CreateUserDto } from "../dto/create-user.dto";
import { UpdateUserDto } from "../dto/update-user.dto";

@Controller('admin/users')
export class AdminUserController{
    constructor(private adminUserService : AdminUserService){}

    // create user
    @Post()
    @UseGuards(JwtAuthGuard, RolesGuard)
    @Roles(Role.Admin)
    createUser(dto: CreateUserDto){
        return this.adminUserService.createUser(dto)
    }

    //search user
    @Get('search')
    @UseGuards(JwtAuthGuard, RolesGuard)
    @Roles(Role.Admin)
    async searchUsers(@Query('keyword') keyword: string) {
        return this.adminUserService.searchUsers(keyword);
    }
    
    // get user by id
    @Get()
    @UseGuards(JwtAuthGuard, RolesGuard)
    @Roles(Role.Admin)
    getAllUser(){
        return this.adminUserService.getAllUser()
    }

    // get user by id
    @Get(':id')
    @UseGuards(JwtAuthGuard, RolesGuard)
    @Roles(Role.Admin)
    getUserById(@Param('id', ParseIntPipe) id : number){
        return this.adminUserService.getUserById((id))
    }

    // update user
    @Put(':id')
    @UseGuards(JwtAuthGuard, RolesGuard)
    @Roles(Role.Admin)
    updateUser(@Param('id', ParseIntPipe) id : number, @Body() dto: UpdateUserDto){
        return this.adminUserService.updateUser(id, dto)
    }

    // delete user
    @Delete(':id')
    @UseGuards(JwtAuthGuard, RolesGuard)
    @Roles(Role.Admin)
    deleteUser(@Param('id', ParseIntPipe) id : number){
        return this.adminUserService.deleteUser(id)
    }


}