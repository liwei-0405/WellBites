import 'package:flutter/material.dart';


class GenderOption extends StatelessWidget {
  final String gender;
  final Color backgroundColor;
  final Widget icon;
  final VoidCallback onTap;
  final bool isSelected;

  const GenderOption({
    Key? key,
    required this.gender,
    required this.backgroundColor,
    required this.icon,
    required this.onTap,
    this.isSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 145,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: backgroundColor,
              border:
                  isSelected ? Border.all(color: Colors.white, width: 1) : null,
              boxShadow:
                  isSelected
                      ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 4,
                          offset: const Offset(0, 4),
                        ),
                      ]
                      : null,
            ),
            child: Center(child: icon),
          ),
          const SizedBox(height: 16),
          Text(gender),
        ],
      ),
    );
  }
}
