import 'package:flutter/material.dart';

class InsuranceDashboard extends StatelessWidget {
  const InsuranceDashboard({super.key});

  static const Color primaryColor = Color(0xFF123B65);
  static const Color backgroundColor = Color(0xFFF5F7FB);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Insure-Plus',
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none, color: primaryColor),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Hello, Policyholder 👋',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Manage your insurance policies in one place.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // Overview card
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Coverage',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'LKR 5,000,000.00',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 27,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _overviewItem('Active Policies', '03'),
                      _overviewItem('Remaining', '85%'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              'Insurance Categories',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),

            const SizedBox(height: 16),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.25,
              children: [
                _categoryCard(
                  Icons.directions_car,
                  'Motor Insurance',
                  Colors.blue,
                ),
                _categoryCard(
                  Icons.local_hospital,
                  'Medical Insurance',
                  Colors.green,
                ),
                _categoryCard(
                  Icons.favorite,
                  'Life Insurance',
                  Colors.redAccent,
                ),
                _categoryCard(Icons.flight, 'Travel Insurance', Colors.orange),
              ],
            ),

            const SizedBox(height: 28),

            const Text(
              'My Policies',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),

            const SizedBox(height: 14),

            _policyCard(
              Icons.directions_car,
              'Motor Insurance',
              'POL-2026-001',
              'Active',
            ),

            const SizedBox(height: 12),

            _policyCard(
              Icons.local_hospital,
              'Medical Insurance',
              'POL-2026-002',
              'Active',
            ),
          ],
        ),
      ),
    );
  }

  Widget _overviewItem(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _categoryCard(IconData icon, String title, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _policyCard(
    IconData icon,
    String title,
    String policyId,
    String status,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          Icon(icon, color: primaryColor, size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Text(
                  policyId,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            status,
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
