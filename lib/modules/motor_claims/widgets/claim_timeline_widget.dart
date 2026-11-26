import 'package:flutter/material.dart';

import '../../../common/theme/insurecare_theme.dart';
import '../models/claim_milestone.dart';

/// Vertical timeline stepper widget illustrating progress milestones for a claim.
class ClaimTimelineWidget extends StatelessWidget {
  final List<ClaimMilestone> milestones;

  const ClaimTimelineWidget({super.key, required this.milestones});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(milestones.length, (index) {
        final item = milestones[index];
        final isLast = index == milestones.length - 1;

        Color indicatorColor;
        IconData indicatorIcon;

        if (item.isCompleted) {
          indicatorColor = Colors.green;
          indicatorIcon = Icons.check_circle_rounded;
        } else if (item.isCurrent) {
          indicatorColor = InsureCareTheme.iconBlue;
          indicatorIcon = Icons.radio_button_checked_rounded;
        } else {
          indicatorColor = Colors.grey.shade300;
          indicatorIcon = Icons.radio_button_off_rounded;
        }

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Indicator column with connector line
              SizedBox(
                width: 32.0,
                child: Column(
                  children: [
                    Icon(indicatorIcon, color: indicatorColor, size: 22.0),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2.0,
                          color: item.isCompleted
                              ? Colors.green
                              : Colors.grey.shade300,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12.0),

              // Step Details
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0.0 : 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: item.isCurrent
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                color: item.isCurrent
                                    ? InsureCareTheme.navy
                                    : (item.isCompleted
                                          ? InsureCareTheme.text
                                          : Colors.grey.shade600),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          Text(
                            item.date,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        item.description,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
