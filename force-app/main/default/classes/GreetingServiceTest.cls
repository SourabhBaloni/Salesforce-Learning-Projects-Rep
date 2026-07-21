@isTest
private class GreetingServiceTest {
  @isTest
  static void returnsDefaultGreetingForBlank() {
    System.assertEquals(
      'Hello, World!',
      GreetingService.greet(''),
      'Empty name should return default greeting'
    );
    System.assertEquals(
      'Hello, World!',
      GreetingService.greet(null),
      'Null name should return default greeting'
    );
    System.assertEquals(
      'Hello, World!',
      GreetingService.greet('   '),
      'Whitespace-only name should return default greeting'
    );
  }

  @isTest
  static void returnsNamedGreetingTrimmed() {
    System.assertEquals(
      'Hello, Sourabh!',
      GreetingService.greet('  Sourabh  '),
      'Named greeting should be trimmed'
    );
  }

  @isTest
  static void greetLoudUppercasesGreeting() {
    System.assertEquals(
      'HELLO, SOURABH!',
      GreetingService.greetLoud('Sourabh'),
      'greetLoud should upper-case the greeting'
    );
  }
}
