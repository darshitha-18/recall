import 'dart:math' as math;

import 'package:flutter/material.dart';
import'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import 'state.dart';
import 'theme.dart';

// ---------------------------------------------------------------------------
// Logo
// ---------------------------------------------------------------------------

/// Typographic logo: "Re" upright, "call" in italic, with an accent full stop.
class RecallLogo extends StatelessWidget {
  const RecallLogo({super.key, this.size = 26, this.compact = false});
  final double size;

  /// Monogram only ("R.") for the narrow tablet rail.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final base = T.serif(size, p.ink, h: 1, ls: -size * 0.03);
    return Semantics(
      label: 'Recall',
      child: ExcludeSemantics(
        child: Text.rich(
          TextSpan(style: base, children: [
            TextSpan(text: compact ? 'R' : 'Re', style: base.copyWith(fontWeight: FontWeight.w800)),
            if (!compact)
              TextSpan(
                text: 'call',
                style: base.copyWith(
                    fontStyle: FontStyle.italic, fontWeight: FontWeight.w400),
              ),
            TextSpan(text: '.', style: base.copyWith(color: p.accent)),
          ]),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Buttons
// ---------------------------------------------------------------------------

enum BtnKind { primary, secondary, ghost }

class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.kind = BtnKind.primary,
    this.expand = false,
    this.large = false,
    this.color,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final IconData? trailingIcon;
  final BtnKind kind;
  final bool expand;
  final bool large;

  /// Optional tone override (text colour for secondary buttons).
  final Color? color;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _hover = false, _focus = false, _down = false;

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final enabled = widget.onPressed != null;

    Color bg = p.surface, fg = p.ink, border = p.border;
    switch (widget.kind) {
      case BtnKind.primary:
        bg = Color.lerp(p.accent, p.ink, _down ? .32 : (_hover ? .16 : 0))!;
        fg = p.onAccent;
        border = bg;
        break;
      case BtnKind.secondary:
        fg = widget.color ?? p.ink;
        bg = _down ? p.sunken : p.surface;
        border = _hover || _down ? tint(fg, .45) : p.border;
        break;
      case BtnKind.ghost:
        fg = widget.color ?? p.ink;
        bg = _down
            ? tint(p.ink, .10)
            : (_hover ? tint(p.ink, .06) : Colors.transparent);
        border = Colors.transparent;
        break;
    }

    final content = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, size: 18, color: fg),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            widget.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: T.sans(widget.large ? 15.5 : 14.5, fg,
                w: FontWeight.w600, h: 1.2),
          ),
        ),
        if (widget.trailingIcon != null) ...[
          const SizedBox(width: 8),
          Icon(widget.trailingIcon, size: 18, color: fg),
        ],
      ],
    );

    return FocusableActionDetector(
      enabled: enabled,
      mouseCursor:
          enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onShowHoverHighlight: (v) => setState(() => _hover = v),
      onShowFocusHighlight: (v) => setState(() => _focus = v),
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) {
          widget.onPressed?.call();
          return null;
        }),
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapUp: enabled ? (_) => setState(() => _down = false) : null,
        onTapCancel: enabled ? () => setState(() => _down = false) : null,
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _down ? .98 : 1,
          duration: const Duration(milliseconds: 90),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
            height: widget.large ? 52 : 44,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _focus ? p.accent : border,
                width: _focus ? 2 : 1,
              ),
            ),
            child: Opacity(opacity: enabled ? 1 : .45, child: content),
          ),
        ),
      ),
    );
  }
}

class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon, size: 18),
      style: IconButton.styleFrom(
        foregroundColor: color ?? p.muted,
        hoverColor: tint(p.ink, .06),
        highlightColor: tint(p.ink, .10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Surfaces and small building blocks
// ---------------------------------------------------------------------------

class HoverBox extends StatefulWidget {
  const HoverBox({super.key, required this.builder, this.onTap});
  final Widget Function(BuildContext context, bool hovered) builder;
  final VoidCallback? onTap;

  @override
  State<HoverBox> createState() => _HoverBoxState();
}

class _HoverBoxState extends State<HoverBox> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: widget.builder(context, _hover),
      ),
    );
  }
}

class Surface extends StatelessWidget {
  const Surface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: p.border),
        boxShadow: [
          BoxShadow(color: p.shadow, blurRadius: 2, offset: const Offset(0, 1)),
        ],
      ),
      child: child,
    );
  }
}

class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.compact = false,
    this.valueColor,
  });
  final String label;
  final String value;
  final bool compact;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Surface(
      padding: EdgeInsets.all(compact ? 14 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: T.label(p.muted)),
          SizedBox(height: compact ? 8 : 12),
          Text(value,
              style: T.serif(compact ? 28 : 38, valueColor ?? p.ink, h: 1)),
        ],
      ),
    );
  }
}

/// Fades and slides its child in once when first built.
class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({super.key, required this.child, this.index = 0});
  final Widget child;
  final int index;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 320 + math.min(index, 8) * 70),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, (1 - t) * 12), child: child),
      ),
      child: child,
    );
  }
}

