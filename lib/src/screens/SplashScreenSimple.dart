import 'package:flutter/material.dart';

class SplashScreenSimple extends StatefulWidget {
  final VoidCallback onComplete;
  
  const SplashScreenSimple({Key? key, required this.onComplete}) 
      : super(key: key);

  @override
  _SplashScreenSimpleState createState() => _SplashScreenSimpleState();
}

class _SplashScreenSimpleState extends State<SplashScreenSimple> 
    with SingleTickerProviderStateMixin {
  
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(seconds: 3), // 3 segundos en total
      vsync: this,
    );
    
    // Logo crece desde el centro
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.3, end: 1.2), // Empieza pequeño
        weight: 0.3,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.2, end: 1.0), // Se ajusta
        weight: 0.3,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.0), // Se mantiene
        weight: 0.4,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );
    
    // Logo aparece gradualmente
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      ),
    );
    
    // Iniciar animación
    _controller.forward().whenComplete(() {
      // Pequeña pausa al final
      Future.delayed(const Duration(milliseconds: 500), () {
        widget.onComplete();
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _opacityAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // LOGO PRINCIPAL - MUY GRANDE
                    Image.asset(
                      'assets/images/logo1.png',
                      width: 350,  // AJUSTA ESTE VALOR para hacerlo más grande/pequeño
                      height: 350,
                      filterQuality: FilterQuality.high,
                    ),
                    
                    // Texto que aparece después (opcional)
                    if (_controller.value > 0.6)
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 800),
                        opacity: _controller.value > 0.6 ? 1.0 : 0.0,
                        child: const Padding(
                          padding: EdgeInsets.only(top: 30),
                          child: Text(
                            'PointSales Pro',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
