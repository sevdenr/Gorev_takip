import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task.dart';
import '../services/firestore_service.dart';

class UserSuggestion {
  final String id;
  final String email;
  final String? name;

  UserSuggestion({required this.id, required this.email, this.name});
}

class TaskDetailScreen extends StatefulWidget {
  final Task task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  _TaskDetailScreenState createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _assigneeController;
  late TextEditingController _deadlineController;
  late TaskPriority _priority;
  bool _isEditing = false;
  bool _isSaving = false;
  
  // Çoklu assignee için
  List<UserSuggestion> _userSuggestions = [];
  List<UserSuggestion> _selectedAssignees = [];
  bool _showSuggestions = false;
  Timer? _searchTimer;
  bool _isSearching = false;
  
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController = TextEditingController(text: widget.task.description);
    _assigneeController = TextEditingController();
    _deadlineController = TextEditingController();
    _priority = widget.task.priority;
    
    // Deadline'ı düzgün formatta göster
    if (widget.task.deadline != null) {
      _deadlineController.text = DateFormat('dd.MM.yyyy').format(widget.task.deadline!.toDate());
    }
    
    // Mevcut assignee'leri yükle
    _loadExistingAssignees();
    
    _assigneeController.addListener(_onAssigneeTextChanged);
  }

  Future<void> _loadExistingAssignees() async {
    // Ana assignee'yi yükle
    if (widget.task.assignee != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(widget.task.assignee)
            .get();
            
        if (doc.exists) {
          final data = doc.data()!;
          final user = UserSuggestion(
            id: doc.id,
            email: data['email'] ?? '',
            name: data['name'] ?? data['displayName'],
          );
          if (!_selectedAssignees.any((u) => u.id == user.id)) {
            setState(() {
              _selectedAssignees.add(user);
            });
          }
        }
      } catch (e) {
        print('Ana assignee yüklenirken hata: $e');
      }
    }
    
    // Tüm assignees'ları yükle
    if (widget.task.assignees.isNotEmpty) {
      try {
        for (String assigneeId in widget.task.assignees) {
          if (!_selectedAssignees.any((user) => user.id == assigneeId)) {
            final doc = await FirebaseFirestore.instance
                .collection('Users')
                .doc(assigneeId)
                .get();
                
            if (doc.exists) {
              final data = doc.data()!;
              final user = UserSuggestion(
                id: doc.id,
                email: data['email'] ?? '',
                name: data['name'] ?? data['displayName'],
              );
              setState(() {
                _selectedAssignees.add(user);
              });
            }
          }
        }
      } catch (e) {
        print('Assignees yüklenirken hata: $e');
      }
    }
  }

  void _onAssigneeTextChanged() {
    final text = _assigneeController.text.trim();
    
    if (text.isEmpty) {
      setState(() {
        _userSuggestions = [];
        _showSuggestions = false;
      });
      _searchTimer?.cancel();
      return;
    }

    if (text.length < 2) {
      setState(() {
        _showSuggestions = false;
      });
      return;
    }

    _searchTimer?.cancel();
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
      final querySnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .where('email', isGreaterThanOrEqualTo: query.toLowerCase())
          .where('email', isLessThan: query.toLowerCase() + 'z')
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
      print('Kullanıcı arama hatası: $e');
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
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Görev Detayları'),
        actions: [
          if (_isEditing)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveTask,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(8),
                ),
                child: _isSaving 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save, size: 20),
              ),
            )
          else
            TextButton(
              onPressed: () => setState(() => _isEditing = true),
              child: const Text(
                'Düzenle',
                style: TextStyle(
                  color: Color(0xFF3B82F6),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitleSection(isDark),
            const SizedBox(height: 24),
            _buildDescriptionSection(isDark),
            const SizedBox(height: 24),
            if (_isEditing) _buildEditableFields(isDark),
            if (!_isEditing) _buildMetadataSection(isDark),
            const SizedBox(height: 24),
            _buildActivitySection(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableFields(bool isDark) {
    return Column(
      children: [
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
                            : (isDark ? const Color(0xFF374151) : Colors.white),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? const Color(0xFF4B5563) : const Color(0xFFD1D5DB),
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
                              : (isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827)),
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
          'Bitiş Tarihi',
          TextField(
            controller: _deadlineController,
            decoration: InputDecoration(
              hintText: 'gg.aa.yyyy',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: isDark ? const Color(0xFF374151) : Colors.white,
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  setState(() {
                    _deadlineController.clear();
                  });
                },
              ),
            ),
            readOnly: true,
            onTap: _pickDeadline,
          ),
        ),
        const SizedBox(height: 20),
        _buildAssigneeSection(isDark),
        const SizedBox(height: 24),
      ],
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
        
        Column(
          children: [
            TextField(
              controller: _assigneeController,
              decoration: InputDecoration(
                hintText: 'Yeni kişi eklemek için e-posta yazın...',
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

  Widget _buildTitleSection(bool isDark) {
    return _isEditing
        ? TextField(
            controller: _titleController,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827),
            ),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: isDark ? const Color(0xFF374151) : Colors.white,
            ),
          )
        : Text(
            widget.task.title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827),
              height: 1.3,
            ),
          );
  }

  Widget _buildDescriptionSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Açıklama',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 8),
        _isEditing
            ? TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF374151) : Colors.white,
                ),
                maxLines: 4,
              )
            : Text(
                widget.task.description.isNotEmpty 
                    ? widget.task.description 
                    : 'Açıklama eklenmemiş',
                style: TextStyle(
                  fontSize: 16,
                  color: widget.task.description.isNotEmpty 
                      ? (isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151))
                      : (isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF)),
                  height: 1.5,
                  fontStyle: widget.task.description.isEmpty ? FontStyle.italic : FontStyle.normal,
                ),
              ),
      ],
    );
  }

  Widget _buildMetadataSection(bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildMetadataItem(
              Icons.flag,
              'Öncelik',
              _getPriorityText(_priority),
              _getPriorityColor(_priority),
              isDark,
              isPriority: true,
            ),
            const SizedBox(height: 16),
            _buildMetadataItem(
              Icons.people,
              'Atananlar',
              _getAssigneesDisplayText(),
              isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
              isDark,
            ),
            const SizedBox(height: 16),
            _buildMetadataItem(
              Icons.calendar_today,
              'Bitiş Tarihi',
              widget.task.deadline != null 
                  ? DateFormat('dd.MM.yyyy').format(widget.task.deadline!.toDate())
                  : 'Belirlenmemiş',
              isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
              isDark,
            ),
            const SizedBox(height: 16),
            _buildMetadataItem(
              Icons.info,
              'Durum',
              _getStatusText(widget.task.status),
              _getStatusColor(widget.task.status),
              isDark,
            ),
          ],
        ),
      ),
    );
  }

  String _getAssigneesDisplayText() {
    if (_selectedAssignees.isEmpty) {
      return 'Atanmamış';
    }
    return _selectedAssignees
        .map((user) => user.name?.isNotEmpty == true ? user.name! : user.email)
        .join(', ');
  }

  Widget _buildMetadataItem(IconData icon, String label, String value, Color iconColor, bool isDark, {bool isPriority = false}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              if (isPriority)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(_priority),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    value.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827),
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivitySection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Aktivite',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Görev ${DateFormat('dd.MM.yyyy HH:mm').format(widget.task.createdAt.toDate())} tarihinde oluşturuldu',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                  ),
                ),
                if (widget.task.updatedAt != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Son güncelleme: ${DateFormat('dd.MM.yyyy HH:mm').format(widget.task.updatedAt!.toDate())}',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getStatusText(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return 'Yapılacak';
      case TaskStatus.inProgress:
        return 'Devam Ediyor';
      case TaskStatus.done:
        return 'Tamamlandı';
    }
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return const Color(0xFF6B7280);
      case TaskStatus.inProgress:
        return const Color(0xFF3B82F6);
      case TaskStatus.done:
        return const Color(0xFF10B981);
    }
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
      initialDate: widget.task.deadline?.toDate() ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selectedDate != null) {
      setState(() {
        _deadlineController.text = DateFormat('dd.MM.yyyy').format(selectedDate);
      });
    }
  }

  Future<void> _saveTask() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Görev başlığı boş olamaz!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      Timestamp? deadlineTimestamp;
      if (_deadlineController.text.trim().isNotEmpty) {
        try {
          final parsedDate = DateFormat('dd.MM.yyyy').parse(_deadlineController.text.trim());
          deadlineTimestamp = Timestamp.fromDate(parsedDate);
        } catch (e) {
          throw Exception('Geçersiz tarih formatı. Lütfen gg.aa.yyyy formatında girin.');
        }
      }

      List<String> assigneeIds = _selectedAssignees.map((user) => user.id).toList();

      await _firestoreService.updateTask(
        taskId: widget.task.id,
        boardId: widget.task.boardId ?? '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        priority: _priority.name,
        assignee: assigneeIds.isNotEmpty ? assigneeIds.first : null,
        assignees: assigneeIds,
        deadline: deadlineTimestamp,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Görev başarıyla güncellendi!'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() => _isEditing = false);
        Navigator.pop(context, true); // Güncellendiğini belirt
      }
    } catch (e) {
      print('Görev güncellenirken hata: $e');
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

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _assigneeController.dispose();
    _deadlineController.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }
}