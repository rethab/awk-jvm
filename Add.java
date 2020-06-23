public class Add {

  public static int main() {
    return add(1, minus(10, 5));
  }

  public static int minus(int a, int b) {
    return a - b;
  }

  public static int add(int a, int b) {
    return a + b;
  }
}
