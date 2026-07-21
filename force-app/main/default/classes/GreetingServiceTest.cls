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
  }

  @isTest
  static void returnsNamedGreeting() {
    System.assertEquals(
      'Hello, Sourabh!',
      GreetingService.greet('Sourabh'),
      'Named greeting should include the name'
    );
  }
}
