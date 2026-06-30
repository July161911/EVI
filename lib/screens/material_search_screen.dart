import 'package:flutter/cupertino.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:evi/models/material_item.dart';
import 'package:evi/services/bluetooth_service.dart';
import 'package:evi/services/led_bluetooth_command_service.dart';
import 'package:evi/services/material_service.dart';
import 'package:evi/theme/app_theme.dart';
import 'package:evi/theme/theme_aware.dart';
import 'package:evi/widgets/app_page_shell.dart';
import 'package:evi/widgets/common_widgets.dart';

class MaterialSearchScreen extends StatefulWidget {
  const MaterialSearchScreen({super.key});

  @override
  State<MaterialSearchScreen> createState() => _MaterialSearchScreenState();
}

class _MaterialSearchScreenState extends State<MaterialSearchScreen>
    with ThemeAwareState {
  final _bluetooth = ShelfBluetoothService();
  final _queryController = TextEditingController();
  List<MaterialItem> _results = [];
  MaterialItem? _selectedItem;
  String? _sendStatus;
  bool _isLoadingCatalog = true;
  bool _hasSearched = false;
  bool _isSendingCommand = false;
  String? _catalogError;

  @override
  void initState() {
    super.initState();
    _bluetooth.addListener(_onBluetoothChanged);
    _loadCatalog();
  }

  Future<void> _loadCatalog({bool forceRefresh = false}) async {
    setState(() {
      _isLoadingCatalog = true;
      _catalogError = null;
    });

    try {
      await MaterialService.instance.loadFromExcel(forceRefresh: forceRefresh);
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingCatalog = false;
        if (_hasSearched && _queryController.text.trim().isNotEmpty) {
          _results = MaterialService.instance.search(_queryController.text);
        }
      });
    } catch (error) {
      MaterialService.instance.rememberLoadError(error);
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingCatalog = false;
        _catalogError = error.toString();
        _results = [];
      });
    }
  }

  void _onBluetoothChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _runQuery() async {
    if (!MaterialService.instance.isLoaded || _isSendingCommand) {
      return;
    }

    final query = _queryController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _hasSearched = false;
        _results = [];
        _selectedItem = null;
        _sendStatus = null;
      });
      return;
    }

    setState(() {
      _hasSearched = true;
      _results = MaterialService.instance.search(query);
      _selectedItem = null;
      _sendStatus = null;
    });

    await _sendBluetoothCommands();
  }

  Future<void> _sendBluetoothCommands() async {
    if (_results.isEmpty) {
      setState(() {
        _sendStatus = '查询完成，无匹配结果，未发送蓝牙指令。';
      });
      return;
    }

    if (!_bluetooth.isConnected) {
      setState(() {
        _sendStatus = '查询完成。请连接蓝牙后重新精确查询以发送指令。';
      });
      return;
    }

    if (_isSendingCommand) {
      return;
    }

    final item = _results.first;
    final ledCommands = LedBluetoothCommandService.instance;
    ledCommands.prepareFromMaterial(item);
    final led0 = ledCommands.buildLed0();
    final led0ByteSegments = ledCommands.splitLed0IntoByteSegments(led0);

    setState(() {
      _isSendingCommand = true;
      _sendStatus = '正在发送 out1–out8 和 LED0 分段…';
    });

    try {
      final outsSent = await _bluetooth.sendHexSequence(
        LedBluetoothCommandService.outCommands,
        interval: const Duration(milliseconds: 200),
      );
      if (!mounted) {
        return;
      }
      if (!outsSent) {
        setState(() {
          _sendStatus = '发送 out1–out8 失败: ${_bluetooth.statusMessage}';
        });
        return;
      }

      setState(() {
        _sendStatus = 'out1–out8 已发送，正在发送 LED0 三段…';
      });

      await Future<void>.delayed(const Duration(milliseconds: 200));

      final segmentsSent = await _bluetooth.sendBytesSequence(
        led0ByteSegments,
        interval: const Duration(milliseconds: 25),
        delayBeforeFirst: false,
      );
      if (!mounted) {
        return;
      }

      final segmentSizes =
          led0ByteSegments.map((segment) => segment.length).join('/');
      setState(() {
        _sendStatus = segmentsSent
            ? '已发送 out1–out8 及 LED0 三段 ($segmentSizes bytes)。'
                ' DeviceID=${ledCommands.deviceId}, LED2=${ledCommands.led2}。'
            : '发送 LED0 分段失败: ${_bluetooth.statusMessage}';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _sendStatus = '蓝牙发送异常: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSendingCommand = false;
        });
      }
    }
  }

  Future<void> _showDevicePicker() async {
    await _bluetooth.startScan();
    if (!mounted) {
      return;
    }

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => _BluetoothDeviceSheet(
        bluetooth: _bluetooth,
        onSelect: (device) async {
          Navigator.of(context).pop();
          await _bluetooth.connect(device);
        },
      ),
    );
  }

  @override
  void dispose() {
    _bluetooth.removeListener(_onBluetoothChanged);
    _bluetooth.dispose();
    _queryController.dispose();
    super.dispose();
  }

  Color _statusColor() {
    switch (_bluetooth.status) {
      case BluetoothConnectionStatus.connected:
        return AppColors.accent;
      case BluetoothConnectionStatus.error:
        return AppColors.error;
      case BluetoothConnectionStatus.scanning:
      case BluetoothConnectionStatus.connecting:
        return AppColors.primary;
      case BluetoothConnectionStatus.disconnected:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPageShell(
      navigationBar: CupertinoNavigationBar(
        middle: Text('紧固件看板查询', style: AppTheme.navTitle),
        backgroundColor: AppColors.surface,
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 88),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('蓝牙连接', style: AppTheme.sectionTitle),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _statusColor(),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _bluetooth.statusMessage,
                          style: AppTheme.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: AppPrimaryButton(
                          label: _bluetooth.isConnected ? '重新连接' : '连接蓝牙',
                          onPressed: _showDevicePicker,
                        ),
                      ),
                      if (_bluetooth.isConnected) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: AppSecondaryButton(
                            label: '断开连接',
                            onPressed: _bluetooth.disconnect,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('紧固件看板查询', style: AppTheme.sectionTitle),
                  const SizedBox(height: 10),
                  AppTextField(
                    controller: _queryController,
                    placeholder: '请输入物料号/物料名称/物料位置',
                  ),
                  const SizedBox(height: 12),
                  AppPrimaryButton(
                    label: '精确查询',
                    isLoading: _isSendingCommand,
                    onPressed: _isLoadingCatalog || _isSendingCommand
                        ? null
                        : _runQuery,
                  ),
                ],
              ),
            ),
            if (_isLoadingCatalog) ...[
              const SizedBox(height: 24),
              const Center(child: CupertinoActivityIndicator()),
              const SizedBox(height: 8),
              Center(
                child: Text('正在从云端 Excel 加载物料数据…', style: AppTheme.secondary),
              ),
            ] else if (_catalogError != null) ...[
              const SizedBox(height: 16),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('加载失败', style: AppTheme.sectionTitle),
                    const SizedBox(height: 8),
                    Text(_catalogError!, style: AppTheme.secondary),
                    const SizedBox(height: 12),
                    AppPrimaryButton(
                      label: '重新加载',
                      onPressed: () => _loadCatalog(forceRefresh: true),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => _loadCatalog(forceRefresh: true),
                  child: Text('刷新看板数据', style: AppTheme.accentTeal),
                ),
              ),
            ],
            if (!_isLoadingCatalog && _catalogError == null && _hasSearched) ...[
              Text(
                '查询获得${_results.length}个结果',
                style: AppTheme.secondary.copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              ..._results.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _MaterialResultCard(
                    item: item,
                    isSelected: _selectedItem?.id == item.id,
                  ),
                ),
              ),
              if (_sendStatus != null) ...[
                const SizedBox(height: 8),
                AppCard(
                  child: Text(
                    _sendStatus!,
                    style: TextStyle(
                      inherit: false,
                      fontSize: 17,
                      color: _sendStatus!.contains('已发送')
                          ? AppColors.accentDark
                          : AppColors.primary,
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _MaterialResultCard extends StatelessWidget {
  const _MaterialResultCard({
    required this.item,
    required this.isSelected,
  });

  final MaterialItem item;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('物料名称: ${item.name}', style: AppTheme.sectionTitle),
          const SizedBox(height: 6),
          Text('物料号: ${item.id}', style: AppTheme.secondary),
          const SizedBox(height: 4),
          Text('物料位置: ${item.location}', style: AppTheme.success),
          if (item.deviceId.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('DeviceID: ${item.deviceId}', style: AppTheme.secondary),
          ],
          if (item.led2.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('LED2: ${item.led2}', style: AppTheme.secondary),
          ],
          const SizedBox(height: 4),
          SizedBox(width: double.infinity),
        ],
      ),
    );
  }
}

