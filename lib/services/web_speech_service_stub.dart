class WebSpeechService {
  final Function(String text, bool isFinal) onResult;
  final Function(String error) onError;
  final Function(bool isListening) onStatusChange;

  WebSpeechService({
    required this.onResult,
    required this.onError,
    required this.onStatusChange,
  });

  bool get isSupported => false;

  bool get isListening => false;

  void start() {
    onError('unsupported_platform');
  }

  void stop() {}

  void cancel() {}
}
