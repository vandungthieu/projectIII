import { CanActivate, ExecutionContext, ForbiddenException, Injectable } from "@nestjs/common";
import { Reflector } from "@nestjs/core";
import { ROLES_KEY } from "src/common/decorator/roles.decorator";

@Injectable()
export class RolesGuard implements CanActivate{
    constructor (private reflector : Reflector){}
    canActivate(context: ExecutionContext): boolean  {
        const requiredRoles = this.reflector.get<string[]>(ROLES_KEY, context.getHandler());
            if (!requiredRoles || requiredRoles.length === 0) {
            return true;
        }

        const request = context.switchToHttp().getRequest()
        const user = request.user

        if(!user || !requiredRoles.includes(user.role)){
            throw new ForbiddenException('You are not have permission to access this resource')
        }

        return true
    }
}