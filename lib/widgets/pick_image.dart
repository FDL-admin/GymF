import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

const int imageMaxDimension = 1280;
const int imageQuality = 80;

Future<ImageSource?> askImageSource(BuildContext context) {
  return showModalBottomSheet<ImageSource>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Prendre une photo'),
            onTap: () => Navigator.of(context).pop(ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Choisir dans la galerie'),
            onTap: () => Navigator.of(context).pop(ImageSource.gallery),
          ),
        ],
      ),
    ),
  );
}

Future<XFile?> pickImage(BuildContext context) async {
  final source = await askImageSource(context);
  if (source == null) return null;
  return ImagePicker().pickImage(
    source: source,
    maxWidth: imageMaxDimension.toDouble(),
    maxHeight: imageMaxDimension.toDouble(),
    imageQuality: imageQuality,
  );
}