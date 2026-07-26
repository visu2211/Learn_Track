import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CustomInputField extends StatelessWidget {
  final String label;
  final String placeholder;
  final IconData icon;
  final bool isPassword;
  final TextEditingController controller;

  const CustomInputField({
    Key? key,
    required this.label,
    required this.placeholder,
    required this.icon,
    this.isPassword = false,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 50,
          decoration: BoxDecoration(
            border: Border.all(color: colors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword,
            style: TextStyle(color: colors.textPrimary),
            decoration: InputDecoration(
              prefixIcon: Icon(
                icon,
                color: colors.textTertiary,
                size: 16,
              ),
              hintText: placeholder,
              hintStyle: TextStyle(
                color: colors.textTertiary,
                fontSize: 16,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 15,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
