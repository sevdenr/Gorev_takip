import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trello/provider/app_provider.dart';

import '../models/task.dart';
import '../services/firestore_service.dart';

class UserSuggestion {
  final String id;
  final String email;
  final String? name;

  UserSuggestion({required this.id, required this.email, this.name});
}

class CreateTaskScreen extends StatefulWidget {
  final TaskStatus initialStatus;
  final String boardId;

  const CreateTaskScreen({
    super.key,
    required this.initialStatus,
    required this.boardId,
  });

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _assigneeController = TextEditingController();
  final _deadlineController = TextEditingController();

  TaskPriority _priority = TaskPriority.medium;
  final FirestoreService _firestoreService = FirestoreService();

  bool _isSaving = false;
  List<UserSuggestion> _userSuggestions = [];
  List<UserSuggestion> _selectedAssignees = [];
  bool _showSuggestions = false;
  Timer? _searchTimer;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _assigneeController.addListener(_onAssigneeTextChanged);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _assigneeController.dispose();
    _deadlineController.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  void _onAssigneeTextChanged() {
    final text = _assigneeController.text.trim();
    
    // Eğer text boşsa, önerileri temizle
    if (text.isEmpty) {
      setState(() {
        _userSuggestions = [];
        _showSuggestions = false;
      });
      _searchTimer?.cancel();
      return;
    }

    // Minimum 2 karakter gerekli
    if (text.length < 2) {
      setState(() {
        _showSuggestions = false;
      });
      return;
    }

    // Önceki timer'ı iptal et
    _searchTimer?.cancel();
    
    // 500ms bekle, sonra arama yap (debouncing)
    _searchTimer = Timer(const Duration(milliseconds: 500), () {
      _searchUsers(text);
    });
  }

  Future<void> _searchUsers(String query) async {
    if (query.length < 2) return;

    setState(() {
      _isSearching = true;
    });

    try {
      // Firestore'da email alanında arama yap
      final querySnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .where('mail', isGreaterThanOrEqualTo: query.toLowerCase())
          .where('mail', isLessThan: query.toLowerCase() + 'z')
          .limit(5)
          .get();

      final suggestions = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return UserSuggestion(
          id: doc.id,
          email: data['email'] ?? '',
          name: data['name'] ?? data['displayName'],
        );
      }).where((user) {
        // Zaten seçili olmayan kullanıcıları filtrele
        return !_selectedAssignees.any((selected) => selected.id == user.id);
      }).toList();

      if (mounted) {
        setState(() {
          _userSuggestions = suggestions;
          _showSuggestions = suggestions.isNotEmpty;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Kullanıcı arama hatası: $e');
      }
      if (mounted) {
        setState(() {
          _isSearching = false;
          _showSuggestions = false;
        });
      }
    }
  }

  void _selectUser(UserSuggestion user) {
    setState(() {
      _selectedAssignees.add(user);
      _assigneeController.clear();
      _userSuggestions = [];
      _showSuggestions = false;
    });
  }

