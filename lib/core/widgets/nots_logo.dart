   import 'package:material_ui/material_ui.dart';
   import 'package:flutter_svg/flutter_svg.dart';

   import '../theme.dart';

   class NotsLogo extends StatelessWidget {
     const NotsLogo({super.key, this.size = 92});

     final double size;

     @override
     Widget build(BuildContext context) {
       final s = size / 92;
       return Container(
         width: size,
         height: size,
         decoration: const BoxDecoration(
           color: NotsColors.primary,
           shape: BoxShape.circle,
         ),
         child: Center(
           child: SvgPicture.asset(
             'assets/images/logo_bell.svg',
             width: 51 * s,
             height: 60 * s,
           ),
         ),
       );
     }
   }