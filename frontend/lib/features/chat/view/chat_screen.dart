import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../core/widgets/futuristic_widgets.dart';
import '../../../core/services/api_service.dart';
import '../../../core/providers/language_provider.dart';

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
  final String? thoughts; // Metadata/Reasoning
  final Uint8List? imageData; // For visual previews
  final String? fileExtension;
  final String? fileName; // New: For file cards

  ChatMessage({
    required this.text, 
    this.fromUser = false, 
    this.isAnimated = false,
    this.thoughts,
    this.imageData,
    this.fileExtension,
    this.fileName,
  });
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

  // Localization Map
  final Map<String, Map<String, String>> _localizedStrings = {
    'en': {
      'app_title': 'Ai Legal Assistant',
      'hero_greeting': 'Multilingual AI Legal Intelligence',
      'hero_subtitle': 'Empowering Indian legal processes with high-performance neural analysis and multilingual precision.',
      'feature_incident_title': 'Incident Reporter',
      'feature_incident_sub': 'Draft reports with AI legal logic.',
      'feature_fir_title': 'FIR Analyzer',
      'feature_fir_sub': 'Deep document extraction.',
      'feature_contract_title': 'Contract Review',
      'feature_contract_sub': 'Neural clause risk detection.',
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
      'tooltip_close_menu': 'Close Menu',
      'tooltip_open_menu': 'Open Menu',
      'sidebar_footer': 'Ind legal assistance',
    },
    'hi': {
      'app_title': 'एआई कानूनी सहायक',
      'hero_greeting': 'बहुभाषी एआई कानूनी खुफिया',
      'hero_subtitle': 'उच्च प्रदर्शन तंत्रिका विश्लेषण और बहुभाषी सटीकता के साथ भारतीय कानूनी प्रक्रियाओं को सशक्त बनाना।',
      'feature_incident_title': 'घटना रिपोर्टर',
      'feature_incident_sub': 'एआई कानूनी तर्क के साथ रिपोर्ट तैयार करें।',
      'feature_fir_title': 'एफआईआर विश्लेषक',
      'feature_fir_sub': 'गहन दस्तावेज़ निष्कर्षण।',
      'feature_contract_title': 'अनुबंध समीक्षा',
      'feature_contract_sub': 'न्यूरल क्लॉज जोखिम का पता लगाना।',
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
      'tooltip_close_menu': 'मेनू बंद करें',
      'tooltip_open_menu': 'मेनू खोलें',
      'sidebar_footer': 'भारतीय कानूनी सहायता',
    },
    'bn': {
      'app_title': 'এআই আইনি সহকারী',
      'hero_greeting': 'বহুভাষী এআই আইনি গোয়েন্দা',
      'hero_subtitle': 'উচ্চ-পারফরম্যান্স নিউরাল বিশ্লেষণ এবং বহুভাষী নির্ভুলতার সাথে ভারতীয় আইনি প্রক্রিয়াগুলিকে শক্তিশালী করা।',
      'feature_incident_title': 'ঘটনা রিপোর্টার',
      'feature_incident_sub': 'এআই আইনি যুক্তি সহ রিপোর্ট তৈরি করুন।',
      'feature_fir_title': 'এফআইআর বিশ্লেষক',
      'feature_fir_sub': 'গভীর নথি নিষ্কাশন।',
      'feature_contract_title': 'চুক্তি পর্যালোচনা',
      'feature_contract_sub': 'নিউরাল ক্লজ ঝুঁকি সনাক্তকরণ।',
      'thinking': 'ভাবছি...',
      'input_hint': 'যেকোনো কিছু জিজ্ঞাসা করুন...',
      'think_incident': 'ঘটনার বিবরণ বিশ্লেষণ এবং রিপোর্ট তৈরি করছি...',
      'think_fir': 'এফআইআর নথি থেকে আইনি ধারা বের করছি...',
      'think_contract': 'চুক্তির ধারা পর্যালোচনা এবং ঝুঁকি চিহ্নিত করছি...',
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
      'tooltip_close_menu': 'মেনু বন্ধ করুন',
      'tooltip_open_menu': 'মেনু খুলুন',
      'sidebar_footer': 'ভারতীয় আইনি সহায়তা',
    },
    'te': {
      'app_title': 'ఏఐ లీగల్ అసిస్టెంట్',
      'hero_greeting': 'బహుభాషా ఏఐ లీగల్ ఇంటెలిజెన్స్',
      'hero_subtitle': 'అధిక-పనితీరు గల న్యూరల్ విశ్లేషణ మరియు బహుభాషా ఖచ్చితత్వంతో భారతీయ చట్టపరమైన ప్రక్రియలను శక్తివంతం చేయడం.',
      'feature_incident_title': 'ఇన్సిడెంట్ రిపోర్టర్',
      'feature_incident_sub': 'ఏఐ లీగల్ లాజిక్‌తో నివేదికలను రూపొందించండి.',
      'feature_fir_title': 'ఎఫ్ఐఆర్ అనలైజర్',
      'feature_fir_sub': 'లోతైన పత్రం వెలికితీత.',
      'feature_contract_title': 'కాంట్రాక్ట్ సమీక్ష',
      'feature_contract_sub': 'న్యూరల్ క్లాజ్ రిస్క్ గుర్తింపు.',
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
      'tooltip_close_menu': 'మెనూను మూసివేయి',
      'tooltip_open_menu': 'మెనూను తెరువు',
      'sidebar_footer': 'భారతీయ చట్టపరమైన సహాయం',
    },
    'mr': {
      'app_title': 'एआय कायदेशीर सहाय्यक',
      'hero_greeting': 'बहुभाषिक एआय कायदेशीर बुद्धिमत्ता',
      'hero_subtitle': 'उच्च-कार्यक्षमता न्यूरल विश्लेषण आणि बहुभाषिक अचूकतेसह भारतीय कायदेशीर प्रक्रिया सक्षम करणे।',
      'feature_incident_title': 'घटना रिपोर्टर',
      'feature_incident_sub': 'एआय कायदेशीर तर्कासह अहवाल तयार करा।',
      'feature_fir_title': 'एफआयआर विश्लेषक',
      'feature_fir_sub': 'खोल दस्तऐवज काढणे।',
      'feature_contract_title': 'करार पुनरावलोकन',
      'feature_contract_sub': 'न्यूरल क्लॉज जोखीम शोधणे।',
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
      'tooltip_close_menu': 'मेनू बंद करा',
      'tooltip_open_menu': 'मेनू उघडा',
      'sidebar_footer': 'भारतीय कायदेशीर मदत',
    },
  };

  String _getT(String key) {
    // Use listen: false to avoid exceptions when called from callbacks or menus
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    return _localizedStrings[languageProvider.selectedLanguage]?[key] ?? _localizedStrings['en']![key]!;
  }
  
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ScrollController _landingScrollController = ScrollController(); // New
  final ScrollController _sidebarScrollController = ScrollController(); // New
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>(); 
  final FocusNode _focusNode = FocusNode(); // New: For auto-focus
  
  bool _loading = false;
  bool _isStopping = false; // New: Flag to ignore response if stopped
  String _lastSentText = ""; // New: Store text to restore on stop
  List<PlatformFile> _lastSentAttachments = []; // New: Store attachments to restore on stop
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

    if (!mounted || _isStopping) return;

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
    if (text.isEmpty && _attachments.isEmpty) return; // Allow empty text if file is present
    _lastSentText = text; // Store for restoration
    _lastSentAttachments = List.from(_attachments); // Store for restoration

    PlatformFile? firstFile;
    if (_attachments.isNotEmpty) {
      firstFile = _attachments.first;
    }

    // Switch to Chat View immediately
    setState(() {
      _showLanding = false;
      Uint8List? previewImage;
      String? ext;
      String? fName;
      if (firstFile != null) {
        ext = firstFile.extension;
        fName = firstFile.name;
        if (['jpg', 'jpeg', 'png', 'webp'].contains(ext?.toLowerCase())) {
          previewImage = firstFile.bytes;
        }
      }

      _messages.insert(0, ChatMessage(
        text: text, 
        fromUser: true, 
        isAnimated: true,
        imageData: previewImage,
        fileExtension: ext,
        fileName: fName,
      ));
      _loading = true;
      _isStopping = false; // Reset stop flag
      _controller.clear();
      _attachments.clear(); // Clear immediately for UI
      _focusNode.requestFocus(); // Auto-focus back to input
    });

    final api = Provider.of<ApiService>(context, listen: false);
    try {
      if (firstFile != null) {
        final item = firstFile;
        if (_currentTool == ChatTool.fir) {
          Uint8List? fileBytes = item.bytes;
          if (fileBytes == null && item.path != null) {
            fileBytes = File(item.path!).readAsBytesSync();
          }
          
          if (fileBytes == null) {
            throw Exception("Could not read file data. Please try again.");
          }

          final selectedLang = Provider.of<LanguageProvider>(context, listen: false).selectedLanguage;
          final resp = await api.analyzeFIR(item.name, fileBytes, selectedLang);
          final summary = (resp['summary'] ?? '').toString();
          final extracted = (resp['extracted_text'] ?? '').toString();
          final entities = resp['entities'] ?? {};
          final sections = List<String>.from(resp['detected_sections'] ?? []);

          String thoughtContent = "### Extracted Text\n$extracted\n\n";
          if (sections.isNotEmpty) {
            thoughtContent += "### Detected Sections\n${sections.join(', ')}\n\n";
          }
          if (entities.isNotEmpty) {
            thoughtContent += "### Entities Found\n$entities";
          }

          if (!mounted || _isStopping) return;
          setState(() {
            _messages.insert(0, ChatMessage(
              text: summary, 
              fromUser: false,
              thoughts: thoughtContent,
            ));
            _loading = false;
          });
          return;
        } else if (_currentTool == ChatTool.contract) {
          Uint8List? fileBytes = item.bytes;
          if (fileBytes == null && item.path != null) {
            fileBytes = File(item.path!).readAsBytesSync();
          }

          if (fileBytes == null) {
            throw Exception("Could not read file data. Please try again.");
          }

          final selectedLang = Provider.of<LanguageProvider>(context, listen: false).selectedLanguage;
          final resp = await api.reviewContract(item.name, fileBytes, selectedLang);
          final summary = (resp['summary'] ?? '').toString();
          final extracted = (resp['extracted_text'] ?? '').toString();
          final entities = resp['entities'] ?? {};
          final clauses = resp['clauses'] ?? [];
          
          String thoughtContent = "### Extracted Text\n$extracted\n\n";
          if (clauses.isNotEmpty) {
            thoughtContent += "### Clauses Found\n";
            for (var c in clauses) {
               thoughtContent += "- **${c['status'].toString().toUpperCase()}**: ${c['clause']}\n";
            }
            thoughtContent += "\n";
          }
          if (entities.isNotEmpty) {
            thoughtContent += "### Entities Found\n$entities";
          }
          
          if (!mounted || _isStopping) return;
          setState(() {
            _messages.insert(0, ChatMessage(
              text: summary, 
              fromUser: false,
              thoughts: thoughtContent,
            ));
            _loading = false;
          });
          return;
        }
      }

      if (_currentTool == ChatTool.incident) {
           // Pass selected language
           final selectedLang = Provider.of<LanguageProvider>(context, listen: false).selectedLanguage;
           final resp = await api.generateIncident(selectedLang, text);
           final firText = (resp['fir_text'] ?? '').toString();
           String reply = firText; 
           if (!mounted || _isStopping) return;
           setState(() {
             _messages.insert(0, ChatMessage(text: reply, fromUser: false));
             _loading = false;
           });
      } else if (_currentTool == ChatTool.chat) {
         final selectedLang = Provider.of<LanguageProvider>(context, listen: false).selectedLanguage;
         final reply = await api.chat(text, selectedLang);
         if (!mounted || _isStopping) return;
         setState(() {
           _messages.insert(0, ChatMessage(text: reply, fromUser: false));
           _loading = false;
         });
      } else {
         // Fallback for file tools when no file is attached
         await Future.delayed(const Duration(milliseconds: 500));
         if (!mounted || _isStopping) return;
         setState(() {
            _messages.insert(0, ChatMessage(text: "For ${_toolName(_currentTool)}, please use the **(+) Plus Button** to upload a document.", fromUser: false));
            _loading = false;
          });
      }
    } catch (e) {
       if (!mounted || _isStopping) return;
       setState(() {
         _messages.insert(0, ChatMessage(text: "Error: ${e.toString()}", fromUser: false));
         _loading = false;
       });
    }
  }

  void _stopMessage() {
    setState(() {
      _isStopping = true;
      _loading = false;
      _controller.text = _lastSentText;
      _attachments = List.from(_lastSentAttachments); // Restore attachments
      _messages.insert(0, ChatMessage(text: "You stopped this response", fromUser: false));
      _focusNode.requestFocus();
    });
  }

  Future<void> _pickFiles(FileType type) async {
    try {
      print("Picking files with type: $type");
      FilePickerResult? result;
      
      if (type == FileType.any) {
        // For Windows, sometimes custom extensions are more reliable
        result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'jpg', 'png', 'jpeg', 'webp'],
          allowMultiple: true,
          withData: true,
        );
      } else {
        result = await FilePicker.platform.pickFiles(
          type: type,
          allowMultiple: true,
          withData: true,
        );
      }

      final pickedResult = result;
      if (pickedResult != null) {
        print("Selected ${pickedResult.files.length} files");
        setState(() {
          _attachments.addAll(pickedResult.files);
        });
      } else {
        print("User cancelled file pick");
      }
    } on PlatformException catch (e) {
      print("PlatformException in _pickFiles: ${e.code} - ${e.message}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error picking files: ${e.message}")),
      );
    } catch (e) {
      print("Exception in _pickFiles: $e");
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
    // Listen to LanguageProvider here so the whole screen rebuilds when language changes
    Provider.of<LanguageProvider>(context); 
    final isLight = Theme.of(context).brightness == Brightness.light;
    
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isLight ? Colors.white : const Color(0xFF0F172A),
      body: Row(
        children: [
          // 1. Unified Sidebar (Collapsible)
          _buildSidebar(),
          
          // 2. Main Content
          Expanded(
            child: Stack(
              children: [
                // Futuristic background
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isLight ? Colors.white : const Color(0xFF0F172A), // Slate 900
                    ),
                  ),
                ),
                // Animated background blobs removed as per request
                
                Column(
                  children: [
                    // Persistent Top Bar
                    _buildTopBar(),
                    
                    // View Content
                    Expanded(
                      child: _showLanding ? _buildLandingView() : _buildChatView(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: isLight ? Colors.white.withOpacity(0.8) : Colors.white.withOpacity(0.05),
            border: Border(bottom: BorderSide(color: isLight ? Colors.black.withOpacity(0.05) : Colors.white.withOpacity(0.1))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    _getT('app_title'),
                    style: const TextStyle(
                      fontSize: 22, 
                      fontWeight: FontWeight.w700, 
                      color: Color(0xFFA68A64),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.balance, color: Color(0xFFA68A64), size: 24),
                ],
              ),
              // Language selector / Profile
              Row(
                children: [
                   _buildLanguageSelector(),
                 ],
               ),
            ],
          ),
        ),
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isLight ? Colors.black.withOpacity(0.02) : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isLight ? Colors.black.withOpacity(0.05) : Colors.white.withOpacity(0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: Provider.of<LanguageProvider>(context).selectedLanguage,
          isDense: true,
          dropdownColor: isLight ? Colors.white : const Color(0xFF1E293B), // Slate 800
          icon: Icon(Icons.language, size: 16, color: isLight ? Colors.black54 : Colors.white70),
          onChanged: (String? newValue) {
            if (newValue != null) {
              Provider.of<LanguageProvider>(context, listen: false).setLanguage(newValue);
            }
          },
          items: languages.entries.map((entry) {
            return DropdownMenuItem<String>(
              value: entry.key,
              child: Text(entry.value, style: TextStyle(fontSize: 13, color: isLight ? Colors.black87 : Colors.white)),
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
              padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
              itemBuilder: (context, i) {
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: SlideFadeTransition(
                      child: i == 0 && _loading 
                        ? _buildThinkingIndicator()
                        : _buildMessage(_messages[_loading ? i - 1 : i]),
                    ),
                  ),
                );
              },
              itemCount: _messages.length + (_loading ? 1 : 0),
            ),
          ),
        ),
        _buildInputArea(isCentered: false),
      ],
    );
  }

  Widget _buildMessage(ChatMessage m) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    if (m.fromUser) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (m.imageData != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.memory(m.imageData!, width: 300, fit: BoxFit.contain),
                      ),
                    ),
                  if (m.fileExtension?.toLowerCase() == 'pdf')
                    _buildPdfCard(m),
                   if (m.text.isNotEmpty)
                    GlassCard(
                      color: const Color(0xFFA68A64).withOpacity(isLight ? 0.7 : 0.15),
                      borderColor: const Color(0xFFA68A64).withOpacity(isLight ? 0.2 : 0.3),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(5),
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                      child: SelectableText(
                        m.text,
                        style: TextStyle(fontSize: 16, height: 1.5, color: isLight ? Colors.white : Colors.white),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFA68A64).withOpacity(0.5)),
              ),
              child: Center(child: Icon(Icons.person, size: 20, color: isLight ? const Color(0xFFA68A64) : Colors.white)),
            ),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36, height: 36,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [Color(0xFFA68A64), Color(0xFF8B5E3C)]),
              ),
              child: const Icon(Icons.auto_awesome, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 16),
             Flexible(
              child: SelectionArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_toolName(_currentTool), style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: isLight ? Colors.black45 : Colors.white.withOpacity(0.5))),
                    const SizedBox(height: 8),
                    if (m.thoughts != null && m.thoughts!.isNotEmpty)
                      ThoughtsWidget(thoughts: m.thoughts!),
                    const SizedBox(height: 8),
                    GlassCard(
                      borderColor: isLight ? Colors.black.withOpacity(0.05) : Colors.white.withOpacity(0.1),
                      child: m.isAnimated 
                        ? MarkdownBody(
                            data: m.text,
                            selectable: false,
                            styleSheet: _markdownStyle(),
                          )
                        : TypewriterMarkdown(
                            text: m.text,
                            styleSheet: _markdownStyle(),
                            onFinished: () {
                              m.isAnimated = true; // Mark as done
                            },
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildPdfCard(ChatMessage m) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF1F1F1F), // Slate 100 or Dark grey
        borderRadius: BorderRadius.circular(20),
        border: isLight ? Border.all(color: Colors.black.withOpacity(0.05)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            (m.fileName ?? "Document").split('.').first,
            style: TextStyle(color: isLight ? Colors.black87 : Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red.shade700,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text("PDF", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
               Text("PDF", style: TextStyle(color: isLight ? Colors.black54 : Colors.white70, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  MarkdownStyleSheet _markdownStyle() {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return MarkdownStyleSheet(
      p: TextStyle(fontSize: 16, height: 1.6, color: isLight ? Colors.black87 : Colors.white, fontFamily: 'Roboto'),
      h1: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1.5, color: isLight ? Colors.black : Colors.white),
      h2: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, height: 1.5, color: isLight ? Colors.black : Colors.white),
      strong: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFA68A64)),
      listBullet: TextStyle(fontSize: 16, color: isLight ? Colors.black54 : Colors.white70),
      blockSpacing: 12,
      code: TextStyle(backgroundColor: isLight ? Colors.black.withOpacity(0.05) : Colors.white.withOpacity(0.1), color: const Color(0xFFA68A64)),
      codeblockDecoration: BoxDecoration(
        color: isLight ? Colors.black.withOpacity(0.03) : Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
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
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      width: isCentered ? 800 : null,
      padding: isCentered ? EdgeInsets.zero : const EdgeInsets.all(16.0),
      child: Center(
        child: Container(
           constraints: const BoxConstraints(maxWidth: 800),
           decoration: BoxDecoration(
             color: isLight ? const Color(0xFFF1F5F9) : Colors.white.withOpacity(0.05),
             borderRadius: BorderRadius.circular(24), 
             border: Border.all(color: isLight ? Colors.black.withOpacity(0.05) : Colors.white.withOpacity(0.1)),
             boxShadow: isCentered ? [BoxShadow(color: isLight ? Colors.black12 : Colors.black26, blurRadius: 20, offset: const Offset(0, 10))] : null,
           ),
           padding: const EdgeInsets.all(16),
           child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             mainAxisSize: MainAxisSize.min,
             children: [
              if (_attachments.isNotEmpty)
                Container(
                  height: 100,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _attachments.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final file = _attachments[index];
                      final isImage = ['jpg', 'jpeg', 'png', 'webp'].contains(file.extension?.toLowerCase());
                      
                      return GlassCard(
                        borderRadius: BorderRadius.circular(16),
                        padding: EdgeInsets.zero,
                        child: SizedBox(
                          width: isImage ? 120 : 180,
                          child: Stack(
                            children: [
                              if (isImage && file.bytes != null)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.memory(file.bytes!, width: double.infinity, height: double.infinity, fit: BoxFit.cover),
                                )
                              else
                                Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(_getFileIcon(file.extension), size: 32, color: const Color(0xFFA68A64)),
                                      const SizedBox(height: 4),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                        child: Text(
                                          file.name,
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: IconButton(
                                  icon: const Icon(Icons.close, size: 14, color: Colors.white),
                                  onPressed: () => setState(() => _attachments.removeAt(index)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

              TextField(
                controller: _controller,
                focusNode: _focusNode,
                minLines: 1,
                maxLines: 12,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(fontSize: 16, height: 1.5, color: isLight ? Colors.black87 : Colors.white),
                cursorColor: const Color(0xFFA68A64),
                decoration: InputDecoration(
                  hintText: _getT('input_hint'),
                  hintStyle: TextStyle(color: isLight ? Colors.black38 : Colors.white.withOpacity(0.5)),
                  filled: false,
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  hoverColor: Colors.transparent,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
                onChanged: (val) => setState(() {}),
                onSubmitted: (_) => _sendMessage(),
              ),
              
              const SizedBox(height: 12),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _buildPopupMenu(
                        icon: Icons.add,
                        tooltip: _getT('upload_files'),
                        transparent: true,
                        items: [
                          _buildPopupItem(Icons.attach_file, _getT('upload_files')),
                          _buildPopupItem(Icons.photo_library, _getT('photos')),
                        ],
                        onSelected: (val) {
                          if (val == _getT('upload_files')) _pickFiles(FileType.any);
                          else if (val == _getT('photos')) _pickFiles(FileType.image);
                        },
                      ),
                       const SizedBox(width: 8),
                       _buildPopupMenu(
                         icon: Icons.tune,
                         tooltip: _getT('select_mode'),
                         items: ChatTool.values.where((t) => t != ChatTool.chat).map((tool) {
                           return PopupMenuItem(
                             value: tool,
                             child: Row(
                               children: [
                                 Icon(_toolIcon(tool), color: Colors.white70, size: 20),
                                 const SizedBox(width: 12),
                                 Expanded(child: Text(_toolName(tool), style: const TextStyle(fontSize: 14, color: Colors.white))),
                                 if (_currentTool == tool)
                                   const Icon(Icons.check_circle, color: Color(0xFFA68A64), size: 18),
                               ],
                             ),
                           );
                         }).toList(),
                         onSelected: (val) {
                            if (val is ChatTool) _switchTool(val);
                         },
                       ),
                       const SizedBox(width: 12),
                       if (_currentTool != ChatTool.chat)
                         Container(
                           decoration: BoxDecoration(
                             color: const Color(0xFFA68A64).withOpacity(0.2),
                             borderRadius: BorderRadius.circular(20),
                             border: Border.all(color: const Color(0xFFA68A64).withOpacity(0.4)),
                           ),
                           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                           child: Row(
                             mainAxisSize: MainAxisSize.min,
                             children: [
                               const Icon(Icons.auto_awesome, size: 14, color: Color(0xFFA68A64)), 
                               const SizedBox(width: 6),
                               Text(_toolName(_currentTool), style: const TextStyle(fontSize: 13, color: Color(0xFFA68A64), fontWeight: FontWeight.w600)),
                               const SizedBox(width: 4),
                               InkWell(
                                 onTap: () => _switchTool(ChatTool.chat),
                                 child: const Icon(Icons.close, size: 14, color: Color(0xFFA68A64)),
                               )
                             ],
                           ),
                         ),
                     ],
                   ),
                      IconButton(
                        icon: _loading 
                          ? Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFA68A64),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(Icons.stop, size: 16, color: Colors.white),
                            ) 
                          : const Icon(Icons.send_rounded, color: Color(0xFFA68A64)),
                        onPressed: _loading ? _stopMessage : _sendMessage,
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
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: transparent ? Colors.transparent : (isLight ? Colors.black.withOpacity(0.05) : Colors.grey.shade100),
      ),
      child: PopupMenuButton(
        tooltip: tooltip,
        icon: Icon(icon, color: isLight ? Colors.black54 : Colors.black54, size: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        // offset: const Offset(0, -120), // Removed to allow default 'under' positioning
        position: PopupMenuPosition.under,
        color: isLight ? Colors.white : const Color(0xFF1E293B),
        elevation: 4,
        onSelected: onSelected,
        itemBuilder: (context) => items,
      ),
    );
  }

  PopupMenuItem _buildPopupItem(IconData icon, String text) {
     final isLight = Theme.of(context).brightness == Brightness.light;
     return PopupMenuItem(
       value: text,
       child: Row(
         children: [
           Icon(icon, color: isLight ? Colors.black54 : Colors.white, size: 20),
           const SizedBox(width: 12),
           Text(text, style: TextStyle(fontSize: 14, color: isLight ? Colors.black87 : Colors.white)),
         ],
       ),
     );
  }

  Widget _buildSidebar() {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: _isPanelOpen ? 260 : 72,
      child: Stack(
        children: [
          // Glass background
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: isLight ? Colors.white.withOpacity(0.8) : Colors.white.withOpacity(0.05),
                  border: Border(right: BorderSide(color: isLight ? Colors.black.withOpacity(0.05) : Colors.white.withOpacity(0.1))),
                ),
              ),
            ),
          ),
          
          LayoutBuilder(
            builder: (context, constraints) {
              final bool isExpanded = constraints.maxWidth > 150;

              return Column(
                crossAxisAlignment: isExpanded ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 12),
                  
                  Container(
                    height: 40,
                    padding: isExpanded ? const EdgeInsets.symmetric(horizontal: 16.0) : EdgeInsets.zero,
                    child: Row(
                      mainAxisAlignment: isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(Icons.menu, color: isLight ? Colors.black54 : Colors.white70),
                          onPressed: () => setState(() => _isPanelOpen = !_isPanelOpen),
                           tooltip: _isPanelOpen ? _getT('tooltip_close_menu') : _getT('tooltip_open_menu'),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: isExpanded ? 16.0 : 8.0),
                    child: InkWell(
                      onTap: () => _switchTool(ChatTool.chat),
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 16, horizontal: isExpanded ? 20 : 0),
                        decoration: BoxDecoration(
                          color: isLight ? Colors.black.withOpacity(0.04) : Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: isLight ? Colors.black.withOpacity(0.05) : Colors.white.withOpacity(0.1)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_rounded, size: 24, color: Color(0xFFA68A64)),
                            if (isExpanded) ...[
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(_getT('sidebar_new_chat'), 
                                  style: TextStyle(color: isLight ? Colors.black87 : Colors.white, fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),

                  if (isExpanded) ...[
                     const SizedBox(height: 32),
                     Padding(
                       padding: const EdgeInsets.symmetric(horizontal: 24.0),
                       child: Text(_getT('sidebar_history').toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, color: isLight ? Colors.black.withOpacity(0.3) : Colors.white.withOpacity(0.4), fontSize: 11, letterSpacing: 1.2)),
                     ),
                     const SizedBox(height: 12),
                     Expanded(
                       child: Scrollbar(
                         controller: _sidebarScrollController,
                         child: ListView.builder(
                           controller: _sidebarScrollController,
                           itemCount: _sessions.length,
                           padding: const EdgeInsets.symmetric(horizontal: 12),
                           itemBuilder: (context, index) {
                             final session = _sessions[index];
                             return ListTile(
                                dense: true,
                                title: Text(session.title, style: TextStyle(fontSize: 14, color: isLight ? Colors.black87 : Colors.white70), overflow: TextOverflow.ellipsis),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                hoverColor: isLight ? Colors.black.withOpacity(0.04) : Colors.white.withOpacity(0.05),
                                onTap: () => _loadSession(session),
                             );
                           },
                         ),
                       ),
                     ),
                     
                     Padding(
                       padding: const EdgeInsets.all(16.0),
                       child: Text(_getT('sidebar_footer'), style: TextStyle(fontSize: 11, color: isLight ? Colors.black26 : Colors.white24)), 
                     ),
                  ] else ...[
                     const SizedBox(height: 32),
                      Center(
                        child: IconButton(
                          icon: Icon(Icons.history_rounded, color: isLight ? Colors.black54 : Colors.white70),
                          onPressed: () => setState(() => _isPanelOpen = true),
                        ),
                      ),
                      const SizedBox(height: 24),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLandingView() {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Scrollbar(
      controller: _landingScrollController,
      child: SingleChildScrollView(
        controller: _landingScrollController,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 80),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                       // Premium Greeting
                       SlideFadeTransition(
                         duration: const Duration(seconds: 1),
                         child: Column(
                           children: [
                              Text(
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
                             const SizedBox(height: 24),
                             Text(
                               _getT('hero_subtitle'),
                               style: TextStyle(
                                 fontSize: 20, 
                                 color: isLight ? Colors.black54 : Colors.white.withOpacity(0.5), 
                                 height: 1.5, 
                                 fontWeight: FontWeight.w400
                               ),
                               textAlign: TextAlign.center,
                             ),
                           ],
                         ),
                       ),
                       const SizedBox(height: 72),
                       
                       // Feature Cards
                       if (_currentTool == ChatTool.chat)
                         SlideFadeTransition(
                           delay: const Duration(milliseconds: 200),
                           child: SizedBox(
                                                           // height removed

                             child: Row(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 _buildFeatureCard(ChatTool.incident, _getT('feature_incident_title'), _getT('feature_incident_sub'), Icons.bolt_rounded),
                                 const SizedBox(width: 16),
                                 _buildFeatureCard(ChatTool.fir, _getT('feature_fir_title'), _getT('feature_fir_sub'), Icons.search_rounded),
                                 const SizedBox(width: 16),
                                 _buildFeatureCard(ChatTool.contract, _getT('feature_contract_title'), _getT('feature_contract_sub'), Icons.security_rounded),
                               ],
                             ),
                           ),
                         ),
                       
                       const SizedBox(height: 72),
                       SlideFadeTransition(
                         delay: const Duration(milliseconds: 400),
                         child: _buildInputArea(isCentered: true),
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
    );
  }

  Widget _buildThinkingIndicator() {
    final isLight = Theme.of(context).brightness == Brightness.light;
    String workingText = "LEGAL_CORE";
    String detailText = _getT('think_chat');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Container(
            width: 36, height: 36,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [Color(0xFFA68A64), Color(0xFF8B5E3C)]),
            ),
            child: const Icon(Icons.auto_awesome, size: 20, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(workingText, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFFA68A64), letterSpacing: 2)),
                const SizedBox(height: 12),
                const ShimmerBox(),
                const SizedBox(height: 12),
                Text(detailText, style: TextStyle(color: isLight ? Colors.black38 : Colors.white.withOpacity(0.3), fontSize: 13, fontStyle: FontStyle.italic)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(ChatTool tool, String title, String subtitle, IconData icon) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Expanded(
      child: GlassCard(
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: () => setState(() => _currentTool = tool),
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFA68A64).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: const Color(0xFFA68A64), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: isLight ? Colors.black87 : Colors.white)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: TextStyle(color: isLight ? Colors.black45 : Colors.white.withOpacity(0.4), fontSize: 11, height: 1.2)),
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
        // Fast but smooth fluid revelation
        int increment = (widget.text.length - _charIndex) > 10 ? 3 : 1;
        _charIndex += increment;
        if (_charIndex > widget.text.length) _charIndex = widget.text.length;
        _displayedText = widget.text.substring(0, _charIndex);
      });
      await Future.delayed(const Duration(milliseconds: 5));
    }
    widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    String content = _displayedText;
    if (_charIndex < widget.text.length) {
      content += " ▎"; // Thinner, more modern cursor
    }
    
    return MarkdownBody(
      data: content,
      selectable: false,
      styleSheet: widget.styleSheet,
    );
  }
}
