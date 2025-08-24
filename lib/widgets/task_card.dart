import 'package:flutter/material.dart';
import '../models/task.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final bool isDark;
  final Map<String, String> userNames;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    required this.isDark,
    this.userNames = const {},
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Color(0xFFF9FAFB) : Color(0xFF111827),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _getPriorityColor(task.priority),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
              if (task.description.isNotEmpty) ...[
                SizedBox(height: 8),
                Text(
                  task.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Color(0xFFD1D5DB) : Color(0xFF6B7280),
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              SizedBox(height: 12),
              
              // Atanan kişiler ve tarih bilgisi
              if (task.assignees.isNotEmpty || task.deadline != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Atanan kişiler
                    if (task.assignees.isNotEmpty)
                      Row(
                        children: [
                          Icon(
                            Icons.person,
                            size: 14,
                            color: isDark ? Color(0xFF9CA3AF) : Color(0xFF6B7280),
                          ),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _getAssigneesText(),
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Color(0xFF9CA3AF) : Color(0xFF6B7280),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    
                    // Deadline tarihi
                    if (task.deadline != null) ...[
                      if (task.assignees.isNotEmpty) SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: isDark ? Color(0xFF9CA3AF) : Color(0xFF6B7280),
                          ),
                          SizedBox(width: 4),
                          Text(
                            _formatDate(task.deadline!.toDate()),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Color(0xFF9CA3AF) : Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getAssigneesText() {
    if (task.assignees.isEmpty) return '';
    
    final names = task.assignees.map((id) => userNames[id] ?? 'Bilinmeyen').toList();
    if (names.length == 1) {
      return names.first;
    } else if (names.length == 2) {
      return '${names[0]} & ${names[1]}';
    } else {
      return '${names[0]} & ${names.length - 1} diğer';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    
    if (difference == 0) {
      return 'Bugün';
    } else if (difference == 1) {
      return 'Yarın';
    } else if (difference == -1) {
      return 'Dün';
    } else if (difference > 0) {
      return '${difference} gün sonra';
    } else {
      return '${-difference} gün geçti';
    }
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return Color(0xFFEF4444);
      case TaskPriority.medium:
        return Color(0xFFF59E0B);
      case TaskPriority.low:
        return Color(0xFF10B981);
    }
  }
}