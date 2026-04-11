import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/api_service.dart';
import 'services/notification_service.dart';
import 'providers/color_provider.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final notificationService = NotificationService();
  await notificationService.initialize();
  
  final prefs = await SharedPreferences.getInstance();
  final serverUrl = prefs.getString('server_url') ?? 'http://141.8.192.25:8000';
  
  runApp(ColorimeterApp(
    initialServerUrl: serverUrl,
    notificationService: notificationService,
  ));
}

class ColorimeterApp extends StatefulWidget {
  final String initialServerUrl;
  final NotificationService notificationService;

  const ColorimeterApp({
    super.key,
    required this.initialServerUrl,
    required this.notificationService,
  });

  @override
  State<ColorimeterApp> createState() => _ColorimeterAppState();
}

class _ColorimeterAppState extends State<ColorimeterApp> {
  late ApiService _apiService;
  late ColorProvider _colorProvider;

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  void _initServices() {
    _apiService = ApiService(baseUrl: widget.initialServerUrl);
    _colorProvider = ColorProvider(
      apiService: _apiService,
      notificationService: widget.notificationService,
    );
  }

  void _onServerUrlChanged(String newUrl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_url', newUrl);
    
    setState(() {
      _colorProvider.dispose();
      _apiService = ApiService(baseUrl: newUrl);
      _colorProvider = ColorProvider(
        apiService: _apiService,
        notificationService: widget.notificationService,
      );
    });
  }

  @override
  void dispose() {
    _colorProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _colorProvider,
      child: MaterialApp(
        title: 'Colorimeter',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: Colors.black,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.black,
            elevation: 0,
          ),
        ),
        home: Scaffold(
          body: HomeScreen(),
          floatingActionButton: FloatingActionButton(
            backgroundColor: Colors.grey[800],
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(
                    onServerUrlChanged: _onServerUrlChanged,
                  ),
                ),
              );
            },
            child: const Icon(Icons.settings, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
