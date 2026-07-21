public with sharing class GreetingService {
  public static String greet(String name) {
    String trimmed = name == null ? '' : name.trim();
    if (String.isBlank(trimmed)) {
      return 'Hello, World!';
    }
    return 'Hello, ' + trimmed + '!';
  }

  public static String greetLoud(String name) {
    return greet(name).toUpperCase();
  }
}
