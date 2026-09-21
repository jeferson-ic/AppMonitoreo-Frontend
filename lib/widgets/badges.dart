import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class RiesgoBadge extends StatelessWidget {
  final String nivel;
  const RiesgoBadge({super.key, required this.nivel});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.riesgoColor(nivel);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        'RIESGO ${nivel.toUpperCase()}',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class EstadoBadge extends StatelessWidget {
  final String estado;
  final bool dot;
  const EstadoBadge({super.key, required this.estado, this.dot = true});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.estadoColor(estado);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            AppColors.estadoLabel(estado),
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class RiesgoDot extends StatelessWidget {
  final String nivel;
  final double size;
  const RiesgoDot({super.key, required this.nivel, this.size = 10});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.riesgoColor(nivel),
        shape: BoxShape.circle,
      ),
    );
  }
}
