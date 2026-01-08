import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_project/controller/auth_controller.dart';
import 'package:mobile_project/view/main_screen.dart';
import 'package:mobile_project/view/onboarding_screen.dart';
import 'package:mobile_project/view/signin_screen.dart';

const bool DEV_MODE = true;

class SplashScreen extends StatelessWidget {
  SplashScreen({super.key});

  final AuthController authController = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(milliseconds: 2500),(){

      if (DEV_MODE) {
        Get.off(() => const OnboardingScreen());
        //Get.off(() => MainScreen());
        return;
      }

      if(authController.isFirstTime){
          Get.off(()=> const OnboardingScreen());
      } else if(authController.isLoggedIn){
          Get.off(()=> const MainScreen());
      }else {
          Get.off(()=>  SigninScreen());
      }
    });


    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withValues(alpha: 0.8),
              Theme.of(context).primaryColor.withValues(alpha: 0.6),
            ]
          )
        ),
        child:  Stack(
          children: [
            Positioned.fill(
                child: Opacity(opacity: 0.05,
                child: GridPattern(
                  color: Colors.white,
                ),)
            ),

            // main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  // animated logo
                  TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 1200),
                      builder: (context, value, child){
                        return Transform.scale(
                          scale: value,
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape : BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            ),
                          ),
                        );
                      }
                  ),

                      const SizedBox(height: 32),

                      // animated text
                      TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 1200),
                          builder: (context, value, child){
                            return Opacity(opacity: value,
                            child: Transform.translate(
                                offset: Offset(0, 20 * (1 - value)),
                                child : child,
                            ),
                            );
                          },
                        child: Column(
                          children: [
                            Text(
                              "PROJECT 3",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 4,
                              ),
                            )
                          ],
                        ),
                      ),

                  // bottom tagline
                  Positioned(
                    bottom: 48,
                    left: 0,
                    right: 0,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 1200),
                      builder: (context, value, child){
                        return Opacity(opacity: value,
                          child: child,
                        );
                      },
                      child: Text(
                        'Quản lý xe ',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14 ,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w300,
                        ),
                      )
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class GridPattern extends StatelessWidget {
  final Color color;
  const GridPattern({
    Key? key,
    required this.color,
  }): super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: GridPainter(color: color),
    );
  }
}

class GridPainter extends CustomPainter{
  final Color color ;
  GridPainter ({required this.color});

  @override
  void paint(Canvas canvas, Size size){
    final paint = Paint()
    ..color = color
    ..strokeWidth = 0.5;

    final spacing = 20.0;

    for(var i = 0.0 ; i< size.width; i += spacing){
      canvas.drawLine(Offset(i,0), Offset(i, size.height), paint);
    }

    for(var i = 0.0 ; i< size.height; i += spacing){
      canvas.drawLine(Offset(0,i), Offset(size.width, i), paint);
    }

  }

  @override
  bool shouldRepaint (covariant CustomPainter oldDeletate) => false;


}