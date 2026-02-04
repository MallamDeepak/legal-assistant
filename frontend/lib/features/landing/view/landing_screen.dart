import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/widgets/futuristic_widgets.dart';
import '../../../core/providers/language_provider.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final ScrollController _scrollController = ScrollController();

  final Map<String, Map<String, String>> _localizedStrings = {
    'en': {
      'hero_greeting': 'NYAYA: AI-Powered Justice',
      'hero_subtitle': 'Empowering Indian legal processes with the Neural Yielding Augmented Yielding Assistance architecture.',
      'get_started': 'Get Started',
      'feature_incident_title': 'Incident Reporter',
      'feature_incident_sub': 'Draft reports with AI legal logic.',
      'feature_fir_title': 'FIR Analyzer',
      'feature_fir_sub': 'Deep document extraction.',
      'feature_contract_title': 'Contract Review',
      'feature_contract_sub': 'Neural clause risk detection.',
    },
    'hi': {
      'hero_greeting': 'न्याय: एआई-संचालित न्याय',
      'hero_subtitle': 'NYAYA (Neural Yielding Augmented Yielding Assistance) आर्किटेक्चर के साथ भारतीय कानूनी प्रक्रियाओं को सशक्त बनाना।',
      'get_started': 'शुरू करें',
      'feature_incident_title': 'घटना रिपोर्टर',
      'feature_incident_sub': 'एआई कानूनी तर्क के साथ रिपोर्ट तैयार करें।',
      'feature_fir_title': 'एफआईआर विश्लेषक',
      'feature_fir_sub': 'गहन दस्तावेज़ निष्कर्षण।',
      'feature_contract_title': 'अनुबंध समीक्षा',
      'feature_contract_sub': 'न्यूरल क्लॉज जोखिम पहचान।',
    },
    'bn': {
      'hero_greeting': 'বহুভাষী এআই আইনি গোয়েন্দা',
      'hero_subtitle': 'উচ্চ-পারফরম্যান্স নিউরাল বিশ্লেষণ এবং বহুভাষী নির্ভুলতার সাথে ভারতীয় আইনি প্রক্রিয়াগুলিকে শক্তিশালী করা।',
      'get_started': 'শুরু করুন',
      'feature_incident_title': 'ঘটনা রিপোর্টার',
      'feature_incident_sub': 'এআই আইনি যুক্তি সহ রিপোর্ট তৈরি করুন।',
      'feature_fir_title': 'এফআইআর বিশ্লেষক',
      'feature_fir_sub': 'গভীর নথি নিষ্কাশন।',
      'feature_contract_title': 'চুক্তি পর্যালোচনা',
      'feature_contract_sub': 'নিউরাল ক্লজ ঝুঁকি সনাক্তকরণ।',
    },
    'te': {
      'hero_greeting': 'బహుభాషా ఏఐ లీగల్ ఇంటెలిజెన్స్',
      'hero_subtitle': 'అధిక-పనితీరు గల న్యూరల్ విశ్లేషణ మరియు బహుభాషా ఖచ్చితత్వంతో భారతీయ చట్టపరమైన ప్రక్రియలను శక్తివంతం చేయడం.',
      'get_started': 'ప్రారంభించండి',
      'feature_incident_title': 'ఇన్సిడెంట్ రిపోర్టర్',
      'feature_incident_sub': 'ఏఐ లీగల్ లాజిక్‌తో నివేదికలను రూపొందించండి.',
      'feature_fir_title': 'ఎఫ్ఐఆర్ అనలైజర్',
      'feature_fir_sub': 'లోతైన పత్రం వెలికితీత.',
      'feature_contract_title': 'కాంట్రాక్ట్ సమీక్ష',
      'feature_contract_sub': 'న్యూరల్ క్లాజ్ రిస్క్ గుర్తింపు.',
    },
    'mr': {
      'hero_greeting': 'बहुभाषिक एआय कायदेशीर बुद्धिमत्ता',
      'hero_subtitle': 'उच्च-कार्यक्षमता न्यूरल विश्लेषण आणि बहुभाषिक अचूकतेसह भारतीय कायदेशीर प्रक्रिया सक्षम करणे।',
      'get_started': 'सुरू करा',
      'feature_incident_title': 'घटना रिपोर्टर',
      'feature_incident_sub': 'एआय कायदेशीर तर्कासह अहवाल तयार करा।',
      'feature_fir_title': 'एफआयआर विश्लेषक',
      'feature_fir_sub': 'खोल दस्तऐवज काढणे।',
      'feature_contract_title': 'करार पुनरावलोकन',
      'feature_contract_sub': 'न्यूरल क्लॉज जोखीम शोधणे।',
    },
  };

  String _getT(String key) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    return _localizedStrings[languageProvider.selectedLanguage]?[key] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Scaffold(
      backgroundColor: isLight ? Colors.white : const Color(0xFF0F172A),
      body: Stack(
        children: [
          // Background spray removed

          Scrollbar(
            controller: _scrollController,
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    // Top Bar / Language Selector
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _buildLanguageSelector(),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 60),

                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          children: [
                            // 1. Hero Title
                            const SlideFadeTransition(
                              duration: Duration(seconds: 1),
                              child: Icon(Icons.balance, size: 80, color: Color(0xFFA68A64)),
                            ),
                            const SizedBox(height: 32),
                            SlideFadeTransition(
                              delay: const Duration(milliseconds: 200),
                              child: Text(
                                _getT('hero_greeting'),
                                style: const TextStyle(
                                  fontSize: 52, 
                                  fontWeight: FontWeight.w800, 
                                  color: Color(0xFFA68A64),
                                  letterSpacing: -2,
                                  height: 1.1,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 24),
                            SlideFadeTransition(
                              delay: const Duration(milliseconds: 400),
                              child: Text(
                                _getT('hero_subtitle'),
                                style: TextStyle(
                                  fontSize: 20, 
                                  color: isLight ? Colors.black54 : Colors.white.withOpacity(0.5), 
                                  height: 1.5, 
                                  fontWeight: FontWeight.w400
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 64),

                            // 2. Feature Cards
                            SlideFadeTransition(
                              delay: const Duration(milliseconds: 600),
                              child: IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    _buildFeatureCard(_getT('feature_incident_title'), _getT('feature_incident_sub'), Icons.bolt_rounded),
                                    const SizedBox(width: 16),
                                    _buildFeatureCard(_getT('feature_fir_title'), _getT('feature_fir_sub'), Icons.search_rounded),
                                    const SizedBox(width: 16),
                                    _buildFeatureCard(_getT('feature_contract_title'), _getT('feature_contract_sub'), Icons.security_rounded),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 80),

                            // 3. CTA Button
                            SlideFadeTransition(
                              delay: const Duration(milliseconds: 800),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(40),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFA68A64).withOpacity(0.3),
                                      blurRadius: 32,
                                      offset: const Offset(0, 12),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.chat),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFA68A64),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 28),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                                    elevation: 0,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(_getT('get_started'), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                                      const SizedBox(width: 12),
                                      const Icon(Icons.arrow_forward_rounded, size: 28),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector() {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final Map<String, String> languages = {
      'en': 'English',
      'hi': 'हिंदी',
      'bn': 'বাংলা',
      'te': 'తెలుగు',
      'mr': 'मराठी',
    };

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      borderRadius: BorderRadius.circular(30),
      color: isLight ? Colors.black.withOpacity(0.02) : Colors.white.withOpacity(0.08),
      borderColor: isLight ? Colors.black.withOpacity(0.05) : Colors.white.withOpacity(0.1),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: Provider.of<LanguageProvider>(context).selectedLanguage,
          dropdownColor: isLight ? Colors.white : const Color(0xFF1E293B),
          icon: const Icon(Icons.language_rounded, color: Color(0xFFA68A64), size: 18),
          elevation: 16,
          style: TextStyle(color: isLight ? Colors.black87 : Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
          onChanged: (String? newValue) {
            if (newValue != null) {
              Provider.of<LanguageProvider>(context, listen: false).setLanguage(newValue);
            }
          },
          items: languages.entries.map<DropdownMenuItem<String>>((entry) {
            return DropdownMenuItem<String>(
              value: entry.key,
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Text(entry.value),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(String title, String subtitle, IconData icon) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        borderRadius: BorderRadius.circular(24),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFA68A64).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFFA68A64), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title, 
                    style: TextStyle(color: isLight ? Colors.black87 : Colors.white, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle, 
                    style: TextStyle(color: isLight ? Colors.black45 : Colors.white.withOpacity(0.4), fontSize: 12, height: 1.3), 
                    textAlign: TextAlign.start,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
