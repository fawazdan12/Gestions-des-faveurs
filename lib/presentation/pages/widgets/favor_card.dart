import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gestion_favor/data/models/favor.dart';

class FavorCard extends StatelessWidget {
  final Favor favor;
  final VoidCallback? onAccept;
  final VoidCallback? onRefuse;
  final VoidCallback? onComplete;

  const FavorCard({
    Key? key,
    required this.favor,
    this.onAccept,
    this.onRefuse,
    this.onComplete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    favor.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildStatusChip(),
              ],
            ),
            SizedBox(height: 8),
            Text(
              favor.description,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            SizedBox(height: 8),
            Text(
              'Demandé le ${DateFormat('dd/MM/yyyy à HH:mm').format(favor.createdAt)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            if (_shouldShowActions()) ...[
              SizedBox(height: 12),
              _buildActionButtons(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    Color color;
    String text;

    switch (favor.status) {
      case FavorStatus.pending:
        color = Colors.orange;
        text = 'En attente';
        break;
      case FavorStatus.accepted:
        color = Colors.blue;
        text = 'Acceptée';
        break;
      case FavorStatus.refused:
        color = Colors.red;
        text = 'Refusée';
        break;
      case FavorStatus.completed:
        color = Colors.green;
        text = 'Terminée';
        break;
    }

    return Chip(
      label: Text(text, style: TextStyle(color: Colors.white, fontSize: 12)),
      backgroundColor: color,
    );
  }

  bool _shouldShowActions() {
    return favor.status == FavorStatus.pending || favor.status == FavorStatus.accepted;
  }

  Widget _buildActionButtons() {
    if (favor.status == FavorStatus.pending) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: onRefuse,
            child: Text('Refuser', style: TextStyle(color: Colors.red)),
          ),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: onAccept,
            child: Text('Accepter'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
        ],
      );
    } else if (favor.status == FavorStatus.accepted) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton(
            onPressed: onComplete,
            child: Text('Terminer'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          ),
        ],
      );
    }

    return SizedBox.shrink();
  }
}