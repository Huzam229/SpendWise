import 'package:flutter/material.dart';

import '../utils/formatters.dart';

class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.balance,
    required this.income,
    required this.expense,
  });

  final double balance;
  final double income;
  final double expense;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPositive = balance >= 0;

    final gradientColors = isDark
        ? [
            scheme.primaryContainer,
            Color.lerp(scheme.primaryContainer, scheme.tertiaryContainer, 0.55)!,
          ]
        : [
            scheme.primary,
            Color.lerp(scheme.primary, scheme.tertiary, 0.4)!,
          ];

    final onCard = isDark ? scheme.onPrimaryContainer : scheme.onPrimary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        border: isDark
            ? Border.all(color: scheme.outlineVariant.withValues(alpha: 0.35))
            : null,
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : scheme.primary)
                .withValues(alpha: isDark ? 0.35 : 0.22),
            blurRadius: isDark ? 18 : 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Balance',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: onCard.withValues(alpha: 0.85),
                  letterSpacing: 0.4,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            currencyFormat.format(balance),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: onCard,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            isPositive
                ? 'You are on track this month'
                : 'Spending ahead of income',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: onCard.withValues(alpha: 0.75),
                ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _MetricChip(
                  label: 'Income',
                  value: currencyFormat.format(income),
                  icon: Icons.arrow_downward_rounded,
                  tint: isDark
                      ? const Color(0xFF81C784)
                      : const Color(0xFFB9F6CA),
                  onCard: onCard,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricChip(
                  label: 'Expense',
                  value: currencyFormat.format(expense),
                  icon: Icons.arrow_upward_rounded,
                  tint: isDark
                      ? const Color(0xFFE57373)
                      : const Color(0xFFFFCDD2),
                  onCard: onCard,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.tint,
    required this.onCard,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color tint;
  final Color onCard;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: onCard.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: onCard.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.22),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: tint),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: onCard.withValues(alpha: 0.8),
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: onCard,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