class _BluetoothDeviceSheet extends StatelessWidget {
  const _BluetoothDeviceSheet({
    required this.bluetooth,
    required this.onSelect,
  });

  final ShelfBluetoothService bluetooth;
  final ValueChanged<BluetoothDevice> onSelect;

  @override
  Widget build(BuildContext context) {
    return ThemeAwareBuilder(
      builder: (context) {
        return CupertinoPopupSurface(
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 420,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('附近的蓝牙设备', style: AppTheme.sectionTitle),
                  ),
                  Expanded(
                    child: AnimatedBuilder(
                      animation: bluetooth,
                      builder: (context, _) {
                        if (bluetooth.scanResults.isEmpty) {
                          return const Center(
                            child: CupertinoActivityIndicator(),
                          );
                        }

                        return ListView.builder(
                          itemCount: bluetooth.scanResults.length,
                          itemBuilder: (context, index) {
                            final result = bluetooth.scanResults[index];
                            final device = result.device;
                            final name = device.platformName.isNotEmpty
                                ? device.platformName
                                : device.remoteId.str;

                            return CupertinoListTile(
                              title: Text(name, style: AppTheme.body),
                              subtitle: Text(
                                device.remoteId.str,
                                style: AppTheme.secondary,
                              ),
                              trailing: const Icon(CupertinoIcons.link),
                              onTap: () => onSelect(device),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  CupertinoButton(
                    child: const Text('关闭'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
