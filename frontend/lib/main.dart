import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'core/services/api_service.dart';
import 'app/routes/app_routes.dart';
import 'features/incident_reporter/view/incident_form_screen.dart';
import 'features/incident_reporter/view/fir_result_screen.dart';
import 'features/fir_analyzer/view/fir_upload_screen.dart';
import 'features/fir_analyzer/view/fir_analysis_screen.dart';
import 'features/contract_reviewer/view/contract_upload_screen.dart';
import 'features/contract_reviewer/view/contract_review_screen.dart';
import 'features/chat/view/chat_screen.dart';

void main() {
  runApp(const MyApp());
}

String resolveApiBaseUrl() {
  const fromDefine = String.fromEnvironment('API_BASE_URL', defaultValue: '');
  if (fromDefine.isNotEmpty) return fromDefine;

  if (kIsWeb) return 'http://localhost:8000';

  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      // Android emulator cannot reach host machine via localhost.
      return 'http://10.0.2.2:8000';
    default:
      return 'http://localhost:8000';
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final apiBase = resolveApiBaseUrl();
    return Provider<ApiService>(
      create: (_) => ApiService(baseUrl: apiBase),
      child: MaterialApp(
        title: 'Legal Assistant',
        theme: ThemeData(primarySwatch: Colors.blue),
        initialRoute: AppRoutes.home,
        routes: {
          AppRoutes.home: (_) => const HomeScreen(),
          AppRoutes.chat: (_) => const ChatScreen(),
          AppRoutes.incidentForm: (context) => IncidentFormScreen(onSubmit: (lang, text) async {
                final api = Provider.of<ApiService>(context, listen: false);
                return api.generateFirDraft(language: lang, text: text);
              }),
          AppRoutes.firResult: (_) => const FirResultScreen(),
          AppRoutes.firAnalyzer: (_) => const FirUploadScreen(),
          '/fir_analysis': (_) => const FirAnalysisScreen(),
          AppRoutes.contractReviewer: (_) => const ContractUploadScreen(),
          '/contract_review': (_) => const ContractReviewScreen(),
        },
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Multilingual Legal Assistant')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: [
          ElevatedButton(onPressed: () => Navigator.pushNamed(context, AppRoutes.chat), child: const Text('Open Chat Assistant')),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: () => Navigator.pushNamed(context, AppRoutes.incidentForm), child: const Text('Incident Reporter')),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: () => Navigator.pushNamed(context, AppRoutes.firAnalyzer), child: const Text('FIR Analyzer')),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: () => Navigator.pushNamed(context, AppRoutes.contractReviewer), child: const Text('Contract Reporter')),
        ]),
      ),
    );
  }
}
