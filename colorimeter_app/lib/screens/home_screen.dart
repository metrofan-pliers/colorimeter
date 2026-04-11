import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/color_provider.dart';
import '../widgets/color_box.dart';
import '../widgets/color_info.dart';
import '../widgets/history_list.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ColorProvider>().startPolling();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Colorimeter',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Consumer<ColorProvider>(
            builder: (context, provider, _) {
              return IconButton(
                icon: Icon(
                  provider.notificationsEnabled
                      ? Icons.notifications_active
                      : Icons.notifications_off,
                  color: provider.notificationsEnabled
                      ? Colors.white
                      : Colors.grey,
                ),
                onPressed: () => provider.toggleNotifications(),
                tooltip: 'Уведомления',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              context.read<ColorProvider>().fetchColor();
            },
            tooltip: 'Обновить',
          ),
          IconButton(
            icon: const Icon(Icons.play_arrow, color: Colors.green),
            onPressed: () {
              context.read<ColorProvider>().fetchTestColor();
            },
            tooltip: 'Тестовый цвет',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: Colors.grey[900],
            onSelected: (value) {
              if (value == 'clear_history') {
                context.read<ColorProvider>().clearHistory();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear_history',
                child: Text(
                  'Очистить историю',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<ColorProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.currentColor == null) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          if (provider.error != null && provider.currentColor == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red[400],
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ошибка подключения',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Проверьте адрес сервера',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => provider.fetchColor(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[800],
                    ),
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            );
          }

          final color = provider.currentColor;

          if (color == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.color_lens_outlined,
                    color: Colors.grey[600],
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ожидание данных...',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ColorBox(color: color),
                const SizedBox(height: 24),
                ColorInfo(color: color),
                const SizedBox(height: 24),
                HistoryList(
                  history: provider.colorHistory,
                  onColorSelected: provider.selectColorFromHistory,
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}
