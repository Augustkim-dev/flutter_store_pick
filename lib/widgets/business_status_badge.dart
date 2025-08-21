import 'package:flutter/material.dart';
import '../models/shop.dart';
import '../utils/business_hours_parser.dart';

class BusinessStatusBadge extends StatelessWidget {
  final Shop shop;

  const BusinessStatusBadge({
    Key? key,
    required this.shop,
  }) : super(key: key);

  bool _isOpenNow() {
    return BusinessHoursParser.isOpenNow(shop.businessHours);
  }

  bool _isLunchTime() {
    return BusinessHoursParser.isLunchTime(shop.businessHours);
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