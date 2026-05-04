import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../services/database_helper.dart';
import '../models/message.dart';
import 'add_message_screen.dart';

class MessageFeedScreen extends StatefulWidget {
  const MessageFeedScreen({super.key});
  @override
  State<MessageFeedScreen> createState() => _MessageFeedScreenState();
}

class _MessageFeedScreenState extends State<MessageFeedScreen> {
  String _filter = "all";
  String _searchQuery = "";
  bool _isSelectionMode = false;
  final Set<int> _selectedIds = {};
  int _bottomNavIndex = 0; 
  final SearchController _searchController = SearchController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        title: Text(_isSelectionMode ? "${_selectedIds.length} Selected" : "Social Sync"),
        leading: _isSelectionMode ? IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => setState(() {
            _isSelectionMode = false;
            _selectedIds.clear();
          }),
        ) : null,
        actions: [
          if (_isSelectionMode) ...[
            if (_filter == "deleted")
              IconButton(
                icon: const Icon(Icons.settings_backup_restore_rounded),
                onPressed: () => _handleBulkAction("restore"),
                tooltip: "Restore Selected",
              ),
            IconButton(
              icon: Icon(_filter == "deleted" ? Icons.delete_forever_rounded : Icons.delete_outline_rounded),
              onPressed: () => _handleBulkAction(_filter == "deleted" ? "delete_forever" : "trash"),
              tooltip: _filter == "deleted" ? "Delete Permanently" : "Move to Trash",
            ),
            const SizedBox(width: 8),
          ]
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildTabs(),
          Expanded(child: _buildMessageList()),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1A1F36),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        currentIndex: _bottomNavIndex,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AddMessageScreen())).then((_) {
              if (mounted) setState(() {});
            });
          } else {
            setState(() => _bottomNavIndex = index);
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: "Feed"),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline_rounded), label: "Create"),
        ],
      ),
    );
  }

  void _handleBulkAction(String action) async {
    if (action == "delete_forever") {
      bool confirm = await _confirmAction("Delete selected items permanently? This cannot be undone.");
      if (!confirm) return;
    }
    
    await DatabaseHelper.instance.bulkUpdateStatus(_selectedIds.toList(), action);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(action == "delete_forever" ? "Items deleted permanently" : "Items moved to ${action == "trash" ? "trash" : "feed"}")),
      );
      setState(() {
        _isSelectionMode = false;
        _selectedIds.clear();
      });
    }
  }

  Future<bool> _confirmAction(String message) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Action"),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("CANCEL")),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text("PROCEED", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    ) ?? false;
  }

  Widget _buildSearchBar() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
    child: SearchBar(
      controller: _searchController,
      onChanged: (v) => setState(() => _searchQuery = v),
      hintText: "Search messages...",
      leading: const Icon(Icons.search, color: Colors.grey),
      elevation: const WidgetStatePropertyAll(0),
      backgroundColor: WidgetStatePropertyAll(Colors.grey.withValues(alpha: 0.1)),
      shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
    ),
  );

  Widget _buildTabs() => Container(
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2), 
    color: Colors.transparent,
    child: Row(
      children: [
        Expanded(child: _buildTab("All", "all", Icons.grid_view_rounded)),
        Expanded(child: _buildTab("Draft", "not_posted", Icons.edit_note_rounded)),
        Expanded(child: _buildTab("Synced", "posted", Icons.cloud_done_rounded)),
        Expanded(child: _buildTab("Trash", "deleted", Icons.delete_outline_rounded)),
      ],
    ),
  );

  Widget _buildTab(String label, String f, IconData icon) {
    bool isSelected = _filter == f;
    const navy = Color(0xFF1A1F36);
    const sky = Color(0xFF010D47);
    
    return GestureDetector(
      onTap: () => setState(() {
        _filter = f;
        _isSelectionMode = false;
        _selectedIds.clear();
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(horizontal: 1), 
        padding: const EdgeInsets.symmetric(vertical: 10),
        transform: isSelected ? Matrix4.diagonal3Values(0.97, 0.97, 1.0) : Matrix4.identity(),
        decoration: BoxDecoration(
          color: isSelected ? sky : navy.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected ? [
            BoxShadow(
              color: sky.withValues(alpha: 0.2),
              offset: const Offset(0, 4),
              blurRadius: 8,
            ),
          ] : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14, 
              color: isSelected ? Colors.white : navy.withValues(alpha: 0.4),
            ),
            const SizedBox(width: 4), 
            Text(
              label, 
              style: TextStyle(
                color: isSelected ? Colors.white : navy.withValues(alpha: 0.6), 
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600, 
                fontSize: 10,
              )
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    return FutureBuilder<List<Message>>(
      future: DatabaseHelper.instance.getMessages(_filter, _searchQuery),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text("Error: ${snap.error}", style: const TextStyle(color: Colors.red)));
        }
        if (!snap.hasData || snap.data!.isEmpty) {
          return const Center(child: Text("No content found", style: TextStyle(color: Colors.grey)));
        }
        final messages = snap.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: messages.length,
          itemBuilder: (context, i) => _buildMessageCard(messages[i]),
        );
      },
    );
  }

  Widget _buildMessageCard(Message m) {
    bool isSelected = _selectedIds.contains(m.id);
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.15),
            offset: const Offset(0, 12),
            blurRadius: 24,
            spreadRadius: -4,
          ),
        ],
      ),
      child: Stack(
        children: [
          Card(
            key: ValueKey(m.id),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
              side: isSelected ? BorderSide(color: theme.colorScheme.primary, width: 3) : BorderSide.none,
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              onLongPress: () => setState(() {
                _isSelectionMode = true;
                _selectedIds.add(m.id!);
              }),
              onTap: () {
                if (_isSelectionMode) {
                  setState(() {
                    _selectedIds.contains(m.id) ? _selectedIds.remove(m.id) : _selectedIds.add(m.id!);
                    if (_selectedIds.isEmpty) _isSelectionMode = false;
                  });
                } else {
                  _showMessageDetail(m);
                }
              },
              child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (m.imagePaths.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.file(File(m.imagePaths[0]), width: 120, height: 120, fit: BoxFit.cover),
                      )
                    else
                      Container(
                        width: 120, height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.05), 
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                        ),
                        child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey, size: 40),
                      ),
                    
                    const SizedBox(width: 20),
                    
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  m.title, 
                                  maxLines: 1, 
                                  overflow: TextOverflow.ellipsis, 
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5)
                                )
                              ),
                              _buildStatusTag(m),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            m.content, 
                            maxLines: 3, 
                            overflow: TextOverflow.ellipsis, 
                            style: theme.textTheme.bodyMedium?.copyWith(height: 1.4, fontSize: 14)
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _formatStatusDate(m), 
                            style: TextStyle(
                              fontSize: 11, 
                              color: theme.colorScheme.primary.withValues(alpha: 0.6), 
                              fontWeight: FontWeight.w500,
                              height: 1.5,
                            )
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(height: 1, thickness: 0.5),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          if (m.isPosted == 1) _buildPlatformChips(m.sharedPlatforms) else const SizedBox(height: 36),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      children: [
                        _buildActionButton(Icons.edit_note_rounded, () => _editMessage(m), Colors.blue),
                        const SizedBox(width: 12),
                        _buildActionButton(Icons.visibility_rounded, () => _showMessageDetail(m), Colors.grey),
                        const SizedBox(width: 12),
                        if (m.isDeleted == 1) ...[ 
                          _buildActionButton(Icons.settings_backup_restore_rounded, () => _restoreMessage(m), Colors.green),
                          const SizedBox(width: 12),
                          _buildActionButton(Icons.delete_forever_rounded, () => _handleSinglePermanentDelete(m), Colors.red),
                        ] else
                          _buildActionButton(Icons.more_vert_rounded, () => _showMessageSettings(m), Colors.grey),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
          if (isSelected)
            Positioned(
              top: 10, right: 10,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
                child: const Icon(Icons.check, color: Colors.white, size: 18),
              ),
            ),
        ],
      ),
    );
  }

  void _handleSinglePermanentDelete(Message m) async {
    bool confirm = await _confirmAction("Delete this message permanently? This action cannot be undone.");
    if (!confirm) return;
    await DatabaseHelper.instance.updateStatus(m.id!, "delete_forever");
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Message deleted permanently")));
      setState(() {});
    }
  }

  Widget _buildActionButton(IconData icon, VoidCallback onTap, Color color) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 22, color: color),
      ),
    );
  }

  String _formatStatusDate(Message m) {
    final created = _timeAgo(m.createdAt);
    if (m.isDeleted == 1) {
      return "Created: $created\nDeleted: ${_timeAgo(m.deletedAt ?? m.createdAt)}";
    }
    if (m.isPosted == 1) {
      return "Created: $created\nSynced: ${_timeAgo(m.postedAt ?? m.createdAt)}";
    }
    return "Created: $created";
  }

  String _timeAgo(String dateStr) {
    try {
      DateTime dt = DateTime.parse(dateStr);
      Duration diff = DateTime.now().difference(dt);
      if (diff.inDays > 0) return "${diff.inDays}d ago";
      if (diff.inHours > 0) return "${diff.inHours}h ago";
      if (diff.inMinutes > 0) return "${diff.inMinutes}m ago";
      return "just now";
    } catch (e) {
      return "some time ago";
    }
  }

  void _editMessage(Message m) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => AddMessageScreen(editMessage: m))).then((_) {
      if (mounted) setState(() {});
    });
  }

  void _restoreMessage(Message m) async {
    await DatabaseHelper.instance.updateStatus(m.id!, "restore");
    if (mounted) setState(() {});
  }

  void _showMessageSettings(Message m) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.copy_rounded),
              title: const Text("Duplicate Message"),
              onTap: () async {
                Navigator.pop(context);
                final newMessage = Message(
                  title: "${m.title} (Copy)",
                  content: m.content,
                  imagePaths: m.imagePaths,
                  createdAt: DateTime.now().toString(),
                );
                await DatabaseHelper.instance.insertMessage(newMessage);
                if (mounted) setState(() {});
              },
            ),
            ListTile(
              leading: Icon(m.isDeleted == 1 ? Icons.delete_forever_rounded : Icons.delete_outline_rounded, color: Colors.red),
              title: Text(m.isDeleted == 1 ? "Delete Permanently" : "Move to Trash", style: const TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                if (m.isDeleted == 1) {
                  bool confirm = await _confirmAction("Delete this message permanently?");
                  if (!confirm) return;
                  await DatabaseHelper.instance.updateStatus(m.id!, "delete_forever");
                } else {
                  await DatabaseHelper.instance.updateStatus(m.id!, "trash");
                }
                if (mounted) setState(() {});
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTag(Message m) {
    Color col; String txt;
    if (m.isDeleted == 1) { col = const Color(0xFFF44336); txt = "Trash"; }
    else if (m.isPosted == 1) { col = const Color(0xFF4CAF50); txt = "Synced"; }
    else { col = const Color(0xFFFFC107); txt = "Draft"; }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: col, borderRadius: BorderRadius.circular(12)),
      child: Text(txt, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
    );
  }

  Widget _buildPlatformChips(List<String> platforms) {
    if (platforms.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      children: platforms.map((p) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _getPlatformColor(p).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _getPlatformColor(p).withValues(alpha: 0.2), width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_getPlatformIcon(p), size: 14, color: _getPlatformColor(p)),
            const SizedBox(width: 6),
            Text(
              p, 
              style: TextStyle(
                fontSize: 10, 
                fontWeight: FontWeight.bold, 
                color: _getPlatformColor(p),
                letterSpacing: 0.2,
              )
            ),
          ],
        ),
      )).toList(),
    );
  }

  IconData _getPlatformIcon(String p) {
    if (p.contains("Facebook")) return Icons.facebook;
    if (p.contains("Instagram")) return Icons.camera_alt_rounded;
    if (p.contains("LinkedIn")) return Icons.groups_rounded;
    if (p.contains("X (Twitter)")) return Icons.close_rounded;
    return Icons.share_rounded;
  }

  Color _getPlatformColor(String p) {
    if (p.contains("Facebook")) return const Color(0xFF1877F2);
    if (p.contains("Instagram")) return const Color(0xFFE1306C);
    if (p.contains("LinkedIn")) return const Color(0xFF0A66C2);
    if (p.contains("X (Twitter)")) return const Color(0xFF1A1F36);
    return Colors.grey;
  }

  void _showMessageDetail(Message m) {
    Navigator.push(context, MaterialPageRoute(
      fullscreenDialog: true,
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: const Text("Message Detail"),
          actions: [
            IconButton(icon: const Icon(Icons.edit_note_rounded), onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => AddMessageScreen(editMessage: m))).then((_) {
                if (mounted) setState(() {});
              });
            }),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (m.imagePaths.isNotEmpty) _buildDetailCarousel(m.imagePaths),
              const SizedBox(height: 24),
              Text(m.title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(m.content, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              if (m.isDeleted == 1)
                ElevatedButton.icon(
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    await DatabaseHelper.instance.updateStatus(m.id!, "restore");
                    if (!mounted) return;
                    navigator.pop(); 
                    setState(() {});
                  },
                  icon: const Icon(Icons.settings_backup_restore),
                  label: const Text("Restore to Drafts"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    elevation: 4,
                  ),
                )
              else
                Wrap(
                  spacing: 12, runSpacing: 12,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _showPlatformComposer(m), 
                      icon: const Icon(Icons.share), 
                      label: const Text("Syndicate Message"),
                      style: ElevatedButton.styleFrom(elevation: 4),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final navigator = Navigator.of(context);
                        await DatabaseHelper.instance.updateStatus(m.id!, "trash");
                        if (!mounted) return;
                        navigator.pop(); 
                        setState(() {});
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text("Move to Trash"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[50],
                        foregroundColor: Colors.red,
                        elevation: 2,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    )).then((_) {
      if (mounted) setState(() {});
    });
  }

  Widget _buildDetailCarousel(List<String> paths) {
    return SizedBox(
      height: 250,
      child: PageView.builder(
        itemCount: paths.length,
        itemBuilder: (context, index) => ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.file(File(paths[index]), fit: BoxFit.cover),
        ),
      ),
    );
  }

  void _showPlatformComposer(Message m) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: Text("PLATFORM COMPOSER", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2))),
            const SizedBox(height: 24),
            const Text("Select Target Channel", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildComposerGridItem(Icons.facebook, "Facebook", const Color(0xFF1877F2), m),
                _buildComposerGridItem(Icons.camera_alt_rounded, "Instagram", const Color(0xFFE4405F), m),
                _buildComposerGridItem(Icons.groups_rounded, "LinkedIn", const Color(0xFF0A66C2), m),
                _buildComposerGridItem(Icons.close_rounded, "X", const Color(0xFF1A1F36), m),
                _buildComposerGridItem(Icons.share_rounded, "System", Colors.grey, m),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildComposerGridItem(IconData icon, String label, Color color, Message message) {
    return InkWell(
      onTap: () => _executeShare(label, message),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _executeShare(String platform, Message m) async {
    final List<XFile> xFiles = m.imagePaths.map((path) => XFile(path)).toList();
    final String fullText = "${m.title}\n\n${m.content}";

    try {
      final ShareResult result;
      if (xFiles.isNotEmpty) {
        result = await Share.shareXFiles(xFiles, text: fullText);
      } else {
        result = await Share.shareWithResult(fullText);
      }

      if (result.status == ShareResultStatus.success) {
        List<String> platforms = List<String>.from(m.sharedPlatforms);
        if (!platforms.contains(platform)) platforms.add(platform);
        await DatabaseHelper.instance.updateStatus(m.id!, "sync", platforms: platforms);
        
        if (mounted) {
          Navigator.pop(context); 
          if (Navigator.canPop(context)) Navigator.pop(context); 
          setState(() {});
        }
      }
    } catch (e) {
      debugPrint("Handoff Error: $e");
    }
  }
}