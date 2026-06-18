import { Module } from "@nestjs/common";
import { PrismaModule } from "src/prisma/prisma.module";
import { FirebaseMessagingService } from "./firebase-messaging.service";

@Module({
  imports: [PrismaModule],
  providers: [FirebaseMessagingService],
  exports: [FirebaseMessagingService],
})
export class FirebaseModule {}
