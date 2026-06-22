/// Core constants for Journal Trend Analyzer app.
library;

class AppConstants {
  // Private constructor to prevent instantiation of this constants class
  AppConstants._();

  static const String baseUrl = 'https://api.openalex.org';
  static const String mailto = 'cuongndse181836@fpt.edu.vn';

  static const List<String> suggestedTopics = [
    'Artificial Intelligence',
    'Blockchain',
    'Internet of Things',
    'Cybersecurity',
    'Data Science',
    'Software Engineering',
  ];

  static const int requestTimeoutSeconds = 30;
  static const int perPage = 25;
  static const int analyticsPerPage = 10;
  static const int trendPerPage = 100;
  static const int minTrendYear = 1990;
}
