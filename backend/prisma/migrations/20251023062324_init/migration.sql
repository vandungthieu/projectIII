/*
  Warnings:

  - You are about to drop the column `resolved` on the `Alert` table. All the data in the column will be lost.
  - You are about to drop the column `severity` on the `Alert` table. All the data in the column will be lost.
  - You are about to drop the column `type` on the `Alert` table. All the data in the column will be lost.
  - You are about to drop the column `location` on the `Device` table. All the data in the column will be lost.
  - You are about to drop the column `status` on the `Device` table. All the data in the column will be lost.
  - A unique constraint covering the columns `[deviceKey]` on the table `Device` will be added. If there are existing duplicate values, this will fail.
  - Added the required column `deviceKey` to the `Device` table without a default value. This is not possible if the table is not empty.

*/
-- AlterTable
ALTER TABLE "Alert" DROP COLUMN "resolved",
DROP COLUMN "severity",
DROP COLUMN "type";

-- AlterTable
ALTER TABLE "Device" DROP COLUMN "location",
DROP COLUMN "status",
ADD COLUMN     "activatedAt" TIMESTAMP(3),
ADD COLUMN     "deviceKey" TEXT NOT NULL,
ADD COLUMN     "isActivated" BOOLEAN NOT NULL DEFAULT false;

-- CreateTable
CREATE TABLE "SensorData" (
    "id" SERIAL NOT NULL,
    "deviceId" INTEGER NOT NULL,
    "location" JSONB,
    "speed" DOUBLE PRECISION,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "SensorData_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "Device_deviceKey_key" ON "Device"("deviceKey");

-- AddForeignKey
ALTER TABLE "SensorData" ADD CONSTRAINT "SensorData_deviceId_fkey" FOREIGN KEY ("deviceId") REFERENCES "Device"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
