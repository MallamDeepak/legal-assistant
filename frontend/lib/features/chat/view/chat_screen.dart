import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart'; // Added
import 'package:url_launcher/url_launcher.dart'; // Added
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../core/services/api_service.dart';

enum ChatTool { chat, incident, fir, contract }

class ChatSession {
  final String id;
  String title;
  final ChatTool tool;
  final List<ChatMessage> messages;
  final DateTime timestamp;

  ChatSession({
    required this.id, 
    required this.title, 
    required this.tool, 
    required this.messages, 
    required this.timestamp
  });
}

class ChatMessage {
  final String text;
  final bool fromUser;
  bool isAnimated; 

  ChatMessage({required this.text, this.fromUser = false, this.isAnimated = false});
}

// _MockDriveFile removed

class ChatScreen extends StatefulWidget {
  final ChatTool initialTool;
  final String? initialQuery;
  final String? initialResponse; // New: For passing analysis results directly
  final VoidCallback? onBack;

  const ChatScreen({
    Key? key, 
    this.initialTool = ChatTool.chat,
    this.initialQuery,
    this.initialResponse,
    this.onBack,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [];
  final List<ChatSession> _sessions = []; // History
  String _selectedLanguage = 'en'; // Default English

  // Localization Map
  final Map<String, Map<String, String>> _localizedStrings = {
    'en': {
      'app_title': 'Ai Legal Assistant',
      'hero_greeting': 'Where knowledge begins',
      'hero_subtitle': 'Experience the power of legal AI analysis in seconds.',
      'feature_incident_title': 'Incident Reporter',
      'feature_incident_sub': 'Draft reports from descriptions',
      'feature_fir_title': 'FIR Analyzer',
      'feature_fir_sub': 'Extract key legal details',
      'feature_contract_title': 'Contract Review',
      'feature_contract_sub': 'Analyze clauses & risks',
      'thinking': 'Thinking...',
      'input_hint': 'Ask anything...',
      'think_incident': 'Analyzing incident details and drafting report...',
      'think_fir': 'Extracting legal sections from FIR document...',
      'think_contract': 'Reviewing contract clauses and identifying risks...',
      'think_chat': 'Searching legal database and generating response...',
      'sidebar_new_chat': 'New chat',
      'sidebar_history': 'History',
      'drive_select_files': 'Select files',
      'drive_search_hint': 'Search in Drive or paste URL',
      'drive_tab_recent': 'Recent',
      'drive_tab_my_drive': 'My Drive',
      'drive_tab_shared': 'Shared with me',
      'drive_tab_starred': 'Starred',
      'drive_section_today': 'Today',
      'drive_section_yesterday': 'Yesterday',
      'upload_files': 'Upload files',
      'photos': 'Photos',
      'select_mode': 'Select Mode',
    },
    'hi': {
      'app_title': 'एआई कानूनी सहायक',
      'hero_greeting': 'जहाँ ज्ञान शुरू होता है',
      'hero_subtitle': 'सेकंड में कानूनी एआई विश्लेषण की शक्ति का अनुभव करें।',
      'feature_incident_title': 'घटना रिपोर्टर',
      'feature_incident_sub': 'विवरण से रिपोर्ट तैयार करें',
      'feature_fir_title': 'एफआईआर विश्लेषक',
      'feature_fir_sub': 'मुख्य कानूनी विवरण निकालें',
      'feature_contract_title': 'अनुबंध समीक्षा',
      'feature_contract_sub': 'खंडों और जोखिमों का विश्लेषण करें',
      'thinking': 'सोच रहा हूँ...',
      'input_hint': 'कुछ भी पूछें...',
      'think_incident': 'घटना के विवरण का विश्लेषण और रिपोर्ट तैयार करना...',
      'think_fir': 'एफआईआर दस्तावेज़ से कानूनी धाराएं निकालना...',
      'think_contract': 'अनुबंध की शर्तों की समीक्षा और जोखिमों की पहचान...',
      'think_chat': 'कानूनी डेटाबेस खोजना और उत्तर तैयार करना...',
      'sidebar_new_chat': 'नई चैट',
      'sidebar_history': 'इतिहास',
      'drive_select_files': 'फ़ाइल चुनें',
      'drive_search_hint': 'ड्राइव में खोजें या यूआरएल पेस्ट करें',
      'drive_tab_recent': 'अभी का',
      'drive_tab_my_drive': 'मेरी ड्राइव',
      'drive_tab_shared': 'साझा किया गया',
      'drive_tab_starred': 'तारांकित',
      'drive_section_today': 'आज',
      'drive_section_yesterday': 'कल',
      'upload_files': 'फाइल अपलोड करें',
      'photos': 'फोटो',
      'select_mode': 'मोड चुनें',
    },
    'bn': {
      'app_title': 'এআই আইনি সহকারী',
      'hero_greeting': 'যেখানে জ্ঞানের শুরু',
      'hero_subtitle': 'সেকেন্ডের মধ্যে আইনি এআই বিশ্লেষণের শক্তি অনুভব করুন।',
      'feature_incident_title': 'ঘটনা রিপোর্টার',
      'feature_incident_sub': 'বিবরণ থেকে রিপোর্ট তৈরি করুন',
      'feature_fir_title': 'এফআইআর বিশ্লেষক',
      'feature_fir_sub': 'মূল আইনি বিবরণ বের করুন',
      'feature_contract_title': 'চুক্তি পর্যালোচনা',
      'feature_contract_sub': 'ধারা এবং ঝুঁকি বিশ্লেষণ করুন',
      'thinking': 'ভাবছি...',
      'input_hint': 'যেকোনো কিছু জিজ্ঞাসা করুন...',
      'think_incident': 'ঘটনার বিবরণ বিশ্লেষণ এবং রিপোর্ট তৈরি করছি...',
      'think_fir': 'এফআইআর নথি থেকে আইনি ধারা বের করছি...',
      'think_contract': 'চুক্তির ধারা পর্যালোচনা এবং ঝুঁকি চিহ্নিত করছি...',
      'think_chat': 'আইনি ডাটাবেস অনুসন্ধান এবং উত্তর তৈরি করছি...',
      'sidebar_new_chat': 'নতুন চ্যাট',
      'sidebar_history': 'ইতিহাস',
      'drive_select_files': 'ফাইল নির্বাচন করুন',
      'drive_search_hint': 'ড্রাইভ অনুসন্ধান করুন বা ইউআরএল পেস্ট করুন',
      'drive_tab_recent': 'সাম্প্রতিক',
      'drive_tab_my_drive': 'আমার ড্রাইভ',
      'drive_tab_shared': 'আমার সাথে শেয়ার করা',
      'drive_tab_starred': 'তারকাচিহ্নিত',
      'drive_section_today': 'আজ',
      'drive_section_yesterday': 'গতকাল',
      'upload_files': 'ফাইল আপলোড করুন',
      'photos': 'ফটো',
      'select_mode': 'মোড নির্বাচন করুন',
    },
    'te': {
      'app_title': 'ఏఐ లీగల్ అసిస్టెంట్',
      'hero_greeting': 'జ్ఞానం ఎక్కడ ప్రారంభమవుతుందో',
      'hero_subtitle': 'సెకన్లలో లీగల్ ఏఐ విశ్లేషణ యొక్క శక్తిని అనుభవించండి.',
      'feature_incident_title': 'ఇన్సిడెంట్ రిపోర్టర్',
      'feature_incident_sub': 'వివరణల నుండి నివేదికలను రూపొందించండి',
      'feature_fir_title': 'ఎఫ్ఐఆర్ అనలైజర్',
      'feature_fir_sub': 'ముఖ్యమైన చట్టపరమైన వివరాలను సేకరించండి',
      'feature_contract_title': 'కాంట్రాక్ట్ సమీక్ష',
      'feature_contract_sub': 'నిబంధనలు మరియు రిస్క్‌లను విశ్లేషించండి',
      'thinking': 'ఆలోచిస్తున్నాను...',
      'input_hint': 'ఏదైనా అడగండి...',
      'think_incident': 'సంఘటన వివరాలను విశ్లేషించి నివేదికను రూపొందిస్తున్నాను...',
      'think_fir': 'ఎఫ్ఐఆర్ పత్రం నుండి చట్టపరమైన విభాగాలను సేకరిస్తున్నాను...',
      'think_contract': 'కాంట్రాక్ట్ నిబంధనలను సమీక్షించి రిస్క్‌లను గుర్తిస్తున్నాను...',
      'think_chat': 'చట్టపరమైన డేటాబేస్ శోధించి సమాధానాన్ని రూపొందిస్తున్నాను...',
      'sidebar_new_chat': 'కొత్త చాట్',
      'sidebar_history': 'చరిత్ర',
      'drive_select_files': 'ఫైల్‌లను ఎంచుకోండి',
      'drive_search_hint': 'డ్రైవ్‌లో వెతకండి లేదా URL పేస్ట్ చేయండి',
      'drive_tab_recent': 'ఇటీవలి',
      'drive_tab_my_drive': 'నా డ్రైవ్',
      'drive_tab_shared': 'నాతో భాగస్వామ్యం చేయబడినవి',
      'drive_tab_starred': 'నక్షత్రం గుర్తు ఉన్నవి',
      'drive_section_today': 'ఈ రోజు',
      'drive_section_yesterday': 'నిన్న',
      'upload_files': 'ఫైల్‌లను అప్‌లోడ్ చేయండి',
      'photos': 'ఫోటోలు',
      'select_mode': 'మోడ్ ఎంచుకోండి',
    },
    'mr': {
      'app_title': 'एआय कायदेशीर सहाय्यक',
      'hero_greeting': 'जिथे ज्ञानाची सुरुवात होते',
      'hero_subtitle': 'सेकंदात कायदेशीर एआय विश्लेषणाच्या शक्तीचा अनुभव घ्या.',
      'feature_incident_title': 'घटना रिपोर्टर',
      'feature_incident_sub': 'वर्णनावरून अहवाल तयार करा',
      'feature_fir_title': 'एफआयआर विश्लेषक',
      'feature_fir_sub': 'मुख्य कायदेशीर तपशील काढा',
      'feature_contract_title': 'करार पुनरावलोकन',
      'feature_contract_sub': 'कलमे आणि जोखमींचे विश्लेषण करा',
      'thinking': 'विचार करत आहे...',
      'input_hint': 'काहीही विचारा...',
      'think_incident': 'घटनेच्या तपशीलांचे विश्लेषण आणि अहवाल तयार करणे...',
      'think_fir': 'एफआयआर दस्तऐवजातून कायदेशीर कलमे काढणे...',
      'think_contract': 'करार कलमांचे पुनरावलोकन आणि जोखीम ओळखणे...',
      'think_chat': 'कायदेशीर डेटाबेस शोधणे आणि प्रतिसाद तयार करणे...',
      'sidebar_new_chat': 'नवीन चॅट',
      'sidebar_history': 'इतिहास',
      'drive_select_files': 'फायली निवडा',
      'drive_search_hint': 'ड्राईव्हमध्ये शोधा किंवा URL पेस्ट करा',
      'drive_tab_recent': 'अलीकडील',
      'drive_tab_my_drive': 'माझी ड्राईव्ह',
      'drive_tab_shared': 'माझ्यासोबत शेअर केलेले',
      'drive_tab_starred': 'तारांकित',
      'drive_section_today': 'आज',
      'drive_section_yesterday': 'काल',
      'upload_files': 'फायली अपलोड करा',
      'photos': 'फोटो',
      'select_mode': 'मोड निवडा',
    },
  };

  String _getT(String key) {
    return _localizedStrings[_selectedLanguage]?[key] ?? _localizedStrings['en']![key]!;
  }
  
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ScrollController _landingScrollController = ScrollController(); // New
  final ScrollController _sidebarScrollController = ScrollController(); // New
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>(); 
  
  bool _loading = false;
  bool _showLanding = true; 
  bool _isPanelOpen = false; // Closed by default
  ChatTool _currentTool = ChatTool.chat;
  
  // Attachments
  List<PlatformFile> _attachments = [];

  @override
  void initState() {
    super.initState();
    _currentTool = widget.initialTool;
    // ... (Rest of initState)
    
    if ((widget.initialQuery != null && widget.initialQuery!.isNotEmpty) || 
        (widget.initialResponse != null && widget.initialResponse!.isNotEmpty)) {
      _showLanding = false;
    }
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialResponse != null && widget.initialResponse!.isNotEmpty) {
        setState(() {
          _messages.insert(0, ChatMessage(text: widget.initialResponse!, fromUser: false));
        });
      } else if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
        _controller.text = widget.initialQuery!;
        _sendMessage();
      }
    });
  }

  // ... (Methods)
  void _saveCurrentSession() {
    if (_messages.isEmpty) return;
    final title = _messages.last.text.length > 30 
        ? '${_messages.last.text.substring(0, 30)}...' 
        : _messages.last.text; // Use first user message as title
        
    final session = ChatSession(
      id: DateTime.now().toIso8601String(),
      title: title,
      tool: _currentTool,
      messages: List.from(_messages), // Copy
      timestamp: DateTime.now(),
    );
    _sessions.insert(0, session);
  }
  
  void _loadSession(ChatSession session) {
    setState(() {
      _showLanding = false;
      _currentTool = session.tool;
      _messages.clear();
      _messages.addAll(session.messages);
      _isPanelOpen = false; // Auto close on selection if desired, or keep open
    });
  }

    Future<void> _switchTool(ChatTool tool) async {
    // If we are in an active chat (not landing), confirm before switching
    if (!_showLanding && _messages.isNotEmpty) {
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Start New Chat?"),
          content: const Text("To use another feature, you need to start a new chat. Current session will be saved."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false), // Cancel
              child: const Text("Cancel"),
            ),
            FilledButton(
               onPressed: () => Navigator.pop(context, true), // New Chat
               child: const Text("New Chat"),
            ),
          ],
        ),
      );

      if (confirm != true) return; // Cancelled
      
      _saveCurrentSession();
    }

    if (!mounted) return;

    setState(() {
      _currentTool = tool;
      // If we switch tool, we go back to landing logic conceptually for "New Chat"
       if (!_showLanding) {
         _messages.clear();
         _showLanding = true;
       }
    });
  }  
  
  String _toolName(ChatTool tool) {
    switch (tool) {
      case ChatTool.chat: return 'Chat Assistant';
      case ChatTool.incident: return 'Incident Reporter';
      case ChatTool.fir: return 'FIR Analyzer';
      case ChatTool.contract: return 'Contract Review';
    }
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    
    // Switch to Chat View immediately
    setState(() {
      _showLanding = false;
      _messages.insert(0, ChatMessage(text: text, fromUser: true, isAnimated: true));
      _loading = true;
      _controller.clear();
    });

    final api = Provider.of<ApiService>(context, listen: false);
    try {
      if (_attachments.isNotEmpty) {
        final item = _attachments.first;
        if (_currentTool == ChatTool.fir) {
          final resp = await api.analyzeFIR(item.name, item.bytes!, _selectedLanguage);
          final summary = (resp['summary'] ?? '').toString();
          final extracted = (resp['extracted_text'] ?? '').toString();
          if (!mounted) return;
          setState(() {
            _messages.insert(0, ChatMessage(
              text: "### Analysis Summary\n$summary\n\n---\n### Extracted Text\n$extracted", 
              fromUser: false
            ));
            _attachments.clear();
            _loading = false;
          });
          return;
        } else if (_currentTool == ChatTool.contract) {
          final resp = await api.reviewContract(item.name, item.bytes!, _selectedLanguage);
          final summary = (resp['summary'] ?? '').toString();
          final textOnly = (resp['text'] ?? '').toString();
          if (!mounted) return;
          setState(() {
            _messages.insert(0, ChatMessage(
              text: "### Review Summary\n$summary\n\n---\n### Full Text\n$textOnly", 
              fromUser: false
            ));
            _attachments.clear();
            _loading = false;
          });
          return;
        }
      }

      if (_currentTool == ChatTool.incident) {
           // Pass selected language
           final resp = await api.generateIncident(_selectedLanguage, text);
           final firText = (resp['fir_text'] ?? '').toString();
           String reply = firText; 
           if (!mounted) return;
           setState(() {
             _messages.insert(0, ChatMessage(text: reply, fromUser: false));
             _loading = false;
           });
      } else if (_currentTool == ChatTool.chat) {
         final reply = await api.chat(text, _selectedLanguage);
         if (!mounted) return;
         setState(() {
           _messages.insert(0, ChatMessage(text: reply, fromUser: false));
           _loading = false;
         });
      } else {
         // Fallback for file tools when no file is attached
         await Future.delayed(const Duration(milliseconds: 500));
         if (!mounted) return;
         setState(() {
            _messages.insert(0, ChatMessage(text: "For ${_toolName(_currentTool)}, please use the **(+) Plus Button** to upload a document.", fromUser: false));
            _loading = false;
          });
      }
    } catch (e) {
       if (!mounted) return;
       setState(() {
         _messages.insert(0, ChatMessage(text: "Error: ${e.toString()}", fromUser: false));
         _loading = false;
       });
    }
  }

  Future<void> _pickFiles(FileType type) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: type,
        allowMultiple: true,
      );

      if (result != null) {
        setState(() {
          _attachments.addAll(result.files);
        });
      }
    } on PlatformException catch (e) {
      // Handle platform exception (e.g., permission denied)
      print("Unsupported operation" + e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error picking files: ${e.message}")),
      );
    } catch (e) {
      // Handle other exceptions
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error picking files: $e")),
      );
    }
  }

