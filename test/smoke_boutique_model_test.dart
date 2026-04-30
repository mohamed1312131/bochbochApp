import 'package:flutter_test/flutter_test.dart';
import 'package:dido/features/boutiques/domain/boutique_models.dart';

void main() {
  group('Boutique', () {
    test('isOnboarded returns false when category missing', () {
      final b = Boutique(
        id: 'id',
        name: 'My Shop',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        city: 'Tunis',
        category: null,
      );
      expect(b.isOnboarded, isFalse);
    });

    test('isOnboarded returns false when city missing', () {
      final b = Boutique(
        id: 'id',
        name: 'My Shop',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        category: 'Vêtements',
        city: null,
      );
      expect(b.isOnboarded, isFalse);
    });

    test('isOnboarded returns false when name empty', () {
      final b = Boutique(
        id: 'id',
        name: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        category: 'Vêtements',
        city: 'Tunis',
      );
      expect(b.isOnboarded, isFalse);
    });

    test('isOnboarded returns true when all required fields populated', () {
      final b = Boutique(
        id: 'id',
        name: 'My Shop',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        category: 'Vêtements',
        city: 'Tunis',
      );
      expect(b.isOnboarded, isTrue);
    });

    test('JSON round trip preserves required fields', () {
      final b = Boutique(
        id: 'id-123',
        name: 'Test Shop',
        createdAt: DateTime.parse('2026-01-01T00:00:00Z'),
        updatedAt: DateTime.parse('2026-01-02T00:00:00Z'),
      );
      final json = b.toJson();
      final restored = Boutique.fromJson(json);
      expect(restored.id, 'id-123');
      expect(restored.name, 'Test Shop');
      expect(restored.archivedAt, isNull);
    });
  });
}
