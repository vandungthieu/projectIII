import { Module } from "@nestjs/common";
import { AuthService } from "./auth.service";
import { AuthController } from "./auth.controller";
import { PrismaModule } from "src/prisma/prisma.module";
import { ConfigModule, ConfigService } from "@nestjs/config";
import { JwtModule } from "@nestjs/jwt";
import { LocalStrategy } from "./strategies/local.strategies";
import { JwtStrategy } from "./strategies/jwt.strategies";

@Module({
    imports:[PrismaModule,
        ConfigModule.forRoot(),
        JwtModule.registerAsync({
            imports:[ConfigModule],
            useFactory: async(configService: ConfigService)=>({
                secret: configService.get<string>('JWT_SECRET'),
                signOptions: {} //{expiresIn: '12h'}
            }),
            inject :[ConfigService]
        })
    ],
    providers:[AuthService,LocalStrategy,JwtStrategy],
    controllers:[AuthController],
    exports:[AuthService]
})
export class AuthModule{}