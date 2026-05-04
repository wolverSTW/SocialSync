import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../services/database_helper.dart';
import '../models/message.dart';

class AddMessageScreen extends StatefulWidget {
  final Message? editMessage;
  const AddMessageScreen({super.key, this.editMessage});

  @override
  State<AddMessageScreen> createState() => _AddMessageScreenState();
}

class _AddMessageScreenState extends State<AddMessageScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  List<File> _images = [];
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    if (widget.editMessage != null) {
      _titleController.text = widget.editMessage!.title;
      _contentController.text = widget.editMessage!.content;
      _images = widget.editMessage!.imagePaths.map((p) => File(p)).toList();
    }
    
    _titleController.addListener(_markDirty);
    _contentController.addListener(_markDirty);
  }

  void _markDirty() {
    if (!_isDirty) setState(() => _isDirty = true);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImages(ImageSource source) async {
    _markDirty();
    if (source == ImageSource.gallery) {
      final List<XFile> pickedFiles = await ImagePicker().pickMultiImage();
      if (pickedFiles.isNotEmpty) {
        setState(() {
          _images.addAll(pickedFiles.map((x) => File(x.path)));
        });
      }
    } else {
      final XFile? pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        setState(() {
          _images.add(File(pickedFile.path));
        });
      }
    }
  }

  void _removeImage(int index) {
    _markDirty();
    setState(() {
      _images.removeAt(index);
    });
  }

  Future<bool> _showDiscardDialog() async {
    if (!_isDirty) return true;
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Discard Changes?"),
        content: const Text("You have unsaved edits. Are you sure you want to leave?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Keep Editing")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true), 
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[50], foregroundColor: Colors.red),
            child: const Text("Discard"),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.editMessage != null;

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _showDiscardDialog();
        if (shouldPop && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEdit ? "Edit Message" : "Create New Message"),
          actions: [
            IconButton(
              icon: const Icon(Icons.check_circle_outline_rounded),
              onPressed: _saveMessage,
              color: theme.colorScheme.secondary,
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Message Details", style: theme.textTheme.titleMedium),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: "Headline / Title",
                  prefixIcon: Icon(Icons.title_rounded),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _contentController,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: "Message Body",
                  hintText: "What would you like to share?",
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 32),
              Text("Attachment Gallery", style: theme.textTheme.titleMedium),
              const SizedBox(height: 16),
              _buildImageCarousel(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _pickImages(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_rounded),
                      label: const Text("Camera"),
                      style: ElevatedButton.styleFrom(elevation: 4, padding: const EdgeInsets.symmetric(vertical: 12)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _pickImages(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_rounded),
                      label: const Text("Gallery"),
                      style: ElevatedButton.styleFrom(elevation: 4, padding: const EdgeInsets.symmetric(vertical: 12)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _saveMessage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 8,
                  ),
                  child: Text(isEdit ? "UPDATE" : "CREATE"),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageCarousel() {
    if (_images.isEmpty) {
      return Container(
        height: 180, width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text("No images attached", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _images.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(_images[index], height: 180, width: 180, fit: BoxFit.cover),
                ),
                Positioned(
                  top: 8, right: 8,
                  child: GestureDetector(
                    onTap: () => _removeImage(index),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                      child: const Icon(Icons.close, color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _saveMessage() async {
    if (_titleController.text.isEmpty) return;
    setState(() => _isDirty = false);
    
    final message = Message(
      id: widget.editMessage?.id,
      title: _titleController.text,
      content: _contentController.text,
      imagePaths: _images.map((f) => f.path).toList(),
      createdAt: widget.editMessage?.createdAt ?? DateTime.now().toString(),
      postedAt: widget.editMessage?.postedAt,
      deletedAt: widget.editMessage?.deletedAt,
      isPosted: widget.editMessage?.isPosted ?? 0,
      isDeleted: widget.editMessage?.isDeleted ?? 0,
    );

    if (widget.editMessage != null) {
      await DatabaseHelper.instance.updateMessage(message);
    } else {
      await DatabaseHelper.instance.insertMessage(message);
    }

    if (mounted) Navigator.pop(context);
  }
}