import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trello/models/board.dart';
import 'package:trello/provider/app_provider.dart';
import 'package:trello/widgets/appBar.dart';
import 'board_detail_screen.dart';

class BoardsScreen extends StatelessWidget {
  const BoardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppbarWidget(title: l10n.boards),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('Boards')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('${l10n.errorOccurred} ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(child: Text(l10n.noBoards));
            }

            final boards = snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return Board(
                id: doc.id,
                title: data['title'] ?? '',
                description: data['description'] ?? '',
                color: Color(int.parse(data['color'], radix: 16)),
                tasks: [], // Task sayısını ayrı StreamBuilder ile çekeceğiz
              );
            }).toList();

            return LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: boards.map((board) {
                      return SizedBox(
                        width: _getCardWidth(constraints.maxWidth),
                        child: _buildBoardCard(board, isDark, context, l10n),
                      );
                    }).toList(),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  double _getCardWidth(double screenWidth) {
    if (screenWidth > 1200) return (screenWidth - 20 * 2 - 16 * 3) / 4;
    if (screenWidth > 800) return (screenWidth - 20 * 2 - 16 * 2) / 3;
    if (screenWidth > 600) return (screenWidth - 20 * 2 - 16 * 1) / 2;
    return screenWidth - 20 * 2;
  }

  Widget _buildBoardCard(Board board, bool isDark, BuildContext context, AppLocalizations l10n) {
    return Card(
      child: InkWell(
        onTap: () => _navigateToBoard(board, context),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    board.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    board.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Gerçek zamanlı task sayısını gösteren StreamBuilder
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('Boards')
                        .doc(board.id)
                        .collection('Tasks')
                        .snapshots(),
                    builder: (context, taskSnapshot) {
                      if (taskSnapshot.hasError) {
                        return Text(
                          '0 ${l10n.tasks}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      }
                      
                      if (taskSnapshot.connectionState == ConnectionState.waiting) {
                        return Text(
                          '-- ${l10n.tasks}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      }

                      final taskCount = taskSnapshot.hasData ? taskSnapshot.data!.docs.length : 0;
                      
                      return Text(
                        '$taskCount ${l10n.tasks}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    },
                  ),
                ],
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
        builder: (context) => BoardDetailScreen(board: board),
      ),
    );
  }
}