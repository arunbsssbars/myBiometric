import 'dart:math';

/// Mathematical utilities for biometric facial vector processing.
class FaceMathUtils {
  /// Normalizes a vector to unit length (L2 norm = 1.0).
  static List<double> l2Normalize(List<double> vector) {
    if (vector.isEmpty) return vector;
    double sumOfSquares = 0.0;
    for (int i = 0; i < vector.length; i++) {
      sumOfSquares += vector[i] * vector[i];
    }
    final double norm = sqrt(sumOfSquares);
    if (norm == 0.0) return List<double>.from(vector);
    return vector.map((v) => v / norm).toList();
  }

  /// Calculates cosine similarity between two unit-normalized vectors.
  /// Result ranges from -1.0 to 1.0 (1.0 indicates identical directions).
  static double cosineSimilarity(List<double> v1, List<double> v2) {
    if (v1.length != v2.length || v1.isEmpty) return 0.0;
    double dotProduct = 0.0;
    for (int i = 0; i < v1.length; i++) {
      dotProduct += v1[i] * v2[i];
    }
    return dotProduct;
  }

  /// Calculates Euclidean distance between two vectors.
  static double euclideanDistance(List<double> v1, List<double> v2) {
    if (v1.length != v2.length || v1.isEmpty) return double.infinity;
    double sum = 0.0;
    for (int i = 0; i < v1.length; i++) {
      final double diff = v1[i] - v2[i];
      sum += diff * diff;
    }
    return sqrt(sum);
  }

  /// Computes the mean vector across multiple embeddings and normalizes the result.
  static List<double> averageAndNormalize(List<List<double>> embeddings) {
    if (embeddings.isEmpty) return [];
    final int dimension = embeddings.first.length;
    final int count = embeddings.length;
    final List<double> averaged = List<double>.filled(dimension, 0.0);

    for (int i = 0; i < dimension; i++) {
      double sum = 0.0;
      for (int sample = 0; sample < count; sample++) {
        sum += embeddings[sample][i];
      }
      averaged[i] = sum / count;
    }

    return l2Normalize(averaged);
  }
}
