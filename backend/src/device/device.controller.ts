import { Body, Controller, Get, Param,Request, ParseIntPipe, Patch, Post, Query, UseGuards, Delete } from "@nestjs/common";
import { DeviceService } from "./device.service";
import { JwtAuthGuard } from "src/auth/guards/jwt-auth.guard";
import { RolesGuard } from "src/auth/guards/roles.guards";
import { Roles } from "src/common/decorator/roles.decorator";
import { Role } from "generated/prisma";
import { CreateDeviceDto } from "./dto/create-device.dto";
import { UpdateDeviceDto } from "./dto/update-device.dto";

@Controller('devices')
export class DeviceController{
    constructor (private deviceService: DeviceService){}


    //----USER ROUTE----

    // get my device
    @Get('my-device')
    @UseGuards(JwtAuthGuard)
    getMyDevice(@Request() req : any){
        return this.deviceService.getMyDevice(req.user.id)
    }

    // get my device by id
    @Get('my-device/:id')
    @UseGuards(JwtAuthGuard)
    getMyDeviceById(@Param('id', ParseIntPipe) id : number, @Request() req : any){
        return this.deviceService.getMyDeviceById(id, req.user.id)
    }
    

    // activate device
    @Post('active')
    @UseGuards(JwtAuthGuard)
    activeteDevice(
        @Body('deviceId') deviceId: string,
        @Body('deviceKey') deviceKey: string,
        @Request() req : any
    ){
        return this.deviceService.activeDevice(deviceId, deviceKey, req.user.id)
    }

    // update my device
    @Patch('my-device/:id')
    @UseGuards(JwtAuthGuard)
    updateMyDevice(
        @Param('id', ParseIntPipe) id : number , 
        @Body() dto : UpdateDeviceDto, 
        @Request() req : any){
            return this.deviceService.updateMyDevice(id, dto, req.user.id)
    }

    // delete my device
    @Delete('my-device/:id')
    @UseGuards(JwtAuthGuard)
    deleteMyDevice(@Param('id', ParseIntPipe) id : number, @Request() req : any){
        return this.deviceService.deleteMyDevice(id, req.user.id)
    }

    /// -----ADMIN-----

    // get all device
    @Get()
    @UseGuards(JwtAuthGuard, RolesGuard)
    @Roles(Role.Admin)
    getAllDevice(){
        return this.deviceService.getAllDevice()
    }


    // create device
    @Post()
    @UseGuards(JwtAuthGuard, RolesGuard)
    @Roles(Role.Admin)
    createDevice(@Body() dto : CreateDeviceDto){
        return this.deviceService.createDevice(dto)
    }

    //search device 
    @Get('search')
    @UseGuards(JwtAuthGuard, RolesGuard)
    @Roles(Role.Admin)
    searchDevice(@Query('keyword') keyword: string) {
        return this.deviceService.searchDevice(keyword);
    }

    //get device by id
    @Get(':id')
    @UseGuards(JwtAuthGuard, RolesGuard)
    @Roles(Role.Admin)
    getDeviceById(@Param('id', ParseIntPipe) id: number,){
        return this.deviceService.getDeviceById(id)
    }

      // update device
    @Patch('my-device/:id')
    @UseGuards(JwtAuthGuard, RolesGuard)
    @Roles(Role.Admin)
    updateDevice(@Param('id', ParseIntPipe) id: number, @Body() dto: UpdateDeviceDto ){
        return this.deviceService.updateDevice(id, dto)
    }

    // delete device
    @Delete(':id')
    @UseGuards(JwtAuthGuard, RolesGuard)
    @Roles(Role.Admin)
    deleteDevice(@Param('id', ParseIntPipe) id : number ){
        return this.deviceService.deleteDevice(id)
    }

    // get alert by device
    @Get('alert/:id')
    @UseGuards(JwtAuthGuard)
    getAlertByDevice(@Param('id', ParseIntPipe) id : number, @Request() req : any){
        return this.deviceService.getAlertByDevice(id, req.user.id)
    }

     // get sensorData by device
    @Get('sensor/:id')
    @UseGuards(JwtAuthGuard)
    getSensorDataByDevice(
        @Param('id', ParseIntPipe) id : number,
        @Request() req : any,
        @Query('from') from?: string,
        @Query('to') to?: string,
    ){
        return this.deviceService.getSensorDataByDevice(id, req.user.id, from, to)
    }

    // get filtered GPS journey and travelled distance by device
    @Get('journey/:id')
    @UseGuards(JwtAuthGuard)
    getJourneyByDevice(
        @Param('id', ParseIntPipe) id: number,
        @Request() req: any,
        @Query('from') from?: string,
        @Query('to') to?: string,
    ) {
        return this.deviceService.getJourneyByDevice(id, req.user.id, from, to)
    }

}
