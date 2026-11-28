enum MedicalClaimStatus {
  submitted('Submitted', 'Submitted'),
  underReview('UnderReview', 'Under review'),
  moreInfoRequired('MoreInfoRequired', 'More info required'),
  approved('Approved', 'Approved'),
  rejected('Rejected', 'Rejected');

  const MedicalClaimStatus(this.value, this.label);

  final String value;
  final String label;

  static MedicalClaimStatus fromValue(String? rawValue) {
    if (rawValue == null || rawValue.trim().isEmpty) {
      return MedicalClaimStatus.submitted;
    }

    final cleaned = rawValue
        .trim()
        .toLowerCase()
        .replaceAll(' ', '')
        .replaceAll('_', '')
        .replaceAll('-', '');

    for (final status in MedicalClaimStatus.values) {
      final valueKey = status.value.toLowerCase();
      final labelKey = status.label.toLowerCase().replaceAll(' ', '');
      if (cleaned == valueKey ||
          cleaned == labelKey ||
          cleaned == status.name.toLowerCase()) {
        return status;
      }
    }

    return MedicalClaimStatus.submitted;
  }
}
