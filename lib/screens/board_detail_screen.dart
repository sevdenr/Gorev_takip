import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:trello/models/board.dart';
import 'package:trello/services/firestore_service.dart';
import '../models/task.dart';
import '../widgets/task_card.dart';
import 'task_detail_screen.dart';
import 'create_task_screen.dart';

class BoardDetailScreen extends StatefulWidget {
  final Board board;

  const BoardDetailScreen({super.key, required this.board});

  @override
  _BoardDetailScreenState createState() => _BoardDetailScreenState();
}

class _BoardDetailScreenState extends State<BoardDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  Map<String, String> _userNames = {};

  @override
  void initState() {
    super.initState();
    _loadUserNames();
  }

  Future<void> _loadUserNames() async {
    // Tüm taskları dinle ve kullanıcı adlarını yükle
    final stream = FirebaseFirestore.instance
        .collection('Boards')
        .doc(widget.board.id)
        .collection('Tasks')
        .snapshots();

    stream.listen((snapshot) async {
      final Set<String> allUserIds = {};
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['assignee'] != null) {
          allUserIds.add(data['assignee']);
        }
        if (data['assignees'] != null) {
          final assignees = List<String>.from(data['assignees']);
          allUserIds.addAll(assignees);
        }
      }

      if (allUserIds.isNotEmpty) {
        final userNames = await _firestoreService.getUserNamesByIds(allUserIds.toList());
        if (mounted) {
          setState(() {
            _userNames = userNames;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.board.title, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold ),),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert),
            onSelected: (String value) {
              switch (value) {
                case 'edit':
                  _editBoard();
                  break;
                case 'delete':
                  _showDeleteBoardDialog();
                  break;
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, color: Color(0xFF3B82F6)),
                    SizedBox(width: 8),
                    Text('Düzenle'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Sil', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Boards')
            .doc(widget.board.id)
            .collection('Tasks')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Görevler yüklenirken hata oluştu'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          // Firestore'dan gelen belgeleri Task objesine çeviriyoruz
          final tasks = snapshot.data!.docs.map((doc) {
            return Task.fromFirestore(doc).copyWith(boardId: widget.board.id);
          }).toList();

          // Kolon bazında filtreleme için hazırla
          List<Task> _filterTasks(TaskStatus status) =>
              tasks.where((task) => task.status == status).toList();

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildColumn('Yapılacaklar', TaskStatus.todo, isDark, _filterTasks(TaskStatus.todo)),
                SizedBox(width: 16),
                _buildColumn('Devam Edenler', TaskStatus.inProgress, isDark, _filterTasks(TaskStatus.inProgress)),
                SizedBox(width: 16),
                _buildColumn('Tamamlandı', TaskStatus.done, isDark, _filterTasks(TaskStatus.done)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildColumn(String title, TaskStatus status, bool isDark, List<Task> tasks) {
    return SizedBox(
      width: 280,
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Başlık ve task sayısı
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Color(0xFFF9FAFB) : Color(0xFF111827),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? Color(0xFF374151) : Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${tasks.length}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Color(0xFF9CA3AF) : Color(0xFF6B7280),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _showCreateTaskModal(status),
                        child: Icon(
                          Icons.add,
                          size: 20,
                          color: isDark ? Color(0xFF9CA3AF) : Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 16),
              
              // Sürükle-bırak özellikli liste
              SizedBox(
                height: 400,
                child: DragTarget<Task>(
                  onAccept: (task) async {
                    if (task.status != status) {
                      await _updateTaskStatus(task, status);
                    }
                  },
                  builder: (context, candidateData, rejectedData) {
                    return Container(
                      decoration: BoxDecoration(
                        color: candidateData.isNotEmpty 
                            ? (isDark ? Color(0xFF374151) : Color(0xFFF3F4F6))
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: candidateData.isNotEmpty 
                            ? Border.all(
                                color: Color(0xFF3B82F6),
                                width: 2,
                                style: BorderStyle.solid,
                              )
                            : null,
                      ),
                      child: ListView.builder(
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          return Draggable<Task>(
                            data: task,
                            feedback: Material(
                              elevation: 8,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: 250,
                                child: TaskCard(
                                  task: task,
                                  onTap: () {},
                                  isDark: isDark,
                                  userNames: _userNames,
                                ),
                              ),
                            ),
                            childWhenDragging: Opacity(
                              opacity: 0.5,
                              child: TaskCard(
                                task: task,
                                onTap: () {},
                                isDark: isDark,
                                userNames: _userNames,
                              ),
                            ),
                            child: GestureDetector(
                              onTap: () => _navigateToTask(task),
                              onLongPress: () => _showTaskActions(task),
                              child: TaskCard(
                                task: task,
                                onTap: () => _navigateToTask(task),
                                isDark: isDark,
                                userNames: _userNames,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateTaskStatus(Task task, TaskStatus newStatus) async {
    try {
      await _firestoreService.updateTaskStatus(
        boardId: widget.board.id,
        taskId: task.id,
        newStatus: newStatus.name,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Görev durumu güncellendi!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Durum güncellenirken hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _editBoard() {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController titleController = TextEditingController(text: widget.board.title);
        final TextEditingController descriptionController = TextEditingController(text: widget.board.description);

        return AlertDialog(
          title: Text('Panoyu Düzenle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Pano Başlığı',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'Açıklama',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Pano başlığı boş olamaz!'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  await _firestoreService.updateBoard(
                    boardId: widget.board.id,
                    title: titleController.text.trim(),
                    description: descriptionController.text.trim(),
                  );

                  Navigator.pop(context);
                  
                  // Board güncellendiğinde state'i güncelle
                  setState(() {
                    widget.board.title = titleController.text.trim();
                    widget.board.description = descriptionController.text.trim();
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Pano başarıyla güncellendi!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Pano güncellenirken hata oluştu: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text('Güncelle'),
            ),
          ],
        );
      },
    );
  }

  void _showTaskActions(Task task) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.edit, color: Color(0xFF3B82F6)),
              title: Text('Düzenle'),
              onTap: () {
                Navigator.pop(context);
                _navigateToTask(task);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text('Sil', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteTaskDialog(task);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteTaskDialog(Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Görevi Sil'),
        content: Text('Bu görevi silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteTask(task);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Sil'),
          ),
        ],
      ),
    );
  }

  void _showDeleteBoardDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Panoyu Sil'),
        content: Text('Bu panoyu ve tüm görevleri silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteBoard();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Sil'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTask(Task task) async {
    try {
      await _firestoreService.deleteTask(
        boardId: widget.board.id,
        taskId: task.id,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Görev başarıyla silindi!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Görev silinirken hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteBoard() async {
    try {
      await _firestoreService.deleteBoard(boardId: widget.board.id);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pano başarıyla silindi!'),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.pop(context); // Board detail sayfasından çık
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pano silinirken hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showCreateTaskModal(TaskStatus status) {
    Navigator.push<Task?>(
      context,
      MaterialPageRoute(
        builder: (context) => CreateTaskScreen(
          boardId: widget.board.id,
          initialStatus: status,
        ),
      ),
    ).then((newTask) {
      // Zaten stream olduğu için Firestore'dan otomatik güncellenecek
      if (newTask != null) {
        setState(() {
          // Stream otomatik güncelleme yapacak
        });
      }
    });
  }

  void _navigateToTask(Task task) {
    Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailScreen(task: task),
      ),
    ).then((wasUpdated) {
      if (wasUpdated == true) {
        setState(() {
          // Stream otomatik güncelleme yapacak
        });
      }
    });
  }
}