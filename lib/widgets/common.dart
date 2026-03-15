import 'package:flutter/material.dart';
import '../theme/theme.dart';

// ── Stat Card ─────────────────────────────────────────────────────────────────
class HMStatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final Color? valueColor;
  final double? progress; // 0.0 to 1.0
  final Color? progressColor;
  final String? badge;
  final Color? badgeColor;

  const HMStatCard({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.valueColor,
    this.progress,
    this.progressColor,
    this.badge,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HMColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: HMColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: HMColors.text3,
              fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700,
                  color: valueColor ?? HMColors.text, fontFamily: 'DM Mono')),
              if (badge != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (badgeColor ?? HMColors.success).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(badge!, style: TextStyle(
                      fontSize: 11, color: badgeColor ?? HMColors.success, fontWeight: FontWeight.w600)),
                ),
              ],
            ],
          ),
          if (unit != null)
            Text(unit!, style: const TextStyle(fontSize: 12, color: HMColors.text3)),
          if (progress != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress!.clamp(0.0, 1.0),
                backgroundColor: HMColors.surface3,
                valueColor: AlwaysStoppedAnimation(progressColor ?? HMColors.accent),
                minHeight: 5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Section Card ──────────────────────────────────────────────────────────────
class HMCard extends StatelessWidget {
  final String? title;
  final Widget child;
  final Widget? trailing;
  final EdgeInsets? padding;

  const HMCard({super.key, this.title, required this.child, this.trailing, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: HMColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: HMColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                      color: HMColors.text)),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
          Padding(
            padding: padding ?? EdgeInsets.fromLTRB(16, title != null ? 12 : 16, 16, 16),
            child: child,
          ),
        ],
      ),
    );
  }
}

// ── Gradient Button ────────────────────────────────────────────────────────────
class HMButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  final IconData? icon;
  final Color? color;
  final bool outlined;

  const HMButton({super.key, required this.label, this.onTap, this.loading = false,
      this.icon, this.color, this.outlined = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 46,
        decoration: BoxDecoration(
          gradient: outlined ? null : LinearGradient(
            colors: color != null
                ? [color!, color!.withOpacity(0.8)]
                : [HMColors.accent, const Color(0xFF00b8ad)],
          ),
          border: outlined ? Border.all(color: color ?? HMColors.accent) : null,
          borderRadius: BorderRadius.circular(10),
          boxShadow: outlined ? null : [BoxShadow(
            color: (color ?? HMColors.accent).withOpacity(0.25),
            blurRadius: 12, offset: const Offset(0, 4),
          )],
        ),
        child: Center(
          child: loading
              ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF001a1a)))
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 16,
                          color: outlined ? (color ?? HMColors.accent) : const Color(0xFF001a1a)),
                      const SizedBox(width: 6),
                    ],
                    Text(label, style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14,
                        color: outlined ? (color ?? HMColors.accent) : const Color(0xFF001a1a))),
                  ],
                ),
        ),
      ),
    );
  }
}

// ── Form Field ────────────────────────────────────────────────────────────────
class HMTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int? maxLines;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;

  const HMTextField({super.key, required this.label, this.hint, this.controller,
      this.keyboardType, this.obscureText = false, this.maxLines = 1,
      this.suffix, this.validator, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: HMColors.text3, letterSpacing: 0.5)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLines: maxLines,
          validator: validator,
          onChanged: onChanged,
          style: const TextStyle(color: HMColors.text, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: suffix,
          ),
        ),
      ],
    );
  }
}

// ── Loading Shimmer ────────────────────────────────────────────────────────────
class HMShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double radius;
  const HMShimmerBox({super.key, this.width = double.infinity, required this.height, this.radius = 8});

  @override
  State<HMShimmerBox> createState() => _HMShimmerBoxState();
}

class _HMShimmerBoxState extends State<HMShimmerBox> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
    _anim = Tween<double>(begin: -1, end: 2).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutSine));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width, height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          gradient: LinearGradient(
            begin: Alignment(_anim.value - 1, 0),
            end: Alignment(_anim.value, 0),
            colors: const [HMColors.surface, HMColors.surface2, HMColors.surface],
          ),
        ),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────
class HMEmptyState extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const HMEmptyState({super.key, required this.emoji, required this.title,
      required this.subtitle, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                color: HMColors.text), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(subtitle, style: const TextStyle(fontSize: 13, color: HMColors.text3),
                textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              SizedBox(width: 160, child: HMButton(label: actionLabel!, onTap: onAction)),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Nutrient Badge ─────────────────────────────────────────────────────────────
class NutrientBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const NutrientBadge({super.key, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text('$label $value', style: TextStyle(
          fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

// ── Toast ─────────────────────────────────────────────────────────────────────
void showHMToast(BuildContext context, String message, {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message),
    backgroundColor: isError ? HMColors.danger : HMColors.surface2,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    margin: const EdgeInsets.all(12),
    duration: const Duration(seconds: 3),
  ));
}
