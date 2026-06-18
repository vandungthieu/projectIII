import { Module } from "@nestjs/common";
import { PrismaModule } from "src/prisma/prisma.module";
import { SensorDataController } from "./sensor-data.controller";
import { SensorDataService } from "./sensor-data.service";
import { SensorDataGateway } from "./sensor-data.gateway";
import { FirebaseModule } from "src/firebase/firebase.module";

@Module({
    imports:[PrismaModule, FirebaseModule],
    controllers:[SensorDataController],
    providers:[SensorDataService, SensorDataGateway],
    exports:[SensorDataService]
})
export class SensorDataModule{}
