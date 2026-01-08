import { ConflictException, Injectable, NotFoundException } from "@nestjs/common";
import { PrismaService } from "src/prisma/prisma.service";
import { UpdateUserDto } from "../dto/update-user.dto";
import * as bcrypt from "bcrypt"
import { CreateUserDto } from "../dto/create-user.dto";
import { Role } from "generated/prisma";

@Injectable()
export class AdminUserService{
    constructor(private readonly prisma: PrismaService){}

    // create user
    async createUser(dto: CreateUserDto){
        const existingUser = await this.prisma.user.findUnique({where: {username:dto.username}})
            if(existingUser){
                throw new ConflictException("Username already exists");
            }

            const hasedPassword = await bcrypt.hash(dto.password,10)
            return await this.prisma.user.create({
                data: {
                    ...dto,
                    password: hasedPassword
                }
        })
    }

    //get user
    async getAllUser(){
        return await this.prisma.user.findMany()
    }

    // get user by id
    async getUserById(id:number){
        const user = await this.prisma.user.findUnique({
            where:{id},
        })

       if(!user){
            throw new NotFoundException(`not found user: ${id}`)
       }
       return user
      
    }
    
    // update user
    async updateUser(id: number, dto : UpdateUserDto){
        const user = await this.prisma.user.findUnique({
            where:{id}
        })

        if(!user){
            throw new NotFoundException(`Not found user: ${id}`)
        }
        return await this.prisma.user.update({
            where:{id},
            data:dto
        })
    }

    //delete user
    async deleteUser(id: number){
        const user = await this.prisma.user.findUnique({
            where:{id}
        })

        if(!user){
            throw new NotFoundException(`Not found user: ${id}`)
        }
        return await this.prisma.user.delete({
            where:{id}
        })
    }
    
    async searchUsers(keyword: string) {
        if (!keyword || keyword.trim() === '') {
        // nếu không có keyword, trả về toàn bộ user
            return this.prisma.user.findMany();
        }

        return this.prisma.user.findMany({
            where: {
            OR: [
                { username: { contains: keyword, mode: 'insensitive' } },
                { email: { contains: keyword, mode: 'insensitive' } },
                { name: { contains: keyword, mode: 'insensitive' } },
                ],
            },
        });
    }

    //  async getPass(){
    //     const adminPass = await bcrypt.hash("123456",10)
    //     const pass2 = await bcrypt.hash("passwordUser1",10)
    //     const pass3 = await bcrypt.hash("passwordUser2",10)
    //     const pass4 = await bcrypt.hash("passwordUser3",10)
    //     console.log(adminPass)
    //     console.log(pass2)
    //     console.log(pass3)
    //     console.log(pass4)
    //}
}

//  const user = new AdminUserService(new PrismaService)
//  user.getPass()

