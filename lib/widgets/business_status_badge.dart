import 'package:flutter/material.dart';
import '../models/shop.dart';

class BusinessStatusBadge extends StatelessWidget {
  final Shop shop;

  const BusinessStatusBadge({
    Key? key,
    required this.shop,
  }) : super(key: key);

  bool _isOpenNow() {
    // TODO: 실제 영업시간 데이터로 판단
    final now = DateTime.now();
    final hour = now.hour;
    final weekday = now.weekday;
    
    // 기본 영업시간: 평일 10-20, 주말 10-18
    if (weekday >= 1 && weekday <= 5) {
      return hour >= 10 && hour < 20;
    } else {
      return hour >= 10 && hour < 18;
    }
  }

  bool _isLunchTime() {
    final now = DateTime.now();
    final hour = now.hour;
    
    // 기본 점심시간: 12-13시
    return hour == 12;
  }

  @override
  Widget build(BuildContext context) {
    final isOpen = _isOpenNow();
    final isLunch = _isLunchTime();
    
    Color backgroundColor;
    IconData icon;
    String text;
    
    if (!isOpen) {
      backgroundColor = Colors.red;
      icon = Icons.block;
      text = '휴무';
    } else if (isLunch) {
      backgroundColor = Colors.orange;
      icon = Icons.lunch_dining;
      text = '점심시간';
    } else {
      backgroundColor = Colors.green;
      icon = Icons.access_time;
      text = '영업중';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}