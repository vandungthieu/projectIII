import { Body, Controller, Post, Req, UseGuards } from "@nestjs/common";
import { AuthService } from "./auth.service";
import { RegisterDto } from "./dto/register.dto";
import { LocalAuthGuard } from "./guards/local-auth.guard";

@Controller('auth')
export class AuthController {
    constructor(private readonly authService : AuthService){}

    // đăng ký
    @Post('register')
    register(@Body() dto: RegisterDto){
        return this.authService.register(dto);
    }

    // đăng nhập trả về token
    @Post('login')
    @UseGuards(LocalAuthGuard)
    login(@Req() req) {
        return this.authService.createToken(req.user);
    }

}