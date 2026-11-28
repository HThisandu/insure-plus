import 'package:flutter/material.dart';

/// Reusable tile representing an uploadable or attached supporting document.
class DocumentPickerTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isAttached;
  final VoidCallback? onToggle;

  const DocumentPickerTile({
    super.key,
    required this.title,
    required this.subtitle,
    this.isAttached = false,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10.0),
      decoration: BoxDecoration(
        color: isAttached ? const Color(0xFFF0FDF4) : Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color: isAttached ? Colors.green.shade300 : Colors.grey.shade300,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4.0),
        leading: CircleAvatar(
          backgroundColor: isAttached ? Colors.green.shade100 : Colors.indigo.shade50,
          child: Icon(
            isAttached ? Icons.check_circle_outline : Icons.upload_file_rounded,
            color: isAttached ? Colors.green : Colors.indigo,
            size: 22.0,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.0),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12.0, color: Colors.grey.shade600),
        ),
        trailing: OutlinedButton(
          onPressed: onToggle,
          style: OutlinedButton.styleFrom(
            foregroundColor: isAttached ? Colors.red.shade700 : Colors.indigo,
            side: BorderSide(color: isAttached ? Colors.red.shade200 : Colors.indigo),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          ),
          child: Text(
            isAttached ? 'Remove' : 'Attach',
            style: const TextStyle(fontSize: 12.0),
          ),
        ),
      ),
    );
  }
}
