import 'package:flutter/material.dart';
import '../../../app/routes/app_routes.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFFFFF), Color(0xFFF0F4F9), Color(0xFFFFFFFF)],
          ),
        ),
        child: Scrollbar(
          controller: _scrollController,
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Center(
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 1000),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
                child: Column(
                  children: [
                    // 1. Sleek Logo
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))
                        ],
                      ),
                      child: const Icon(Icons.balance, size: 48, color: Color(0xFF1A73E8)),
                    ),
                    const SizedBox(height: 32),

                    // 2. Hero Section
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFF1A73E8), Color(0xFF15B79E)],
                      ).createShader(bounds),
                      child: const Text(
                        "Multilingual AI-Powered Legal Assistant",
                        style: TextStyle(
                          fontSize: 48, 
                          fontWeight: FontWeight.bold, 
                          color: Colors.white,
                          letterSpacing: -1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Enhancing Access and Compliance in Indian Legal Processes",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.normal, color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),

                    // 3. Description
                    Container(
                      constraints: const BoxConstraints(maxWidth: 850),
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white),
                        boxShadow: [
                           BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 40, offset: const Offset(0, 10))
                        ],
                      ),
                      child: const Text(
                        "Democratizing access to Indian legal processes by bridging the gap in understanding through state-of-the-art NLP and machine learning. "
                        "Our assistant empowers citizens to describe incidents in plain language, identifies relevant laws, generates FIR copies, and reviews contracts for non-compliance or fraudulent practices—promoting judicial efficiency and transparency for all.",
                        style: TextStyle(fontSize: 17, height: 1.7, color: Colors.black87, fontWeight: FontWeight.w400),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 64),

                    // 4. Services Grid
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: MediaQuery.of(context).size.width > 900 ? 3 : 1,
                      mainAxisSpacing: 24,
                      crossAxisSpacing: 24,
                      childAspectRatio: 0.85,
                      children: [
                        _serviceCard(Icons.report_problem_rounded, "Incident Reporter", "Identify legal sections and generate compliant FIR drafts from plain language descriptions."),
                        _serviceCard(Icons.document_scanner_rounded, "FIR Analyzer", "Extract comprehensive legal details and contextual explanations from scanned FIR documents."),
                        _serviceCard(Icons.gavel_rounded, "Contract Review", "Highlight non-compliant clauses and fraudulent risks with actionable legal references."),
                      ],
                    ),
                    const SizedBox(height: 80),

                    // 5. CTA
                    ElevatedButton(
                      onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.chat),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A73E8),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 24),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                        elevation: 8,
                        shadowColor: const Color(0xFF1A73E8).withOpacity(0.4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("Get Started", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          SizedBox(width: 12),
                          Icon(Icons.arrow_forward_rounded, size: 28),
                        ],
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _serviceCard(IconData icon, String title, String desc) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 36, color: const Color(0xFF1A73E8)),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Expanded(
            child: Text(desc, 
              style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.4), 
              textAlign: TextAlign.center,
              overflow: TextOverflow.fade,
            ),
          ),
        ],
      ),
    );
  }
}
