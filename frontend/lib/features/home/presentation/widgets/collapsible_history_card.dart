import 'package:flutter/material.dart';

import 'package:slot_1_tasks/core/theme/app_colors.dart';
import 'package:slot_1_tasks/shared/widgets/harmonious_ui.dart';

/// Short history list by default; expands when the user asks for more.
class CollapsibleHistoryCard extends StatefulWidget {
  const CollapsibleHistoryCard({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.previewCount = 5,
    this.emptyMessage = 'No history yet.',
    this.title = 'History',
    this.subtitle,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final int previewCount;
  final String emptyMessage;
  final String title;
  final String? subtitle;

  @override
  State<CollapsibleHistoryCard> createState() => _CollapsibleHistoryCardState();
}

class _CollapsibleHistoryCardState extends State<CollapsibleHistoryCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final total = widget.itemCount;
    final visible = (!_expanded && total > widget.previewCount)
        ? widget.previewCount
        : total;
    final canExpand = total > widget.previewCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        if (widget.subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.subtitle!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
        const SizedBox(height: 10),
        if (total == 0)
          HarmoniousCard(
            padding: const EdgeInsets.all(16),
            child: Text(
              widget.emptyMessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
            ),
          )
        else
          HarmoniousCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < visible; i++) ...[
                  widget.itemBuilder(context, i),
                  if (i != visible - 1)
                    Divider(
                      height: 1,
                      color: AppColors.cardBorder.withValues(alpha: 0.8),
                    ),
                ],
                if (canExpand) ...[
                  Divider(
                    height: 1,
                    color: AppColors.cardBorder.withValues(alpha: 0.8),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _expanded = !_expanded),
                    child: Text(
                      _expanded
                          ? 'Show less'
                          : 'See all ($total)',
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
