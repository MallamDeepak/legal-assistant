import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants.dart';
import 'core/services/api_service.dart';
import 'app/routes/app_routes.dart';
import 'features/incident_reporter/view/incident_form_screen.dart';
import 'features/incident_reporter/view/fir_result_screen.dart';
import 'features/fir_analyzer/view/fir_upload_screen.dart';
import 'features/fir_analyzer/view/fir_analysis_screen.dart';
import 'features/contract_reviewer/view/contract_upload_screen.dart';
import 'features/contract_reviewer/view/contract_review_screen.dart';
import 'features/chat/view/chat_screen.dart'; 
import 'features/landing/view/landing_screen.dart';
import 'core/providers/language_provider.dart';
import 'core/widgets/futuristic_widgets.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        Provider<ApiService>(
          create: (_) => ApiService(baseUrl: AppConstants.apiBaseUrl),
        ),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'NYAYA: AI Legal Assistant',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFA68A64), // Light Brown/Tan
            brightness: Brightness.light,
            primary: const Color(0xFFA68A64),
            surface: Colors.white,
            background: Colors.white,
            onBackground: Colors.black,
            onSurface: Colors.black87,
          ),
          scaffoldBackgroundColor: Colors.white, 
          appBarTheme: const AppBarTheme(
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: Colors.transparent,
            centerTitle: true,
            iconTheme: IconThemeData(color: Colors.black87),
            titleTextStyle: TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFFF1F5F9), // Slate 100
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.black.withOpacity(0.05))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFA68A64), width: 1.5)),
            hintStyle: TextStyle(color: Colors.black.withOpacity(0.3)),
          ),
          scrollbarTheme: ScrollbarThemeData(
            thickness: MaterialStateProperty.all(6),
            radius: const Radius.circular(3),
            thumbColor: MaterialStateProperty.all(const Color(0xFFA68A64).withOpacity(0.2)),
            interactive: true,
          ),
          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: Colors.black87),
            bodyMedium: TextStyle(color: Colors.black87),
          ),
        ),
        initialRoute: AppRoutes.home,
        onGenerateRoute: (settings) {
          // Handle Chat Screen with arguments
          if (settings.name == AppRoutes.chat) {
            final args = settings.arguments as ChatTool?;
            // ChatScreen uses its own Scaffold/Layout, do not wrap with SidebarWrapper as it has internal rail
            return MaterialPageRoute(
              builder: (_) => ChatScreen(initialTool: args ?? ChatTool.chat),
            );
          }
          return null;
        },
        routes: {
          // Home is now the Splash/Landing Page
          AppRoutes.home: (_) => const LandingScreen(),
          
          // Other features wrapped in Sidebar if needed, or ChatScreen handles them.
          // Note: IncidentForm, FIRResult etc might be legacy or specific sub-screens. 
          // If ChatScreen is the main interface, we might not need these as separate top-level routes 
          // often, but keeping them for now.
          
          AppRoutes.incidentForm: (context) => SidebarWrapper(
                child: IncidentFormScreen(onSubmit: (lang, text) async {
                  final api = Provider.of<ApiService>(context, listen: false);
                  return api.generateIncident(lang, text);
                }),
              ),
          AppRoutes.firResult: (_) => const SidebarWrapper(child: FirResultScreen()),
          AppRoutes.firAnalyzer: (_) => const SidebarWrapper(child: FirUploadScreen()),
          '/fir_analysis': (_) => const SidebarWrapper(child: FirAnalysisScreen()),
          AppRoutes.contractReviewer: (_) => const SidebarWrapper(child: ContractUploadScreen()),
          '/contract_review': (_) => const SidebarWrapper(child: ContractReviewScreen()),
        },
      );
  }
}

// Wrapper for legacy screens that don't have their own scaffold/layout
class SidebarWrapper extends StatelessWidget {
  final Widget child;
  const SidebarWrapper({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Scaffold(
      body: Stack(
        children: [
          // Background spray removed
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Basic Glass Sidebar for legacy screens
              SizedBox(
                width: 72,
                child: GlassCard(
                  padding: EdgeInsets.zero,
                  borderRadius: BorderRadius.zero,
                  borderColor: isLight ? Colors.black.withOpacity(0.05) : Colors.white.withOpacity(0.05),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      const Icon(Icons.balance, size: 28, color: Color(0xFFA68A64)),
                      const Spacer(),
                      IconButton(
                        icon: Icon(Icons.home_rounded, color: isLight ? Colors.black54 : Colors.white70), 
                        onPressed: () => Navigator.pushNamed(context, AppRoutes.home)
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  color: Colors.transparent,
                  child: child,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
