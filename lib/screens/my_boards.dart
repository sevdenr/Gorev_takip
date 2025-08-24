import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trello/models/board.dart';
import 'package:trello/provider/app_provider.dart';
import 'package:trello/widgets/appBar.dart';
import 'board_detail_screen.dart';

class MyBoards extends StatelessWidget {
  const MyBoards({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppbarWidget(title: l10n.myBoards),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: StreamBuilder<QuerySnapshot>(
          // Hem sahip olduğum hem de görev aldığım panoları getir
          stream: _getBoardsStream(currentUserId),
          builder: (context, snapshot) {
            // Yükleniyor
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // Hata
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  '${l10n.errorOccurred} ${snapshot.error}',
                  style: TextStyle(
                    color: isDark ? Colors.red[200] : Colors.red[800],
                  ),
                ),
              );
            }

            // Veri yok
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Text(l10n.noBoards),
              );
            }

            // Board listesi
            final boards = snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final isOwner = data['ownerID'] == currentUserId;
              
              return BoardWithRole(
                board: Board(
                  id: doc.id,
                  title: data['title'] ?? '',
                  description: data['description'] ?? '',
                  color: _parseColor(data['color']),
                  tasks: [],
                ),
                isOwner: isOwner,
              );
            }).toList();

            return GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _getCrossAxisCount(context),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
              ),
              itemCount: boards.length,
              itemBuilder: (context, index) {
                return _buildBoardCard(boards[index], isDark, context, l10n);
              },
            );
          },
        ),
      ),
    );
  }

  /// Kullanıcının hem sahip olduğu hem de görev aldığı panoları getiren stream
  Stream<QuerySnapshot> _getBoardsStream(String currentUserId) {
    return FirebaseFirestore.instance
        .collection('Boards')
        .where(Filter.or(
          Filter('ownerID', isEqualTo: currentUserId), // Sahip olduğum panolar
          Filter('members', arrayContains: currentUserId), // Üye olduğum panolar
        ))
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Ekran genişliğine göre kaç sütun gösterileceğini belirler
  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 4;
    if (width > 800) return 3;
    if (width > 600) return 2;
    return 1;
  }

  /// Renk bilgisini güvenli şekilde parse eder
  Color _parseColor(dynamic colorValue) {
    if (colorValue is int) return Color(colorValue);
    if (colorValue is String) {
      try {
        return Color(int.parse(colorValue, radix: 16));
      } catch (_) {}
    }
    return Colors.grey; // Hata olursa varsayılan
  }

  /// Pano kartı widget'ı
  Widget _buildBoardCard(BoardWithRole boardWithRole, bool isDark, BuildContext context, AppLocalizations l10n) {
    final board = boardWithRole.board;
    final isOwner = boardWithRole.isOwner;
    
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        onTap: () => _navigateToBoard(board, context),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üst renk barı
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: board.color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
            ),
            // İçerik
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Başlık ve sahiplik durumu
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            board.title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827),
                            ),
                          ),
                        ),
                        // Sahiplik/üyelik göstergesi
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isOwner 
                                ? (isDark ? Colors.blue[800] : Colors.blue[100])
                                : (isDark ? Colors.orange[800] : Colors.orange[100]),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isOwner ? l10n.owner : l10n.member,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: isOwner 
                                  ? (isDark ? Colors.blue[200] : Colors.blue[800])
                                  : (isDark ? Colors.orange[200] : Colors.orange[800]),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Text(
                        board.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Görev sayısı ve kişisel görev sayısı
                    Row(
                      children: [
                        // Toplam görev sayısı
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('Boards')
                              .doc(board.id)
                              .collection('Tasks')
                              .snapshots(),
                          builder: (context, taskSnapshot) {
                            final count = taskSnapshot.hasData
                                ? taskSnapshot.data!.docs.length
                                : 0;
                            return Text(
                              '$count ${l10n.tasks}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                                fontWeight: FontWeight.w500,
                              ),
                            );
                          },
                        ),
                        // Kişisel görev sayısı (sadece üye olduğu panolarda)
                        if (!isOwner) ...[
                          const SizedBox(width: 8),
                          Text('•', style: TextStyle(
                            color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                          )),
                          const SizedBox(width: 8),
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('Boards')
                                .doc(board.id)
                                .collection('Tasks')
                                .where(Filter.or(
                                  Filter('assignee', isEqualTo: FirebaseAuth.instance.currentUser!.uid),
                                  Filter('assignees', arrayContains: FirebaseAuth.instance.currentUser!.uid),
                                ))
                                .snapshots(),
                            builder: (context, myTaskSnapshot) {
                              final myCount = myTaskSnapshot.hasData
                                  ? myTaskSnapshot.data!.docs.length
                                  : 0;
                              return Text(
                                '$myCount ${l10n.myTasks}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.orange[400] : Colors.orange[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToBoard(Board board, BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BoardDetailScreen(board: board),
      ),
    );
  }
}

/// Board ve kullanıcının rolünü birlikte tutan yardımcı sınıf
class BoardWithRole {
  final Board board;
  final bool isOwner;

  BoardWithRole({
    required this.board,
    required this.isOwner,
  });
}