// Google Drive methods removed

  Color _getFileColor(String? ext) {
    switch (ext?.toLowerCase()) {
      case 'pdf': return Colors.red;
      case 'doc':
      case 'docx': return Colors.blue;
      case 'xls':
      case 'xlsx': return Colors.green;
      default: return Colors.blueGrey;
    }
  }

// Drive helpers removed

  IconData _getFileIcon(String? extension) {
    switch (extension?.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'txt':
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // 1. Unified Sidebar (Collapsible)
          _buildSidebar(),
          
          // 2. Main Content
          Expanded(
            child: Container(
              // Elegant background gradient
              decoration: const BoxDecoration(
                color: Colors.white,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFFFFF),
                    Color(0xFFF0F4F9), // Very light Gemini-style blue/grey
                    Color(0xFFFFFFFF),
                  ],
                ),
              ),
              child: Column(
                children: [
                  // Persistent Top Bar (Outside Sidebar)
                  _buildTopBar(),
                  
                  // View Content
                  Expanded(
                    child: _showLanding ? _buildLandingView() : _buildChatView(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 64, // Increased height for premium feel
      padding: const EdgeInsets.symmetric(horizontal: 24),
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                _getT('app_title'),
                style: TextStyle(
                  fontSize: 22, 
                  fontWeight: FontWeight.w600, 
                  color: Colors.teal.shade700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.balance, color: Colors.teal.shade700, size: 24),
            ],
          ),
          // Language selector / Profile
          Row(
            children: [
              _buildLanguageSelector(),
              const SizedBox(width: 16),
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.teal.shade50,
                child: const Icon(Icons.person, size: 20, color: Colors.teal),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector() {
    final Map<String, String> languages = {
      'en': 'English',
      'hi': 'हिंदी',
      'bn': 'বাংলা',
      'te': 'తెలుగు',
      'mr': 'मराठी',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedLanguage,
          isDense: true,
          icon: const Icon(Icons.language, size: 16, color: Colors.black54),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() => _selectedLanguage = newValue);
            }
          },
          items: languages.entries.map((entry) {
            return DropdownMenuItem<String>(
              value: entry.key,
              child: Text(entry.value, style: const TextStyle(fontSize: 13, color: Colors.black87)),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildChatView() {
    return Column(
      children: [
        Expanded(
          child: Scrollbar(
            controller: _scrollController,
            thickness: 6,
            radius: const Radius.circular(3),
            child: ListView.builder(
              controller: _scrollController,
              reverse: true,
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              itemBuilder: (context, i) {
                final int itemCount = _messages.length + (_loading ? 1 : 0);
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: i == 0 && _loading 
                      ? _buildThinkingIndicator()
                      : _buildMessage(_messages[_loading ? i - 1 : i]),
                  ),
                );
              },
              itemCount: _messages.length + (_loading ? 1 : 0),
            ),
          ),
        ),
        // Input area also centered
        Center(
          child: _buildInputArea(isCentered: false),
        ),
      ],
    );
  }

  Widget _buildMessage(ChatMessage m) {
    if (m.fromUser) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4F9), // Gemini User Grey
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(5),
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: SelectableText(
                  m.text,
                  style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
                ),
              ),
            ),
            const SizedBox(width: 12),
             CircleAvatar(
              radius: 18,
              backgroundColor: Colors.black87, // Dark User Avatar
              child: const Icon(Icons.person, size: 20, color: Colors.white),
            ),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.purple.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(Icons.auto_awesome, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_toolName(_currentTool), style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey.shade600)),
                  const SizedBox(height: 8),
                  m.isAnimated 
                    ? MarkdownBody(
                        data: m.text,
                        selectable: true,
                        styleSheet: _markdownStyle(),
                      )
                    : TypewriterMarkdown(
                        text: m.text,
                        styleSheet: _markdownStyle(),
                        onFinished: () {
                          m.isAnimated = true; // Mark as done
                        },
                      ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  MarkdownStyleSheet _markdownStyle() {
    return MarkdownStyleSheet(
      p: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87, fontFamily: 'Roboto'),
      h1: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1.5),
      h2: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, height: 1.5),
      strong: const TextStyle(fontWeight: FontWeight.w700),
      listBullet: const TextStyle(fontSize: 16),
      blockSpacing: 12,
    );
  }

  IconData _toolIcon(ChatTool tool) {
    switch (tool) {
      case ChatTool.chat: return Icons.chat_bubble_outline;
      case ChatTool.incident: return Icons.report_problem_outlined;
      case ChatTool.fir: return Icons.document_scanner_outlined;
      case ChatTool.contract: return Icons.gavel_outlined;
    }
  }

  Widget _buildInputArea({bool isCentered = false}) {
    return Container(
      width: isCentered ? 800 : null,
      padding: isCentered ? EdgeInsets.zero : const EdgeInsets.all(16.0),
      child: Center(
        child: Container(
           constraints: const BoxConstraints(maxWidth: 800),
           decoration: BoxDecoration(
             color: isCentered ? Colors.white : const Color(0xFFF0F4F9),
             borderRadius: BorderRadius.circular(24), 
             // Border removed as requested
             boxShadow: isCentered ? [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))] : null,
           ),
           padding: const EdgeInsets.all(16),
           child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             mainAxisSize: MainAxisSize.min, // Wrap content
             children: [
             // 0. Attachments Preview
             if (_attachments.isNotEmpty)
               Container(
                 height: 60,
                 margin: const EdgeInsets.only(bottom: 12),
                 child: ListView.separated(
                   scrollDirection: Axis.horizontal,
                   itemCount: _attachments.length,
                   separatorBuilder: (_, __) => const SizedBox(width: 8),
                   itemBuilder: (context, index) {
                     final file = _attachments[index];
                     return Container(
                       padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                       decoration: BoxDecoration(
                         color: Colors.grey.shade100,
                         borderRadius: BorderRadius.circular(16),
                         border: Border.all(color: Colors.grey.shade300),
                       ),
                       child: Row(
                         children: [
                           Icon(_getFileIcon(file.extension), size: 20, color: Colors.teal),
                           const SizedBox(width: 8),
                           Text(
                             file.name.length > 20 ? "${file.name.substring(0, 15)}...${file.extension}" : file.name,
                             style: const TextStyle(fontSize: 13),
                           ),
                           const SizedBox(width: 4),
                           IconButton(
                             icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                             padding: EdgeInsets.zero,
                             constraints: const BoxConstraints(),
                             onPressed: () => setState(() => _attachments.removeAt(index)),
                           ),
                         ],
                       ),
                     );
                   },
                 ),
               ),

              // 1. Text Field (Top)
              TextField(
                controller: _controller,
                minLines: 1, // Start small
                maxLines: 12, // Allow growing tall
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(fontSize: 16, height: 1.5),
                cursorColor: Colors.teal,
                decoration: InputDecoration(
                  hintText: _getT('input_hint'),
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  filled: false, // Explicitly false to prevent background colors
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  hoverColor: Colors.transparent, // Disable hover effect
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  suffixIcon: _controller.text.isNotEmpty 
                    ? IconButton(
                        icon: const Icon(Icons.cancel, size: 20, color: Colors.grey),
                        onPressed: () {
                          setState(() {
                            _controller.clear();
                          });
                        },
                      )
                    : null,
                ),
                onChanged: (val) {
                  setState(() {}); 
                },
                onSubmitted: (_) => _sendMessage(),
              ),
              
              const SizedBox(height: 12),
              
              // 2. Features/Icons (Bottom)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left: Tools
                  Row(
                    children: [
                       // Plus (Upload)
                      _buildPopupMenu(
                        icon: Icons.add,
                        tooltip: _getT('upload_files'),
                        transparent: true,
                        items: [
                          _buildPopupItem(Icons.attach_file, _getT('upload_files')),
                          _buildPopupItem(Icons.photo_library, _getT('photos')),
                        ],
                        onSelected: (val) {
                          if (val == _getT('upload_files')) {
                            _pickFiles(FileType.any);
                          } else if (val == _getT('photos')) {
                            _pickFiles(FileType.image);
                          }
                        },
                      ),
                       const SizedBox(width: 8),
                       
                       // Tune (Mode)
                       _buildPopupMenu(
                         icon: Icons.tune,
                         tooltip: _getT('select_mode'),
                         items: ChatTool.values.where((t) => t != ChatTool.chat).map((tool) {
                           return PopupMenuItem(
                             value: tool,
                             child: Row(
                               children: [
                                 Icon(_toolIcon(tool), color: Colors.grey.shade700, size: 20),
                                 const SizedBox(width: 12),
                                 Expanded(child: Text(_toolName(tool), style: const TextStyle(fontSize: 14))),
                                 if (_currentTool == tool)
                                   const Icon(Icons.check_circle, color: Colors.blue, size: 18),
                               ],
                             ),
                           );
                         }).toList(),
                         onSelected: (val) {
                            if (val is ChatTool) _switchTool(val);
                         },
                       ),
                       const SizedBox(width: 12),
                       
                       // Active Mode Chip
                       if (_currentTool != ChatTool.chat)
                         Container(
                           decoration: BoxDecoration(
                             color: Colors.white,
                             borderRadius: BorderRadius.circular(20),
                             border: Border.all(color: Colors.grey.shade200),
                           ),
                           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                           child: Row(
                             mainAxisSize: MainAxisSize.min,
                             children: [
                               Icon(_toolIcon(_currentTool), size: 14, color: Colors.orange), 
                               const SizedBox(width: 6),
                               Text(_toolName(_currentTool), style: const TextStyle(fontSize: 13, color: Colors.blueAccent, fontWeight: FontWeight.w500)),
                               const SizedBox(width: 4),
                               InkWell(
                                 onTap: () => _switchTool(ChatTool.chat),
                                 child: const Icon(Icons.close, size: 14, color: Colors.grey),
                               )
                             ],
                           ),
                         ),
                     ],
                   ),
                   
                   // Right: Mic / Send
                   if (_controller.text.isEmpty)
                     IconButton(
                       icon: const Icon(Icons.mic_none, color: Colors.grey),
                       onPressed: () {},
                     )
                   else
                     IconButton(
                       icon: _loading 
                         ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)) 
                         : Icon(Icons.send_rounded, color: Theme.of(context).primaryColor),
                       onPressed: _loading ? null : _sendMessage,
                     ),
                 ],
               ),
             ],
           ),
        ),
      ),
    );
  }

  Widget _buildPopupMenu({
    required IconData icon,
    required String tooltip,
    required List<PopupMenuEntry<dynamic>> items,
    required Function(dynamic) onSelected,
    bool transparent = false, // New parameter
  }) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: transparent ? Colors.transparent : Colors.grey.shade100,
      ),
      child: PopupMenuButton(
        tooltip: tooltip,
        icon: Icon(icon, color: Colors.black54, size: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        // offset: const Offset(0, -120), // Removed to allow default 'under' positioning
        position: PopupMenuPosition.under,
        color: const Color(0xFFF0F4F9),
        elevation: 4,
        onSelected: onSelected,
        itemBuilder: (context) => items,
      ),
    );
  }

  PopupMenuItem _buildPopupItem(IconData icon, String text) {
     return PopupMenuItem(
       value: text,
       child: Row(
         children: [
           Icon(icon, color: Colors.black87, size: 20),
           const SizedBox(width: 12),
           Text(text, style: const TextStyle(fontSize: 14)),
         ],
       ),
     );
  }

  Widget _buildSidebar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: _isPanelOpen ? 260 : 72,
      color: const Color(0xFFF9F9FB),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isExpanded = constraints.maxWidth > 150;

          return Column(
            crossAxisAlignment: isExpanded ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 8), // Reduced to 8 to align with TopBar title
              
              // Menu Button Only (Title removed)
              Container(
                height: 40,
                padding: isExpanded ? const EdgeInsets.symmetric(horizontal: 16.0) : EdgeInsets.zero,
                child: Row(
                  mainAxisAlignment: isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 40, height: 40,
                      alignment: Alignment.center,
                      child: IconButton(
                        icon: const Icon(Icons.menu),
                        onPressed: () => setState(() => _isPanelOpen = !_isPanelOpen),
                        tooltip: _isPanelOpen ? "Close Menu" : "Open Menu",
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(), 
                        iconSize: 24,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12), // Reduced to 12 to move content up
              
              // "New Chat" Button
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isExpanded ? 16.0 : 0),
                child: isExpanded 
                  ? Material(
                      color: const Color(0xFFE8EDF2), 
                      borderRadius: BorderRadius.circular(24),
                      child: InkWell(
                        onTap: () => _switchTool(ChatTool.chat),
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                          width: double.infinity,
                          child: Row(
                            children: [
                              const Icon(Icons.add, size: 20, color: Colors.black54),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(_getT('sidebar_new_chat'), 
                                  style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : IconButton(
                      icon: Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8EDF2),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Icon(Icons.add, size: 24, color: Colors.black54),
                      ),
                      onPressed: () => _switchTool(ChatTool.chat),
                      tooltip: _getT('sidebar_new_chat'),
                      padding: EdgeInsets.zero,
                    ),
              ),

              if (isExpanded) ...[
                 const SizedBox(height: 32),
                 Padding(
                   padding: const EdgeInsets.symmetric(horizontal: 24.0),
                   child: Text(_getT('sidebar_history'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13)),
                 ),
                 const SizedBox(height: 12),
                 Expanded(
                   child: Scrollbar(
                     controller: _sidebarScrollController,
                     thickness: 4,
                     radius: const Radius.circular(2),
                     child: ListView.builder(
                       controller: _sidebarScrollController,
                       itemCount: _sessions.length,
                       padding: const EdgeInsets.symmetric(horizontal: 12),
                       itemBuilder: (context, index) {
                         final session = _sessions[index];
                         return ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                            title: Text(session.title, style: const TextStyle(fontSize: 14, color: Colors.black87), overflow: TextOverflow.ellipsis),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            onTap: () => _loadSession(session),
                         );
                       },
                     ),
                   ),
                 ),
                 
                 const Divider(height: 1, color: Colors.black12),
                 const Padding(
                   padding: EdgeInsets.all(16.0),
                   child: Text("New York, NY", style: TextStyle(fontSize: 12, color: Colors.grey)), 
                 ),
              ] else ...[
                 const SizedBox(height: 32),
                  Center(
                    child: IconButton(
                      icon: const Icon(Icons.history, color: Colors.black54),
                      onPressed: () => setState(() => _isPanelOpen = true),
                      tooltip: _getT('sidebar_history'),
                    ),
                  ),
                 const Spacer(),
                 Center(
                   child: IconButton(
                     icon: const Icon(Icons.settings_outlined, color: Colors.black54),
                     onPressed: () {},
                   ),
                 ),
                 const SizedBox(height: 24),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildLandingView() {
    return Scrollbar(
      controller: _landingScrollController,
      thickness: 6,
      radius: const Radius.circular(3),
      child: SingleChildScrollView(
        controller: _landingScrollController,
        child: Container(
          width: double.infinity, // Force full width for edge scrollbar
          padding: const EdgeInsets.symmetric(vertical: 60),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 850),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                       // Animated/Premium Greeting
                       ShaderMask(
                         shaderCallback: (bounds) => const LinearGradient(
                           colors: [Color(0xFF1A73E8), Color(0xFF15B79E)],
                         ).createShader(bounds),
                         child: Text(
                           "Multilingual AI-Powered Legal Assistant",
                           style: const TextStyle(
                             fontSize: 42, 
                             fontWeight: FontWeight.bold, 
                             color: Colors.white, // Masked by shader
                             letterSpacing: -1,
                           ),
                           textAlign: TextAlign.center,
                         ),
                       ),
                       const SizedBox(height: 20),
                       Text(
                         "Democratizing access and enhancing compliance in Indian legal processes through advanced NLP.",
                         style: const TextStyle(fontSize: 18, color: Colors.black54, height: 1.4),
                         textAlign: TextAlign.center,
                       ),
                       const SizedBox(height: 64),
                       
                       // Feature Cards
                       if (_currentTool == ChatTool.chat)
                         SizedBox(
                           height: 110, 
                           child: Row(
                             crossAxisAlignment: CrossAxisAlignment.stretch,
                             children: [
                               _buildFeatureCard(ChatTool.incident, "Incident Reporter", "Generate compliant FIR drafts from plain language.", Icons.report_problem_rounded),
                               const SizedBox(width: 16),
                               _buildFeatureCard(ChatTool.fir, "FIR Analyzer", "Extract legal details from scanned documents.", Icons.document_scanner_rounded),
                               const SizedBox(width: 16),
                               _buildFeatureCard(ChatTool.contract, "Contract Review", "Identify non-compliant clauses and risks.", Icons.gavel_rounded),
                             ],
                           ),
                         ),
                       
                       const SizedBox(height: 80),
                       // Centered Input
                       _buildInputArea(isCentered: true),
                       const SizedBox(height: 100), 
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThinkingIndicator() {
    String workingText = _getT('thinking');
    String detailText = _getT('think_chat');

    switch (_currentTool) {
      case ChatTool.incident:
        detailText = _getT('think_incident');
        break;
      case ChatTool.fir:
        detailText = _getT('think_fir');
        break;
      case ChatTool.contract:
        detailText = _getT('think_contract');
        break;
      case ChatTool.chat:
        detailText = _getT('think_chat');
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                workingText,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const SizedBox(width: 32),
              Expanded(
                child: Text(
                  detailText,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(ChatTool tool, String title, String subtitle, IconData icon) {
    return Expanded(
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: () {
            setState(() {
              _currentTool = tool;
            });
          },
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade100, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: const Color(0xFF1A73E8), size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(title, 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1F1F1F)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(subtitle, 
                        style: const TextStyle(color: Colors.black54, fontSize: 13, height: 1.4),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TypewriterMarkdown extends StatefulWidget {
  final String text;
  final MarkdownStyleSheet styleSheet;
  final VoidCallback onFinished;

  const TypewriterMarkdown({
    Key? key, 
    required this.text, 
    required this.styleSheet,
    required this.onFinished
  }) : super(key: key);

  @override
  State<TypewriterMarkdown> createState() => _TypewriterMarkdownState();
}

class _TypewriterMarkdownState extends State<TypewriterMarkdown> {
  String _displayedText = "";
  int _charIndex = 0;
  
  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  void _startAnimation() async {
    while (_charIndex < widget.text.length) {
      if (!mounted) return;
      setState(() {
        _charIndex += 4; // Reveal 4 chars at a time for speed (Gemini is fast)
        if (_charIndex > widget.text.length) _charIndex = widget.text.length;
        _displayedText = widget.text.substring(0, _charIndex);
      });
      await Future.delayed(const Duration(milliseconds: 10)); // ~100fps look
    }
    widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    // Add a blinking cursor at the end while typing
    String content = _displayedText;
    if (_charIndex < widget.text.length) {
      content += " ●"; // Dot cursor
    }
    
    return MarkdownBody(
      data: content,
      selectable: true,
      styleSheet: widget.styleSheet,
    );
  }
}
