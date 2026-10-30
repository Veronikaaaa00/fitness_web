/// Адрес PocketBase задаётся при запуске/сборке:
/// --dart-define=API_BASE_URL=http://127.0.0.1:8090
const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://fitness-pocketbase.onrender.com',
);