  void _removeAssignee(UserSuggestion user) {
    setState(() {
      _selectedAssignees.removeWhere((assignee) => assignee.id == user.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.createTask, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold ),) ,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton(
              onPressed: _titleController.text.trim().isNotEmpty && !_isSaving
                  ? _createTask
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(8),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.add, size: 20),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInputGroup(
              'Görev Başlığı',
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'Görev başlığını girin',
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
                decoration: InputDecoration(
                  hintText: 'Görev açıklamasını girin',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF374151) : Colors.white,
                ),
                maxLines: 4,
              ),
            ),
            const SizedBox(height: 20),
            _buildInputGroup(
              'Öncelik',
              Row(
                children: TaskPriority.values.map((priority) {
                  final isSelected = _priority == priority;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _priority = priority),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? _getPriorityColor(priority)
                                : (isDark
                                    ? const Color(0xFF374151)
                                    : Colors.white),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF4B5563)
                                  : const Color(0xFFD1D5DB),
                            ),
                          ),
                          child: Text(
                            _getPriorityText(priority),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark
                                      ? const Color(0xFFF9FAFB)
                                      : const Color(0xFF111827)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            _buildInputGroup(
              'Bitiş Tarihi (İsteğe bağlı)',
              TextField(
                controller: _deadlineController,
                decoration: InputDecoration(
                  hintText: 'gg.aa.yyyy',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF374151) : Colors.white,
                  suffixIcon: _deadlineController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _deadlineController.clear();
                            });
                          },
                        )
                      : Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: _pickDeadline,
              ),
            ),
            const SizedBox(height: 20),
            _buildAssigneeSection(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildAssigneeSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Atanan Kişiler',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 8),
        
        // Seçili kullanıcıların chip'leri
        if (_selectedAssignees.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedAssignees.map((user) {
              return Chip(
                label: Text(
                  user.name?.isNotEmpty == true ? user.name! : user.email,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                deleteIcon: Icon(
                  Icons.close,
                  size: 16,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                onDeleted: () => _removeAssignee(user),
                backgroundColor: isDark ? const Color(0xFF4B5563) : const Color(0xFFE5E7EB),
                side: BorderSide(
                  color: isDark ? const Color(0xFF6B7280) : const Color(0xFFD1D5DB),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
        ],
        
        // TextField ve öneriler
        Column(
          children: [
            TextField(
              controller: _assigneeController,
              decoration: InputDecoration(
                hintText: 'E-posta adresi yazın...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF374151) : Colors.white,
                suffixIcon: _isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
            ),
            
            // Öneri listesi
            if (_showSuggestions && _userSuggestions.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF374151) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? const Color(0xFF4B5563) : const Color(0xFFD1D5DB),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: _userSuggestions.map((user) {
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF3B82F6),
                        radius: 16,
                        child: Text(
                          (user.name?.isNotEmpty == true 
                              ? user.name!.substring(0, 1).toUpperCase()
                              : user.email.substring(0, 1).toUpperCase()),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        user.name?.isNotEmpty == true ? user.name! : user.email,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827),
                        ),
                      ),
                      subtitle: user.name?.isNotEmpty == true
                          ? Text(
                              user.email,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                              ),
                            )
                          : null,
                      onTap: () => _selectUser(user),
                    );
                  }).toList(),
                ),
              ),
          ],
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

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return const Color(0xFFEF4444);
      case TaskPriority.medium:
        return const Color(0xFFF59E0B);
      case TaskPriority.low:
        return const Color(0xFF10B981);
    }
  }

  String _getPriorityText(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return 'Yüksek';
      case TaskPriority.medium:
        return 'Orta';
      case TaskPriority.low:
        return 'Düşük';
    }
  }

  Future<void> _pickDeadline() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(), // Geçmiş tarih seçilmesin
      lastDate: DateTime(2100),
    );
    if (selectedDate != null) {
      setState(() {
        _deadlineController.text = DateFormat('dd.MM.yyyy').format(selectedDate);
      });
    }
  }

  Future<void> _createTask() async {
    if (_titleController.text.trim().isEmpty) return;

    setState(() => _isSaving = true);

    try {
      Timestamp? deadlineTimestamp;
      if (_deadlineController.text.trim().isNotEmpty) {
        try {
          final parsedDate = DateFormat('dd.MM.yyyy').parse(_deadlineController.text.trim());
          deadlineTimestamp = Timestamp.fromDate(parsedDate);
          if (kDebugMode) {
            print('Deadline timestamp oluşturuldu: $deadlineTimestamp');
          }
        } catch (e) {
          if (kDebugMode) {
            print('Tarih parse hatası: $e');
          }
          throw Exception('Geçersiz tarih formatı. Lütfen gg.aa.yyyy formatında girin.');
        }
      }

      // Seçili assignee ID'lerini al
      List<String> assigneeIds = _selectedAssignees.map((user) => user.id).toList();

      if (kDebugMode) {
        print('Görev oluşturuluyor:');
        print('- Başlık: ${_titleController.text.trim()}');
        print('- Açıklama: ${_descriptionController.text.trim()}');
        print('- Öncelik: ${_priority.name}');
        print('- Assignee IDs: $assigneeIds');
        print('- Deadline: $deadlineTimestamp');
        print('- Board ID: ${widget.boardId}');
        print('- Status: ${widget.initialStatus.name}');
      }

      await _firestoreService.createTask(
        boardId: widget.boardId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        priority: _priority.name,
        assignee: assigneeIds.isNotEmpty ? assigneeIds.first : null,
        assignees: assigneeIds,
        status: widget.initialStatus.name,
        deadline: deadlineTimestamp,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Görev başarıyla oluşturuldu!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Görev oluşturma hatası: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}