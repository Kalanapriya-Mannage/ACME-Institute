import 'package:flutter/material.dart';

class ModuleIconCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool disabled;
  const ModuleIconCard({super.key, required this.icon, required this.label, this.onTap, this.disabled = false});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: const Color(0xFFFF1800), size: 22),
              const SizedBox(height: 6),
              Flexible(
                fit: FlexFit.loose,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: disabled ? Colors.grey : Colors.black87,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (disabled) const Text('Soon', style: TextStyle(fontSize: 10, color: Color(0xFFFF1800))),
            ],
          ),
        ),
      ),
    );
  }
}
