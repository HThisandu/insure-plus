import 'package:flutter/material.dart';

class ClaimsScreen extends StatelessWidget {
  const ClaimsScreen({
    super.key,
    required this.openMotorClaims,
    required this.openMedicalClaims,
  });

  final VoidCallback openMotorClaims;
  final VoidCallback openMedicalClaims;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Choose a claim type',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.directions_car_outlined),
              title: const Text('Motor Claims'),
              trailing: const Icon(Icons.chevron_right),
              onTap: openMotorClaims,
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.medical_services_outlined),
              title: const Text('Medical Claims'),
              trailing: const Icon(Icons.chevron_right),
              onTap: openMedicalClaims,
            ),
          ),
        ],
      ),
    );
  }
}
