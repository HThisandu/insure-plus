import 'package:flutter/material.dart';

import '../../../common/models/claim_document.dart';

/// Reusable widget for capturing, uploading, and displaying accident photos.
/// Works directly with [ClaimDocument] objects conforming to the schema:
/// [documentId], [documentType], [fileName], [fileUrl], [uploadedAt].
class AccidentPhotoUploadWidget extends StatelessWidget {
  final List<ClaimDocument> photos;
  final ValueChanged<String>? onAddPhoto;
  final ValueChanged<ClaimDocument>? onRemovePhoto;
  final bool isReadOnly;
  final Future<String> Function(ClaimDocument photo)? resolvePhotoUrl;

  const AccidentPhotoUploadWidget({
    super.key,
    required this.photos,
    this.onAddPhoto,
    this.onRemovePhoto,
    this.isReadOnly = false,
    this.resolvePhotoUrl,
  });

  void _showAddPhotoDialog(BuildContext context) {
    final photoPresets = [
      'Front_Bumper_Damage.jpg',
      'Rear_Impact_Area.jpg',
      'Driver_Side_Door.jpg',
      'Passenger_Side_Scrape.jpg',
      'Windshield_Glass_Crack.jpg',
      'Engine_Bay_CloseUp.jpg',
      'Vehicle_Odometer_Reading.jpg',
      'Accident_Scene_Wide.jpg',
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Upload Accident Photo',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const Text(
              'Select an angle or accident perspective to attach:',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: photoPresets.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final preset = photoPresets[index];
                  final isAlreadyAdded = photos.any(
                    (p) => p.fileName == preset,
                  );

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: Colors.indigo.shade50,
                      child: const Icon(
                        Icons.photo_camera_rounded,
                        color: Colors.indigo,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      preset.replaceAll('_', ' ').replaceAll('.jpg', ''),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: isAlreadyAdded
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : TextButton.icon(
                            icon: const Icon(
                              Icons.add_a_photo_outlined,
                              size: 16,
                            ),
                            label: const Text('Add'),
                            onPressed: () {
                              Navigator.pop(ctx);
                              if (onAddPhoto != null) {
                                onAddPhoto!(preset);
                              }
                            },
                          ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Accident Photos (${photos.length})',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14.5,
              ),
            ),
            if (!isReadOnly)
              TextButton.icon(
                onPressed: () => _showAddPhotoDialog(context),
                icon: const Icon(Icons.add_a_photo_rounded, size: 18),
                label: const Text('Upload Photo'),
                style: TextButton.styleFrom(foregroundColor: Colors.indigo),
              ),
          ],
        ),
        const SizedBox(height: 8),

        if (photos.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.shade300,
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 40,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 8),
                const Text(
                  'No accident photos uploaded yet.',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  'Upload clear photos of damage, vehicle number plate, and collision scene.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                if (!isReadOnly) ...[
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => _showAddPhotoDialog(context),
                    icon: const Icon(Icons.camera_alt_outlined, size: 18),
                    label: const Text('Add Accident Photo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: photos.length + (isReadOnly ? 0 : 1),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.4,
            ),
            itemBuilder: (context, index) {
              if (!isReadOnly && index == photos.length) {
                // Add more photos card
                return InkWell(
                  onTap: () => _showAddPhotoDialog(context),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.indigo.shade200,
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.add_a_photo_outlined,
                          color: Colors.indigo,
                          size: 28,
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Add Photo',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final photoDoc = photos[index];
              final displayName = photoDoc.fileName
                  .replaceAll('_', ' ')
                  .replaceAll('.jpg', '');

              return Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child:
                              resolvePhotoUrl != null &&
                                  !photoDoc.fileUrl.startsWith('gs://')
                              ? FutureBuilder<String>(
                                  future: resolvePhotoUrl!(photoDoc),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      return ClipRRect(
                                        borderRadius:
                                            const BorderRadius.vertical(
                                              top: Radius.circular(9),
                                            ),
                                        child: Image.network(
                                          snapshot.data!,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) => const Icon(
                                            Icons.broken_image_outlined,
                                          ),
                                        ),
                                      );
                                    }
                                    return const Center(
                                      child: Icon(
                                        Icons.directions_car_filled_rounded,
                                        color: Colors.indigo,
                                        size: 30,
                                      ),
                                    );
                                  },
                                )
                              : const Center(
                                  child: Icon(
                                    Icons.directions_car_filled_rounded,
                                    color: Colors.indigo,
                                    size: 30,
                                  ),
                                ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            displayName,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        Text(
                          photoDoc.documentId,
                          style: TextStyle(
                            fontSize: 9.5,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.cloud_done_rounded,
                            color: Colors.white,
                            size: 10,
                          ),
                          SizedBox(width: 3),
                          Text(
                            'Private Cloud',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!isReadOnly)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: CircleAvatar(
                        radius: 13,
                        backgroundColor: Colors.red.shade600,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          iconSize: 14,
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () {
                            if (onRemovePhoto != null) {
                              onRemovePhoto!(photoDoc);
                            }
                          },
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }
}
