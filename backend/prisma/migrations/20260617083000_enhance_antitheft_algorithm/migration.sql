ALTER TABLE "Device"
ADD COLUMN     "parkedLocation" JSONB,
ADD COLUMN     "suspiciousCount" INTEGER NOT NULL DEFAULT 0;
