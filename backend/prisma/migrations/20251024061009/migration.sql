/*
  Warnings:

  - The `vehicleStatus` column on the `Device` table would be dropped and recreated. This will lead to data loss if there is data in the column.

*/
-- CreateEnum
CREATE TYPE "Role" AS ENUM ('User', 'Admin');

-- CreateEnum
CREATE TYPE "VehicleStatus" AS ENUM ('Parked', 'Moving', 'Stolen');

-- DropForeignKey
ALTER TABLE "public"."Device" DROP CONSTRAINT "Device_userId_fkey";

-- AlterTable
ALTER TABLE "Device" ALTER COLUMN "userId" DROP NOT NULL,
DROP COLUMN "vehicleStatus",
ADD COLUMN     "vehicleStatus" "VehicleStatus" NOT NULL DEFAULT 'Parked';

-- AlterTable
ALTER TABLE "User" ADD COLUMN     "role" "Role" NOT NULL DEFAULT 'User',
ALTER COLUMN "updatedAt" SET DEFAULT CURRENT_TIMESTAMP;

-- AddForeignKey
ALTER TABLE "Device" ADD CONSTRAINT "Device_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;
