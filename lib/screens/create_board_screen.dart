import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:trello/models/user.dart';
import 'package:provider/provider.dart';
import 'package:trello/provider/app_provider.dart';
import 'package:trello/provider/auth_provider.dart';
import 'package:trello/router.dart';
import 'package:trello/services/firestore_service.dart';

class CreateBoardScreen extends StatefulWidget {
  const CreateBoardScreen({super.key});

  @override
  State<CreateBoardScreen> createState() => _CreateBoardScreenState();
}

class _CreateBoardScreenState extends State<CreateBoardScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  Color _selectedColor = const Color(0xFF3B82F6);
  final _firestore = FirestoreService();
  bool _isCreating = false;

  final List<Color> _boardColors = const [
    Color(0xFF3B82F6), Color(0xFF8B5CF6), Color(0xFF10B981), Color(0xFFF59E0B),
    Color(0xFFEF4444), Color(0xFFEC4899), Color(0xFF06B6D4), Color(0xFF84CC16),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);
    final userModel = authProvider.userModel;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.createBoard,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton(
              onPressed: (_titleController.text.trim().isNotEmpty && 
                         userModel != null && 
                         !_isCreating)
                  ? () => _createBoard(userModel)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(8),
              ),
              child: _isCreating 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.check, size: 20),
            ),
          ),
        ],
      ),
      body: userModel == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPreview(isDark),
                  const SizedBox(height: 24),
                  _buildForm(isDark),
                ],
              ),
            ),
    );
  }

  Widget _buildPreview(bool isDark) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: _selectedColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _titleController.text.isEmpty
                      ? 'Pano Başlığı'
                      : _titleController.text,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _descriptionController.text.isEmpty
                      ? 'Pano açıklaması'
                      : _descriptionController.text,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputGroup(
          'Pano Başlığı',
          TextField(
            controller: _titleController,
            enabled: !_isCreating,
            decoration: InputDecoration(
              hintText: 'Pano başlığını girin',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: isDark ? const Color(0xFF374151) : Colors.white,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: 20),
        _buildInputGroup(
          'Açıklama',
          TextField(
            controller: _descriptionController,
            enabled: !_isCreating,
            decoration: InputDecoration(
              hintText: 'Pano açıklamasını girin',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: isDark ? const Color(0xFF374151) : Colors.white,
            ),
            maxLines: 3,
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: 20),
        _buildInputGroup(
          'Pano Rengi',
          Wrap(
            spacing: 10,
            children: _boardColors.map((color) {
              final isSelected = _selectedColor == color;
              return GestureDetector(
                onTap: _isCreating ? null : () => setState(() => _selectedColor = color),
                child: Container(
                  width: 35,
                  height: 35,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                    border: isSelected
                        ? Border.all(color: isDark ? Colors.white : Colors.black, width: 3)
                        : null,
                    boxShadow: isSelected
                        ? [const BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))]
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildInputGroup(String label, Widget child) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Future<void> _createBoard(UserModel userModel) async {
    if (_titleController.text.trim().isEmpty || _isCreating) return;

    setState(() {
      _isCreating = true;
    });

    final colorString = _selectedColor.value.toRadixString(16);

    try {
      await _firestore.dataUpdateBoard(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        color: colorString,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pano başarıyla oluşturuldu!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        
        // Ana boards sayfasına git
        context.go(AppRouter.home);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pano oluşturulurken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}