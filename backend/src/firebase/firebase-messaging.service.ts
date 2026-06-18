import { Injectable, Logger } from "@nestjs/common";
import { PrismaService } from "src/prisma/prisma.service";
import { cert, getApps, initializeApp } from "firebase-admin/app";
import { getMessaging } from "firebase-admin/messaging";
import * as fs from "fs";

type PushPayload = {
  title: string;
  body: string;
  data?: Record<string, string | number | boolean | null | undefined>;
};

@Injectable()
export class FirebaseMessagingService {
  private readonly logger = new Logger(FirebaseMessagingService.name);
  private initialized = false;
  private disabledReason: string | null = null;

  constructor(private readonly prisma: PrismaService) {}

  async sendToUser(userId: number, payload: PushPayload) {
    if (!this.ensureInitialized()) return;

    const tokens = await this.prisma.fcmToken.findMany({
      where: { userId },
      select: { token: true },
    });

    if (tokens.length === 0) return;

    const response = await getMessaging().sendEachForMulticast({
      tokens: tokens.map((item) => item.token),
      notification: {
        title: payload.title,
        body: payload.body,
      },
      data: this.stringifyData(payload.data ?? {}),
      android: {
        priority: "high",
        notification: {
          channelId: "security_alerts",
          priority: "high",
          sound: "default",
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
          },
        },
      },
    });

    const invalidTokens = response.responses
      .map((result, index) => ({ result, token: tokens[index].token }))
      .filter(({ result }) => {
        const code = result.error?.code;
        return (
          code === "messaging/invalid-registration-token" ||
          code === "messaging/registration-token-not-registered"
        );
      })
      .map(({ token }) => token);

    if (invalidTokens.length > 0) {
      await this.prisma.fcmToken.deleteMany({
        where: { token: { in: invalidTokens } },
      });
    }

    if (response.failureCount > invalidTokens.length) {
      this.logger.warn(
        `FCM sent with ${response.failureCount} failures for user ${userId}`,
      );
    }
  }

  private ensureInitialized(): boolean {
    if (this.initialized || getApps().length > 0) {
      this.initialized = true;
      return true;
    }

    try {
      const serviceAccount = this.readServiceAccount();
      if (!serviceAccount) {
        this.disabledReason ??= "Firebase service account is not configured";
        this.logger.warn(this.disabledReason);
        return false;
      }

      initializeApp({
        credential: cert(serviceAccount),
      });
      this.initialized = true;
      return true;
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      this.disabledReason = `Firebase initialization failed: ${message}`;
      this.logger.warn(this.disabledReason);
      return false;
    }
  }

  private readServiceAccount() {
    const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH;
    if (serviceAccountPath && fs.existsSync(serviceAccountPath)) {
      return JSON.parse(fs.readFileSync(serviceAccountPath, "utf8"));
    }

    const projectId = process.env.FIREBASE_PROJECT_ID;
    const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
    const privateKey = process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, "\n");

    if (projectId && clientEmail && privateKey) {
      return {
        projectId,
        clientEmail,
        privateKey,
      };
    }

    return null;
  }

  private stringifyData(data: PushPayload["data"]): Record<string, string> {
    return Object.fromEntries(
      Object.entries(data ?? {})
        .filter(([, value]) => value !== undefined && value !== null)
        .map(([key, value]) => [key, String(value)]),
    );
  }
}
