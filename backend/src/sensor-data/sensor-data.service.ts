import { Injectable } from "@nestjs/common";
import { PrismaService } from "src/prisma/prisma.service";
import { SensorDataGateway } from "./sensor-data.gateway";
import {
  haversineDistanceMeters,
  normalizeLocation,
} from "src/common/utils/location.util";
import { FirebaseMessagingService } from "src/firebase/firebase-messaging.service";

const SPEED_THRESHOLD = 10;
const DISTANCE_THRESHOLD_METERS = 50;
const SEVERE_DISTANCE_THRESHOLD_METERS = 100;
const ALERT_STREAK_THRESHOLD = 2;
const SEVERE_STREAK_THRESHOLD = 3;

@Injectable()
export class SensorDataService {
  constructor(
    private prisma: PrismaService,
    private gateway: SensorDataGateway,
    private firebaseMessaging: FirebaseMessagingService,
  ) {}

  async createFromMqtt(deviceId: string, payload: any) {
    const device = await this.prisma.device.findUnique({
      where: { deviceId },
    });

    if (!device) {
      console.warn(`Device ${deviceId} does not exist`);
      return;
    }

    if (!device.isActivated) {
      console.warn(`Device ${deviceId} is not activated, skipping data`);
      return;
    }

    const speed = this.normalizeSpeed(payload.speed);
    const normalizedLocation = normalizeLocation(payload.location);
    const sensorLocation = normalizedLocation ?? payload.location ?? null;

    await this.prisma.device.update({
      where: { id: device.id },
      data: { lastSeen: new Date() },
    });

    const sensor = await this.prisma.sensorData.create({
      data: {
        deviceId: device.id,
        speed,
        location: sensorLocation,
      },
    });

    await this.evaluateVehicleRisk(device, speed ?? 0, sensorLocation);

    if (device.userId) {
      this.gateway.sendDataToUser(device.userId, {
        id: sensor.id,
        deviceId: sensor.deviceId,
        speed: sensor.speed,
        location: sensor.location,
        createdAt: sensor.createdAt,
      });
    }
  }

  private normalizeSpeed(speed: unknown): number | null {
    if (typeof speed === "number" && Number.isFinite(speed)) {
      return speed;
    }
    if (typeof speed === "string") {
      const parsed = Number(speed);
      if (Number.isFinite(parsed)) {
        return parsed;
      }
    }
    return null;
  }

  private async evaluateVehicleRisk(
    device: any,
    speed: number,
    location: any,
  ) {
    const currentLocation = normalizeLocation(location);
    const parkedLocation = normalizeLocation(device.parkedLocation);
    const isParked = device.vehicleStatus === "Parked";

    if (!isParked) {
      if (device.suspiciousCount !== 0 || device.lastSpeedAlert) {
        await this.prisma.device.update({
          where: { id: device.id },
          data: {
            suspiciousCount: 0,
            lastSpeedAlert: false,
          },
        });
      }
      return;
    }

    if (!parkedLocation && currentLocation && speed <= SPEED_THRESHOLD) {
      await this.prisma.device.update({
        where: { id: device.id },
        data: { parkedLocation: currentLocation },
      });
      return;
    }

    const speedAnomaly = speed > SPEED_THRESHOLD;
    const distanceMeters =
      parkedLocation && currentLocation
        ? haversineDistanceMeters(parkedLocation, currentLocation)
        : null;
    const distanceAnomaly =
      distanceMeters !== null && distanceMeters > DISTANCE_THRESHOLD_METERS;
    const severeDistance =
      distanceMeters !== null &&
      distanceMeters > SEVERE_DISTANCE_THRESHOLD_METERS;

    const suspicious = speedAnomaly || distanceAnomaly;

    if (!suspicious) {
      if (device.suspiciousCount !== 0 || device.lastSpeedAlert) {
        await this.prisma.device.update({
          where: { id: device.id },
          data: {
            suspiciousCount: 0,
            lastSpeedAlert: false,
          },
        });
      }
      return;
    }

    const nextSuspiciousCount = (device.suspiciousCount ?? 0) + 1;

    if (nextSuspiciousCount < ALERT_STREAK_THRESHOLD) {
      await this.prisma.device.update({
        where: { id: device.id },
        data: { suspiciousCount: nextSuspiciousCount },
      });
      return;
    }

    if (device.lastSpeedAlert) {
      await this.prisma.device.update({
        where: { id: device.id },
        data: { suspiciousCount: nextSuspiciousCount },
      });
      return;
    }

    const shouldMarkStolen =
      severeDistance ||
      nextSuspiciousCount >= SEVERE_STREAK_THRESHOLD ||
      (speedAnomaly && distanceAnomaly);

    const messageParts: string[] = [];
    if (speedAnomaly) {
      messageParts.push(`speed ${speed} km/h over threshold`);
    }
    if (distanceAnomaly && distanceMeters !== null) {
      messageParts.push(
        `moved ${distanceMeters.toFixed(0)} m away from parked location`,
      );
    }

    const alertMessage = messageParts.length
      ? `Suspicious vehicle behavior: ${messageParts.join(" and ")}.`
      : `Vehicle is moving abnormally at ${speed} km/h!`;

    await this.prisma.device.update({
      where: { id: device.id },
      data: {
        suspiciousCount: nextSuspiciousCount,
        lastSpeedAlert: true,
        ...(shouldMarkStolen ? { vehicleStatus: "Stolen" } : {}),
      },
    });

    const alert = await this.prisma.alert.create({
      data: {
        deviceId: device.id,
        userId: device.userId,
        message: alertMessage,
        location: currentLocation ?? location,
      },
    });

    if (device.userId) {
      this.gateway.sendAlertToUser(device.userId, {
        id: alert.id,
        deviceId: alert.deviceId,
        deviceCode: device.deviceId,
        licensePlate: device.licensePlate,
        userId: alert.userId,
        message: alert.message,
        location: alert.location,
        createdAt: alert.createdAt,
        severity: shouldMarkStolen ? "high" : "medium",
        speed,
        distanceMeters,
        vehicleStatus: shouldMarkStolen ? "Stolen" : "Parked",
      });

      await this.firebaseMessaging.sendToUser(device.userId, {
        title: shouldMarkStolen ? "Canh bao khan cap" : "Canh bao moi",
        body: `${device.licensePlate ?? device.deviceId}: ${alert.message}`,
        data: {
          type: "alert",
          alertId: alert.id,
          deviceId: alert.deviceId,
          deviceCode: device.deviceId,
          severity: shouldMarkStolen ? "high" : "medium",
          vehicleStatus: shouldMarkStolen ? "Stolen" : "Parked",
        },
      });
    }
  }
}