class DashedRRectPainter extends CustomPainter {
  DashedRRectPainter({required this.color, this.radius = 12});
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Offset.zero & size, Radius.circular(radius)));
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 6), paint);
        d += 11;
      }
    }
  }

  @override
  bool shouldRepaint(DashedRRectPainter old) =>
      old.color != color || old.radius != radius;
}

// ---------------------------------------------------------------------------
// App shell: sidebar (desktop) / rail (tablet) / bottom bar (mobile)
// ---------------------------------------------------------------------------

class _Dest {
  const _Dest(this.route, this.label, this.short, this.icon);
  final String route, label, short;
  final IconData icon;
}

const _dests = [
  _Dest('/', 'Home', 'Home', LucideIcons.home),
  _Dest('/import', 'Import notes', 'Import', LucideIcons.upload),
];

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.route, required this.child});
  final String route;
  final Widget child;

  void _go(BuildContext context, String target) {
    if (target == route) return;
    Navigator.pushReplacementNamed(context, target);
  }

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final state = context.watch<RecallState>();
    final themeIcon = state.isDark ? LucideIcons.sun : LucideIcons.moon;
    final themeLabel = state.isDark ? 'Light mode' : 'Dark mode';

    return Scaffold(
      backgroundColor: p.bg,
      body: LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth;

        if (w >= 1000) {
          return Row(children: [
            _SideContainer(
              width: 248,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Align(
                      alignment: Alignment.centerLeft,
                      child: RecallLogo(size: 30)),
                ),
                const SizedBox(height: 32),
                for (final d in _dests)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: _SideTile(
                      icon: d.icon,
                      label: d.label,
                      selected: d.route == route,
                      onTap: () => _go(context, d.route),
                    ),
                  ),
                const Spacer(),
                _SideTile(
                  icon: themeIcon,
                  label: themeLabel,
                  onTap: context.read<RecallState>().toggleTheme,
                ),
              ]),
            ),
            Expanded(child: child),
          ]);
        }

        if (w >= 640) {
          return Row(children: [
            _SideContainer(
              width: 76,
              child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                const SizedBox(height: 4),
                const RecallLogo(size: 28, compact: true),
                const SizedBox(height: 28),
                for (final d in _dests)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: _SideTile(
                      icon: d.icon,
                      label: d.label,
                      selected: d.route == route,
                      showLabel: false,
                      onTap: () => _go(context, d.route),
                    ),
                  ),
                const Spacer(),
                _SideTile(
                  icon: themeIcon,
                  label: themeLabel,
                  showLabel: false,
                  onTap: context.read<RecallState>().toggleTheme,
                ),
              ]),
            ),
            Expanded(child: child),
          ]);
        }

        // Mobile: compact top bar + bottom navigation.
        return SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
              child: Row(children: [
                const RecallLogo(size: 24),
                const Spacer(),
                AppIconButton(
                  icon: themeIcon,
                  tooltip: themeLabel,
                  onPressed: context.read<RecallState>().toggleTheme,
                ),
              ]),
            ),
            Expanded(child: child),
            Container(
              decoration: BoxDecoration(
                color: p.sunken,
                border: Border(top: BorderSide(color: p.border)),
              ),
              child: Row(children: [
                for (final d in _dests)
                  Expanded(
                    child: _BottomItem(
                      dest: d,
                      selected: d.route == route,
                      onTap: () => _go(context, d.route),
                    ),
                  ),
              ]),
            ),
          ]),
        );
      }),
    );
  }
}

class _SideContainer extends StatelessWidget {
  const _SideContainer({required this.width, required this.child});
  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Container(
      width: width,
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 20),
      decoration: BoxDecoration(
        color: p.sunken,
        border: Border(right: BorderSide(color: p.border)),
      ),
      child: child,
    );
  }
}

class _SideTile extends StatelessWidget {
  const _SideTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.showLabel = true,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: HoverBox(
        onTap: onTap,
        builder: (context, hover) {
          final fg = selected ? p.ink : p.muted;
          final tile = AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            height: 42,
            padding: EdgeInsets.symmetric(horizontal: showLabel ? 12 : 0),
            decoration: BoxDecoration(
              color: selected
                  ? p.surface
                  : (hover ? tint(p.ink, .05) : Colors.transparent),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: selected ? p.border : Colors.transparent),
            ),
            child: Row(
              mainAxisAlignment:
                  showLabel ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: selected ? p.accent : fg),
                if (showLabel) ...[
                  const SizedBox(width: 12),
                  Text(label,
                      style: T.sans(14.5, fg,
                          w: selected ? FontWeight.w600 : FontWeight.w500)),
                ],
              ],
            ),
          );
          return showLabel
              ? tile
              : Tooltip(message: label, child: SizedBox(width: 44, child: tile));
        },
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  const _BottomItem(
      {required this.dest, required this.selected, required this.onTap});
  final _Dest dest;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final color = selected ? p.accent : p.muted;
    return Semantics(
      button: true,
      selected: selected,
      label: dest.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          height: 60,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(dest.icon, size: 20, color: color),
              const SizedBox(height: 4),
              Text(dest.short,
                  style: T.sans(11.5, color,
                      w: selected ? FontWeight.w600 : FontWeight.w500, h: 1.2)),
            ],
          ),
        ),
      ),
    );
  }
}
