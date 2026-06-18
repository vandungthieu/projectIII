import { Module } from "@nestjs/common";
import { PrismaModule } from "src/prisma/prisma.module";
import { AdminUserController } from "./admin/admin-user.controller";
import { UserController } from "./user/user.controller";
import { AdminUserService } from "./admin/admin-user.service";
import { UserService } from "./user/user.service";


@Module({
    imports:[PrismaModule],
    controllers:[AdminUserController, UserController],
    providers:[AdminUserService, UserService],
    exports:[UserService]
})
export class UserModule{}
