import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/upload_provider.dart';
import 'upload_screen.dart';  // Import for edit nav

class ListScreen extends StatefulWidget {
  final String baseUrl;

  const ListScreen({super.key, required this.baseUrl});

  @override
  _ListScreenState createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  @override
  void initState() {
    super.initState();
    Provider.of<UploadProvider>(context, listen: false).fetchUserImages(baseUrl: widget.baseUrl);
  }

  // New: Confirm delete dialog
  Future<void> _confirmDelete(BuildContext context, UserImage item) async {
    final provider = Provider.of<UploadProvider>(context, listen: false);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Item'),
        content: Text('Delete "${item.username}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      await provider.deleteItem(item.id, baseUrl: widget.baseUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('List of Items'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => UploadScreen(baseUrl: widget.baseUrl),  // New insert
              ),
            ),
          ),
        ],
      ),
      body: Consumer<UploadProvider>(
        builder: (context, provider, child) {
          return Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Items (${provider.userImages.length})'),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: provider.isLoadingList ? null : () => provider.fetchUserImages(baseUrl: widget.baseUrl),
                  child: Text(provider.isLoadingList ? 'Loading...' : 'Refresh'),
                ),
                SizedBox(height: 10),
                if (provider.isLoadingList) Center(child: CircularProgressIndicator()),
                if (provider.userImages.isEmpty && !provider.isLoadingList)
                  Center(child: Text('No items. Add from the + button!')),
                Expanded(
                  child: ListView.builder(
                    itemCount: provider.userImages.length,
                    itemBuilder: (context, index) {
                      final item = provider.userImages[index];
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(item.imageUrl),
                           // onBackgroundImageError: (, _) => Icon(Icons.error),
                            radius: 30,
                          ),
                          title: Text(item.username, style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(item.imageUrl),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => UploadScreen(
                                      baseUrl: widget.baseUrl,
                                      editingItem: item,  // Pass for edit
                                    ),
                                  ),
                                );
                              } else if (value == 'delete') {
                                _confirmDelete(context, item);
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit), SizedBox(width: 8), Text('Edit')])),
                              PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red), SizedBox(width: 8), Text('Delete')])),
                            ],
                          ),
                          onTap: () => showDialog(  // Full image view
                            context: context,
                            builder: (_) => Dialog(child: InteractiveViewer(child: Image.network(item.imageUrl, fit: BoxFit.contain))),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (provider.errorMessage != null)
                  Padding(padding: EdgeInsets.only(top: 10), child: Text(provider.errorMessage!, style: TextStyle(color: Colors.red))),
                if (provider.successMessage != null)
                  Padding(padding: EdgeInsets.only(top: 10), child: Text(provider.successMessage!, style: TextStyle(color: Colors.green))),
              ],
            ),
          );
        },
      ),
    );
  }
}