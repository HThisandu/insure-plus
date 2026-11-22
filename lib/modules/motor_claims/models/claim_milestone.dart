/// Represents a progress milestone in the tracking of a motor claim.
class ClaimMilestone {
  final String title;
  final String description;
  final String date;
  final bool isCompleted;
  final bool isCurrent;

  const ClaimMilestone({
    required this.title,
    required this.description,
    required this.date,
    this.isCompleted = false,
    this.isCurrent = false,
  });
}
