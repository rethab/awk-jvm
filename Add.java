public class Add {

  public static int main() {
    return add(1, add(10, 10));
  }

  public static int minus(int a, int b) {
    return a - b;
  }

  public static int add(int a, int b) {
    return a + b;
  }
}
