import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/license_service.dart';

/// 首次启动授权闸门。本文件为定制分发版新增。
class ActivationScreen extends StatefulWidget {
  const ActivationScreen({super.key, required this.onActivated});

  final ValueChanged<LicenseInfo> onActivated;

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  final _controller = TextEditingController();
  late final Future<String> _deviceId = LicenseService.getDeviceId();
  String? _error;
  bool _busy = false;

  Future<void> _activate() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final info = await LicenseService.activate(_controller.text);
    if (!mounted) return;
    if (info.isValid) {
      widget.onActivated(info);
      return;
    }
    setState(() {
      _busy = false;
      _error = switch (info.result) {
        LicenseResult.badFormat => '格式错误：请输入 19 位字母数字卡密',
        LicenseResult.expired => '卡密已过期：请联系管理员换取新卡密',
        _ => '卡密无效：请核对后重试',
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            color: cs.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.eco, size: 42, color: cs.primary),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          '覓源方',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '设备授权激活',
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                        const SizedBox(height: 22),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: FutureBuilder<String>(
                            future: _deviceId,
                            builder: (context, snapshot) {
                              final id = snapshot.data ?? '正在生成…';
                              return Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '设备编号',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: cs.onSurfaceVariant,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        SelectableText(
                                          id,
                                          style: const TextStyle(
                                            fontFamily: 'monospace',
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: '复制设备编号',
                                    onPressed: snapshot.hasData
                                        ? () async {
                                            await Clipboard.setData(
                                              ClipboardData(text: id),
                                            );
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text('设备编号已复制'),
                                                ),
                                              );
                                            }
                                          }
                                        : null,
                                    icon: const Icon(Icons.copy),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _controller,
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontFamily: 'monospace',
                            letterSpacing: 1.5,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9A-Za-z]'),
                            ),
                            LengthLimitingTextInputFormatter(19),
                          ],
                          decoration: InputDecoration(
                            labelText: '19 位卡密',
                            helperText: '将设备编号发给管理员换取卡密',
                            errorText: _error,
                            border: const OutlineInputBorder(),
                          ),
                          onSubmitted: (_) {
                            if (!_busy) _activate();
                          },
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _busy ? null : _activate,
                            icon: _busy
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.lock_open),
                            label: const Text('激活并进入'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '授权校验完全在本机进行，无需联网。',
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
