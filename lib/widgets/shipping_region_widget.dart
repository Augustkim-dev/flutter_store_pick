import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/shipping_region.dart';
import '../theme/app_colors.dart';

class ShippingRegionWidget extends StatefulWidget {
  final List<ShippingRegion> regions;
  final ValueChanged<List<ShippingRegion>> onRegionsChanged;
  final String shopId;

  const ShippingRegionWidget({
    Key? key,
    required this.regions,
    required this.onRegionsChanged,
    required this.shopId,
  }) : super(key: key);

  @override
  State<ShippingRegionWidget> createState() => _ShippingRegionWidgetState();
}

class _ShippingRegionWidgetState extends State<ShippingRegionWidget> {
  late List<ShippingRegion> _regions;
  final Map<String, TextEditingController> _feeControllers = {};
  final Map<String, TextEditingController> _daysControllers = {};
  bool _useUniformFee = false;
  String _uniformFee = '3000';

  @override
  void initState() {
    super.initState();
    _initializeRegions();
  }

  void _initializeRegions() {
    if (widget.regions.isEmpty) {
      // 기본 지역 목록으로 초기화
      _regions = ShippingRegion.defaultRegions.map((regionName) {
        final region = ShippingRegion(
          id: '${widget.shopId}_$regionName',
          shopId: widget.shopId,
          regionName: regionName,
          shippingFee: 3000,
          estimatedDays: regionName == '제주' ? 3 : 2,
        );
        
        _feeControllers[regionName] = TextEditingController(
          text: region.shippingFee.toString(),
        );
        _daysControllers[regionName] = TextEditingController(
          text: region.estimatedDays.toString(),
        );
        
        return region;
      }).toList();
    } else {
      _regions = List.from(widget.regions);
      for (var region in _regions) {
        _feeControllers[region.regionName] = TextEditingController(
          text: region.shippingFee.toString(),
        );
        _daysControllers[region.regionName] = TextEditingController(
          text: region.estimatedDays.toString(),
        );
      }
    }
  }

  @override
  void dispose() {
    _feeControllers.values.forEach((controller) => controller.dispose());
    _daysControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  void _applyUniformFee() {
    final fee = int.tryParse(_uniformFee) ?? 3000;
    setState(() {
      _regions = _regions.map((region) {
        _feeControllers[region.regionName]?.text = fee.toString();
        return ShippingRegion(
          id: region.id,
          shopId: region.shopId,
          regionName: region.regionName,
          shippingFee: fee,
          estimatedDays: region.estimatedDays,
          createdAt: region.createdAt,
        );
      }).toList();
    });
    widget.onRegionsChanged(_regions);
  }

  void _updateRegion(String regionName, {int? fee, int? days}) {
    final index = _regions.indexWhere((r) => r.regionName == regionName);
    if (index != -1) {
      final region = _regions[index];
      _regions[index] = ShippingRegion(
        id: region.id,
        shopId: region.shopId,
        regionName: region.regionName,
        shippingFee: fee ?? region.shippingFee,
        estimatedDays: days ?? region.estimatedDays,
        createdAt: region.createdAt,
      );
      widget.onRegionsChanged(_regions);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 일괄 설정
        Card(
          color: AppColors.primaryPink.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '일괄 설정',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Checkbox(
                      value: _useUniformFee,
                      onChanged: (value) {
                        setState(() {
                          _useUniformFee = value ?? false;
                        });
                      },
                      activeColor: AppColors.primaryPink,
                    ),
                    const Text('모든 지역 동일 배송비'),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 100,
                      child: TextField(
                        enabled: _useUniformFee,
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(),
                          suffixText: '원',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (value) {
                          _uniformFee = value;
                        },
                        controller: TextEditingController(text: _uniformFee),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _useUniformFee ? _applyUniformFee : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPink,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      child: const Text('적용'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 지역별 설정 테이블
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              // 테이블 헤더
              Container(
                color: Colors.grey.shade100,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(
                        '지역',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '배송비',
                        style: TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '예상 일수',
                        style: TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // 지역별 행
              SizedBox(
                height: 400,
                child: ListView.separated(
                  itemCount: _regions.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final region = _regions[index];
                    final isSpecial = region.regionName == '제주' || 
                                     region.regionName == '강원';
                    
                    return Container(
                      color: isSpecial ? Colors.yellow.shade50 : null,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 80,
                            child: Text(
                              region.regionName,
                              style: TextStyle(
                                fontWeight: isSpecial ? FontWeight.bold : null,
                                color: isSpecial ? Colors.orange.shade700 : null,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: TextFormField(
                                controller: _feeControllers[region.regionName],
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                  border: const OutlineInputBorder(),
                                  suffixText: '원',
                                  filled: isSpecial,
                                  fillColor: Colors.orange.shade50,
                                ),
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                onChanged: (value) {
                                  final fee = int.tryParse(value);
                                  if (fee != null) {
                                    _updateRegion(region.regionName, fee: fee);
                                  }
                                },
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: TextFormField(
                                controller: _daysControllers[region.regionName],
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                  border: OutlineInputBorder(),
                                  suffixText: '일',
                                ),
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(1),
                                ],
                                onChanged: (value) {
                                  final days = int.tryParse(value);
                                  if (days != null) {
                                    _updateRegion(region.regionName, days: days);
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 도움말
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: Colors.blue.shade700,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '• 제주 및 도서산간 지역은 추가 배송비를 설정하세요\n'
                  '• 예상 일수는 영업일 기준입니다\n'
                  '• 무료배송 조건은 온라인 탭에서 설정하세요',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}