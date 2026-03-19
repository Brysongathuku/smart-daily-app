class ApiConfig {
  // ✅ Using localhost:8081 with adb reverse tunnel
  // Run this command first: adb reverse tcp:8081 tcp:8081
  // This creates a tunnel from emulator to your computer

  static const String baseUrl = 'http://localhost:8081';

  // Alternative if adb reverse doesn't work:
  // 1. Bind backend to 0.0.0.0 (not just 127.0.0.1)
  // 2. Get your computer's IP: ipconfig (Windows) or ifconfig (Mac/Linux)
  // 3. Use: static const String baseUrl = 'http://YOUR_IP:8081';

  // API Endpoints
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String verify = '/auth/verify';
  static const String customers = '/customers';
  static const String farmers = '/farmers';
  static const String admins = '/admins';

  // Helper method to get full URL
  static String getUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }

  // Timeout durations
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
