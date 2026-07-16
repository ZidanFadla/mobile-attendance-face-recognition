import 'package:flutter/material.dart';

import '../../core/app_theme.dart';

class SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final Color? color;
  final VoidCallback? onTap;

  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.radius = AppTheme.radiusXl,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = AnimatedContainer(
      duration: AppTheme.normalTransition,
      curve: AppTheme.transitionCurve,
      margin: margin,
      padding: padding,
      decoration: AppTheme.clayDecoration(color: color, radius: radius),
      child: child,
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: card,
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const SectionTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 4, 2, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.textDark,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class ClayButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool destructive;

  const ClayButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isLoading = false,
    this.destructive = false,
  });

  @override
  State<ClayButton> createState() => _ClayButtonState();
}

class _ClayButtonState extends State<ClayButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.isLoading;
    final colors = widget.destructive
        ? AppTheme.gradientError
        : AppTheme.gradientArmyGreen;

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      child: AnimatedScale(
        duration: AppTheme.fastTransition,
        curve: AppTheme.transitionCurve,
        scale: _pressed ? 0.98 : 1,
        child: AnimatedContainer(
          duration: AppTheme.normalTransition,
          height: 56,
          decoration: BoxDecoration(
            gradient: enabled ? LinearGradient(colors: colors) : null,
            color: enabled ? null : AppTheme.surfaceAlt,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            boxShadow: enabled ? [AppTheme.buttonShadow] : [],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: enabled ? widget.onPressed : null,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              child: Center(
                child: AnimatedSwitcher(
                  duration: AppTheme.fastTransition,
                  child: widget.isLoading
                      ? const SizedBox(
                          key: ValueKey('loading'),
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          key: const ValueKey('content'),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(widget.icon, color: Colors.white, size: 20),
                            const SizedBox(width: 10),
                            Text(
                              widget.label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SoftIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;
  final String? semanticLabel;

  const SoftIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.color,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: 46,
            height: 46,
            decoration: AppTheme.clayDecoration(radius: 18),
            child: Icon(icon, color: color ?? AppTheme.textDark, size: 22),
          ),
        ),
      ),
    );
  }
}

class SoftNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<SoftNavigationItem> items;

  const SoftNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: AppTheme.clayDecoration(radius: 28),
          child: Row(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final selected = currentIndex == index;
              return Expanded(
                child: _SoftNavItem(
                  item: item,
                  selected: selected,
                  onTap: () => onTap(index),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class SoftNavigationItem {
  final IconData icon;
  final String label;
  final Widget? badge;

  const SoftNavigationItem({
    required this.icon,
    required this.label,
    this.badge,
  });
}

class _SoftNavItem extends StatelessWidget {
  final SoftNavigationItem item;
  final bool selected;
  final VoidCallback onTap;

  const _SoftNavItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      label: item.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: AnimatedContainer(
            duration: AppTheme.normalTransition,
            curve: AppTheme.transitionCurve,
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: selected
                  ? AppTheme.clayPrimary.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                AnimatedScale(
                  duration: AppTheme.fastTransition,
                  scale: selected ? 1.08 : 1,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        item.icon,
                        color: selected
                            ? AppTheme.clayPrimary
                            : AppTheme.textMuted,
                        size: 23,
                      ),
                      if (item.badge != null)
                        Positioned(right: -7, top: -7, child: item.badge!),
                    ],
                  ),
                ),
                if (selected)
                  Flexible(
                    child: AnimatedSize(
                      duration: AppTheme.normalTransition,
                      curve: AppTheme.transitionCurve,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 5),
                        child: Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                          style: TextStyle(
                            color: AppTheme.clayPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LoadingCard extends StatelessWidget {
  final String message;

  const LoadingCard({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(26),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.86, end: 1),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
            builder: (context, value, child) {
              return Transform.scale(scale: value, child: child);
            },
            child: Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: AppTheme.gradientArmyGreen),
                boxShadow: [AppTheme.buttonShadow],
              ),
              child: const Icon(
                Icons.face_retouching_natural_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textDark,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              minHeight: 6,
              backgroundColor: AppTheme.surfaceAlt,
              color: AppTheme.clayPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
