public with sharing class GreetingService {
  public static String greet(String name) {
    if (String.isBlank(name)) {
      return 'Hello, World!';
    }
    return 'Hello, ' + name + '!';
  }
}
