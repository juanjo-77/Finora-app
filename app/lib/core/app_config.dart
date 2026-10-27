class AppConfig {
  // Se puede cambiar al compilar: --dart-define=API_URL=http://localhost:5080/api
  static const String apiBaseUrl = String.fromEnvironment('API_URL', defaultValue: 'https://finora-app-jii4.onrender.com/api');
  static const String aiBaseUrl = 'https://finora-app-1.onrender.com';
}
