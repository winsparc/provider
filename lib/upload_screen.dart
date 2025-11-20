import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/upload_provider.dart';

class UploadScreen extends StatefulWidget {
  final String baseUrl;
  final UserImage? editingItem; // New: For edit mode

  const UploadScreen({super.key, required this.baseUrl, this.editingItem});

  @override
  _UploadScreenState createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  late TextEditingController _usernameController;
  @override
  void initState() {
    super.initState();
    final provider = Provider.of<UploadProvider>(context, listen: false);
    _usernameController = TextEditingController(text: provider.username);
    if (widget.editingItem != null) {
      provider.loadForEdit(widget.editingItem!);
      _usernameController.text = widget.editingItem!.username;
    } else {
      provider.clearEditMode();
    }
    provider.fetchUserImages(baseUrl: widget.baseUrl); // Optional
  }

  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.editingItem != null ? 'Update Item' : 'Insert New Item'),
        actions: [
          IconButton(
            icon: Icon(Icons.list),
            onPressed: () => Navigator.pushNamed(context, '/list'),
          ),
        ],
      ),
      body: Consumer<UploadProvider>(
        builder: (context, provider, child) {
          print("api calling");
          print(provider.errorMessage);
          return Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                  ),
                  controller: _usernameController,
                  onChanged: provider.updateUsername,
                ),

                SizedBox(height: 20),

                if (provider.selectedImage != null ||
                    provider.editingItem != null)
                  Column(
                    children: [
                      if (provider.selectedImage != null)
                        Image.file(provider.selectedImage!,
                            height: 150, fit: BoxFit.cover),
                      if (provider.editingItem != null &&
                          provider.selectedImage == null)
                        Image.network(
                          provider.editingItem!.imageUrl,
                          height: 150,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Icon(Icons.error),
                        ),
                      Text(provider.selectedImage == null &&
                              provider.editingItem != null
                          ? 'No new image selected (username only update)'
                          : 'Selected Image'),
                    ],
                  ),

                SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: provider.isLoadingUpload
                            ? null
                            : provider.pickImage,
                        child: Text('Pick/Change Image'),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: provider.isLoadingUpload
                            ? null
                            : provider.pickFromCamera,
                        icon: Icon(Icons.camera_alt),
                        label: Text('Camera'),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: provider.isLoadingUpload
                            ? null
                            : () {
                                // provider.saveImageAndUsername(
                                //   baseUrl: widget.baseUrl,
                                //   fieldName: 'image',
                                //   // fileName: 'custom_name.jpg',
                                //   fileName:
                                //       '${DateTime.now().millisecondsSinceEpoch}.jpg',
                                // );

// provider.saveUserDataJson(
//   baseUrl: widget.baseUrl,
//  username: provider.username,
//   email: 'john@gmail.com',
//   password: '123456',

// );

                               provider.updateUserProfile(
                                  baseUrl: widget.baseUrl,
                                  fieldName: 'image',
                                  // fileName: 'custom_name.jpg',
                                  fileName:
                                      '${DateTime.now().millisecondsSinceEpoch}.jpg',
                                );

                                if (provider.successMessage != null) {
                                  Navigator.pop(
                                      context); // Back to list after success
                                }
                              },
                        child: provider.isLoadingUpload
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : Text(widget.editingItem != null
                                ? 'Update'
                                : 'Insert'),
                      ),
                    ),
                  ],
                ),

                // Cancel Edit (only for update mode)
                if (widget.editingItem != null)
                  TextButton(
                    onPressed: () {
                      provider.clearEditMode();
                      Navigator.pop(context);
                    },
                    child: Text('Cancel Edit'),
                  ),

                // Messages
                if (provider.errorMessage != null)
                  Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Text(provider.errorMessage!,
                        style: TextStyle(color: Colors.red)),
                  ),
                if (provider.successMessage != null)
                  Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Text(provider.successMessage!,
                        style: TextStyle(color: Colors.green)),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
