// Stub implementation for web and non-native platforms where tflite_flutter cannot run.

class InterpreterOptions {
  int threads = 1;
  void addDelegate(dynamic delegate) {}
}

class GpuDelegateV2 {
  GpuDelegateV2();
}

class Interpreter {
  static Future<Interpreter> fromAsset(
    String assetName, {
    InterpreterOptions? options,
  }) async {
    return Interpreter();
  }

  void run(Object input, Object output) {}

  void close() {}
}

extension ReshapeExtension<T> on List<T> {
  List<dynamic> reshape(List<int> shape) {
    return this;
  }
}
