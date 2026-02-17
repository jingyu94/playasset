import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AssetDetailField {
  const AssetDetailField({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;
}

class AssetDetailSheetData {
  const AssetDetailSheetData({
    required this.assetName,
    required this.symbol,
    this.price,
    this.changeRate,
    this.note,
    this.fields = const [],
  });

  final String assetName;
  final String symbol;
  final double? price;
  final double? changeRate;
  final String? note;
  final List<AssetDetailField> fields;
}

Future<void> showAssetDetailSheet(
  BuildContext context, {
  required AssetDetailSheetData data,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final won =
      NumberFormat.currency(locale: 'ko_KR', symbol: '₩ ', decimalDigits: 0);
  final changeRate = data.changeRate;
  final hasChangeRate = changeRate != null;
  final changeUp = (changeRate ?? 0) >= 0;
  final changeColor =
      changeUp ? const Color(0xFFFF6B81) : const Color(0xFF5CA8FF);

  Color subText(BuildContext ctx) {
    final dark = Theme.of(ctx).brightness == Brightness.dark;
    return dark ? const Color(0xFF8FA1C0) : const Color(0xFF4A6581);
  }

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: isDark ? const Color(0xFF101A2B) : const Color(0xFFF7FAFF),
    builder: (ctx) {
      final borderColor =
          isDark ? const Color(0xFF2A3E63) : const Color(0xFFD0E4DE);
      final fieldBg =
          isDark ? const Color(0xFF12213A) : const Color(0xFFF7FCFA);
      final fieldValueText =
          isDark ? const Color(0xFFEAF1FF) : const Color(0xFF1A2D45);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.assetName,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 3),
              Text(data.symbol, style: TextStyle(color: subText(ctx))),
              if (data.price != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      won.format(data.price),
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w900),
                    ),
                    if (hasChangeRate) ...[
                      const SizedBox(width: 8),
                      Text(
                        '${changeUp ? '+' : ''}${changeRate.toStringAsFixed(2)}%',
                        style: TextStyle(
                            color: changeColor, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ],
                ),
              ],
              if (data.fields.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: fieldBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    children: [
                      for (int i = 0; i < data.fields.length; i++) ...[
                        if (i > 0)
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: borderColor,
                          ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  data.fields[i].label,
                                  style: TextStyle(
                                      color: subText(ctx),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                data.fields[i].value,
                                style: TextStyle(
                                  color: data.fields[i].valueColor ??
                                      fieldValueText,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              if ((data.note ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(data.note!.trim(), style: TextStyle(color: subText(ctx))),
              ],
              const SizedBox(height: 14),
              const Text('관련 뉴스',
                  style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(
                '뉴스 연동 준비중',
                style: TextStyle(color: subText(ctx), fontSize: 12.5),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('닫기'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
