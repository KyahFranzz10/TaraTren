import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'settings_service.dart';
import 'dart:async';
import 'dart:developer' as dev;

class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal() {
    _tts.setCompletionHandler(() {
      _speechCompleter?.complete();
    });
  }

  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();
  Completer<void>? _speechCompleter;

  Future<void> init() async {
    // Basic TTS Config
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    await _tts.setLanguage("en-US");

    // Enable Audio Ducking for TTS
    try {
      await _tts.setIosAudioCategory(IosTextToSpeechAudioCategory.playback,
          [
            IosTextToSpeechAudioCategoryOptions.duckOthers,
            IosTextToSpeechAudioCategoryOptions.defaultToSpeaker
          ],
          IosTextToSpeechAudioMode.defaultMode
      );
    } catch (e) {
      dev.log("TTS Ducking Config Error: $e");
    }

    // Enable Audio Ducking for AudioPlayer (Francis Voicepack)
    try {
      final audioContext = AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: {
            AVAudioSessionOptions.duckOthers,
            AVAudioSessionOptions.defaultToSpeaker,
          },
        ),
        android: AudioContextAndroid(
          contentType: AndroidContentType.speech,
          usageType: AndroidUsageType.assistanceNavigationGuidance,
          audioFocus: AndroidAudioFocus.gainTransientMayDuck,
        ),
      );
      AudioPlayer.global.setAudioContext(audioContext);
    } catch (e) {
      dev.log("AudioPlayer Ducking Config Error: $e");
    }
  }

  Future<void> _awaitSpeak(String text) async {
    _speechCompleter = Completer<void>();
    await _tts.speak(text);
    return _speechCompleter?.future;
  }

  Future<void> speak(String text) async {
    await _tts.stop();
    await _awaitSpeak(text);
  }

  Future<void> _applyLineCharacteristics(String line) async {
    if (line == 'LRT1') {
      await _tts.setPitch(1.1); // Slightly higher, energetic
      await _tts.setSpeechRate(0.48); // Natural, clear speed
    } else if (line == 'LRT2') {
      await _tts.setPitch(0.85); // Lower, more formal/deep
      await _tts.setSpeechRate(0.38); // Slower, prestigious pacing
    } else if (line == 'MRT3') {
      await _tts.setPitch(1.0); // Balanced
      await _tts.setSpeechRate(0.45); // Standard, easy to understand
    } else {
      await _tts.setPitch(1.0);
      await _tts.setSpeechRate(0.45);
    }
  }

  String _sanitizeVoiceText(String text) {
    // Some station names and acronyms need special handling for pronunciation
    String sanitized = text;
    
    // Fix "Dr. Santos" misinterpretation (TTS often says "Drive Santos")
    sanitized = sanitized.replaceAll(RegExp(r'\bDr\.\s*Santos\b', caseSensitive: false), 'Doctor Santos');
    
    // Replace "EDSA" with "Edsa" to ensure the TTS reads it as a word, not individual letters
    sanitized = sanitized.replaceAll(RegExp(r'\bEDSA\b', caseSensitive: false), 'Edsa');
    
    // Example: "FPJ" can be expanded for clearer spelling out
    sanitized = sanitized.replaceAll(RegExp(r'\bFPJ\b', caseSensitive: false), 'Ef-Pe-Jye');
    
    // LRT-1 Manila & LRT-2 segments phonetic cleanup
    sanitized = sanitized.replaceAll(RegExp(r'\bUN Ave\b', caseSensitive: false), 'U. N. Avenue');
    sanitized = sanitized.replaceAll(RegExp(r'\bPedro Gil\b', caseSensitive: false), 'Pedro Hill');
    sanitized = sanitized.replaceAll(RegExp(r'\bRecto\b', caseSensitive: false), 'Rect-toh');
    sanitized = sanitized.replaceAll(RegExp(r'\bPureza\b', caseSensitive: false), 'Poo-reh-za');
    sanitized = sanitized.replaceAll(RegExp(r'\bV. Mapa\b', caseSensitive: false), 'Victorino Mapa');
    sanitized = sanitized.replaceAll(RegExp(r'\bJ. Ruiz\b', caseSensitive: false), 'Juan Ruiz');
    
    return sanitized;
  }

  Future<bool> _playFrancisVoice(String stationId, {bool isArriving = true}) async {
    String lineDir = "";
    if (stationId.startsWith('lrt1-')) {
      lineDir = "LRT1";
    } else if (stationId.startsWith('lrt2-')) {
      lineDir = "LRT2";
    } else {
      return false;
    }

    final prefix = isArriving ? "arriving_" : "next_";
    String fileId = stationId.split('-').skip(1).join('_');
    
    // Custom mappings for the user's recorded filenames
    if (lineDir == "LRT1") {
      if (fileId == 'asiaworld') fileId = 'pitx';
      if (fileId == 'ninoy_aquino') fileId = 'ninoy_aquino_avenue';
      if (fileId == 'doroteo_jose') fileId = 'doreteo_jose'; // User's phonetic spelling
      if (fileId == 'carriedo') fileId = 'carriedo';
      if (fileId == 'central') fileId = 'central';
      if (fileId == 'un_ave') fileId = 'un_ave';
      if (fileId == 'pedro_gil') fileId = 'pedro_gil';
      if (fileId == 'quirino') fileId = 'quirino';
      if (fileId == 'doroteo_jose') fileId = 'doreteo_jose'; 
    } else if (lineDir == "LRT2") {
      if (fileId == 'betty_go') fileId = 'bgb';
      if (fileId == 'j_ruiz') fileId = 'j_ruiz';
      if (fileId == 'v_mapa') fileId = 'v_mapa';
      if (fileId == 'pureza') fileId = 'pureza';
      if (fileId == 'legarda') fileId = 'legarda';
      if (fileId == 'recto') fileId = 'recto';
      if (fileId == 'gilmore') fileId = 'gilmore';
    }
    
    final assetPath = "voice_announcements/$lineDir/$prefix$fileId.m4a";
    
    try {
      dev.log("📢 Attempting personalized voice: $assetPath");
      await _tts.stop();
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource(assetPath));
      return true;
    } catch (e) {
      dev.log("⚠️ Personalized voice failed ($assetPath): $e");
      return false;
    }
  }

  Future<void> announceNextStation({
    required String stationId,
    required String stationName,
    required String line,
  }) async {
    if (!SettingsService().isVoiceEnabled) return;

    // Check for custom Francis voice first if he enabled his pack (or for LRT1 in general)
    if (SettingsService().voicePack == 'francis' || line == 'LRT1' || line == 'LRT2') {
      bool played = await _playFrancisVoice(stationId, isArriving: false);
      if (played) return;
    }

    await _tts.stop();
    await _applyLineCharacteristics(line);
    
    final String sanitized = _sanitizeVoiceText(stationName);
    final String lang = SettingsService().voiceLanguage;
    final String pack = SettingsService().voicePack;
    
    // sequential: ENGLISH then TAGALOG
    if (lang == 'english' || lang == 'both') {
      await _tts.setLanguage("en-US");
      String msg = "Next station is $sanitized.";
      if (pack == 'casual') msg = "Next up is $sanitized. Get ready!";
      if (pack == 'conyo') msg = "Wait, we're like arriving at $sanitized soon. It's super near na!";
      
      await _awaitSpeak(msg);
    }
    
    if (lang == 'both') {
       await Future.delayed(const Duration(milliseconds: 500));
    }
    
    if (lang == 'tagalog' || lang == 'both') {
      await _tts.setLanguage("fil-PH");
      String msg = "Ang susunod na istasyon ay $sanitized.";
      if (pack == 'casual') msg = "Ang susunod nating hinto ay sa $sanitized.";
      if (pack == 'conyo') msg = "Next station na yung $sanitized. Super exciting, 'di ba?";
      
      await _awaitSpeak(msg);
    }
  }

  Future<void> announceArrival({
    required String stationId,
    required String stationName,
    required String line,
    bool isTerminus = false, 
    bool opensOnLeft = false, 
    List<String> connections = const [],
  }) async {
    if (!SettingsService().isVoiceEnabled) return;

    // Check for custom Francis voice first
    if (SettingsService().voicePack == 'francis' || line == 'LRT1' || line == 'LRT2') {
      bool played = await _playFrancisVoice(stationId, isArriving: true);
      if (played) return;
    }

    await _tts.stop();
    await _applyLineCharacteristics(line);
    
    final String sanitized = _sanitizeVoiceText(stationName);
    final String lang = SettingsService().voiceLanguage;
    final String pack = SettingsService().voicePack;
    final String doorSideEn = opensOnLeft ? "Left" : "Right";
    final String doorSideTl = opensOnLeft ? "kaliwa" : "kanan";
    
    if (lang == 'english' || lang == 'both') {
      await _tts.setLanguage("en-US");
      String message = "Arriving in $sanitized. $doorSideEn Doors will be open.";
      if (pack == 'casual') message = "We've arrived at $sanitized. Exit on the ${doorSideEn.toLowerCase()} side, please!";
      if (pack == 'conyo') message = "We're here na in $sanitized! Doors are like opening on the ${doorSideEn.toLowerCase()}.";

      if (connections.isNotEmpty) {
        String connectionStr = connections.map((c) => _sanitizeVoiceText(c)).join(" and ");
        String connMsg = " Transfer to $connectionStr is available.";
        if (pack == 'conyo') connMsg = " You can like transfer to $connectionStr here if you want.";
        message += connMsg;
      }
      
      if (isTerminus) {
        String termMsg = " This is the end of the line. Please ensure you have all your belongings with you.";
        if (pack == 'conyo') termMsg = " This is like the last stop na. Don't forget your things, okay?";
        message += termMsg;
      }
      await _awaitSpeak(message);
    }
    
    if (lang == 'both') await Future.delayed(const Duration(milliseconds: 500));
    
    if (lang == 'tagalog' || lang == 'both') {
      await _tts.setLanguage("fil-PH");
      String message = "Paparating na sa $sanitized. Sa $doorSideTl pintuan magbubukas.";
      if (pack == 'casual') message = "Nandito na tayo sa $sanitized. Ingat sa pagbaba sa $doorSideTl.";
      if (pack == 'conyo') message = "Finally, $sanitized na! Ingat sa doors ha, sa $doorSideTl side siya.";

      if (connections.isNotEmpty) {
        message += " Maaaring lumipat papunta sa mga linyang ito.";
      }
      
      if (isTerminus) {
        message += " Ito na ang huling istasyon. Pakisiguro na dala ninyo ang lahat ng inyong mga kagamitan.";
      }
      await _awaitSpeak(message);
    }
  }
}
