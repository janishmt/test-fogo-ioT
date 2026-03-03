import 'package:flutter_test/flutter_test.dart';
import 'package:fogo/data/models/connection_status.dart';

void main() {
  group('StatusRules.compute —', () {
    group('Unknown', () {
      test('jamais répondu → Unknown', () {
        expect(
          StatusRules.compute(
            successiveFailures: 0,
            lastResponseMs: null,
            hasEverResponded: false,
          ),
          ConnectionStatus.unknown,
        );
      });

      test('jamais répondu même avec des échecs → Unknown', () {
        expect(
          StatusRules.compute(
            successiveFailures: 5,
            lastResponseMs: null,
            hasEverResponded: false,
          ),
          ConnectionStatus.unknown,
        );
      });
    });

    group('Online', () {
      test('0 échec et latence faible → Online', () {
        expect(
          StatusRules.compute(
            successiveFailures: 0,
            lastResponseMs: 100,
            hasEverResponded: true,
          ),
          ConnectionStatus.online,
        );
      });

      test('0 échec et latence juste sous le seuil (1999 ms) → Online', () {
        expect(
          StatusRules.compute(
            successiveFailures: 0,
            lastResponseMs: 1999,
            hasEverResponded: true,
          ),
          ConnectionStatus.online,
        );
      });

      test('0 échec et lastResponseMs null → Online', () {
        expect(
          StatusRules.compute(
            successiveFailures: 0,
            lastResponseMs: null,
            hasEverResponded: true,
          ),
          ConnectionStatus.online,
        );
      });
    });

    group('Degraded', () {
      test('0 échec mais latence ≥ 2000 ms → Degraded', () {
        expect(
          StatusRules.compute(
            successiveFailures: 0,
            lastResponseMs: 2000,
            hasEverResponded: true,
          ),
          ConnectionStatus.degraded,
        );
      });

      test('0 échec et latence très élevée (5000 ms) → Degraded', () {
        expect(
          StatusRules.compute(
            successiveFailures: 0,
            lastResponseMs: 5000,
            hasEverResponded: true,
          ),
          ConnectionStatus.degraded,
        );
      });

      test('1 échec consécutif → Degraded', () {
        expect(
          StatusRules.compute(
            successiveFailures: 1,
            lastResponseMs: 100,
            hasEverResponded: true,
          ),
          ConnectionStatus.degraded,
        );
      });

      test('2 échecs consécutifs → Degraded', () {
        expect(
          StatusRules.compute(
            successiveFailures: 2,
            lastResponseMs: null,
            hasEverResponded: true,
          ),
          ConnectionStatus.degraded,
        );
      });
    });

    group('Offline', () {
      test('3 échecs consécutifs → Offline', () {
        expect(
          StatusRules.compute(
            successiveFailures: 3,
            lastResponseMs: null,
            hasEverResponded: true,
          ),
          ConnectionStatus.offline,
        );
      });

      test('5 échecs consécutifs → Offline', () {
        expect(
          StatusRules.compute(
            successiveFailures: 5,
            lastResponseMs: null,
            hasEverResponded: true,
          ),
          ConnectionStatus.offline,
        );
      });
    });
  });

  group('StatusRules.computeScore —', () {
    test('0 échec, latence ≤ 500 ms → score 100', () {
      expect(
        StatusRules.computeScore(successiveFailures: 0, lastResponseMs: 500),
        100,
      );
    });

    test('0 échec, latence nulle → score 100', () {
      expect(
        StatusRules.computeScore(successiveFailures: 0, lastResponseMs: null),
        100,
      );
    });

    test('0 échec, latence 50 ms (sous seuil 500 ms) → score 100', () {
      expect(
        StatusRules.computeScore(successiveFailures: 0, lastResponseMs: 50),
        100,
      );
    });

    test('0 échec, latence 1500 ms → score 80', () {
      // latencyPenalty = clamp((1500-500)/50, 0, 40) = clamp(20, 0, 40) = 20
      // score = 100 - 0 - 20 = 80
      expect(
        StatusRules.computeScore(successiveFailures: 0, lastResponseMs: 1500),
        80,
      );
    });

    test('0 échec, latence 2500 ms → score 60', () {
      // latencyPenalty = clamp((2500-500)/50, 0, 40) = clamp(40, 0, 40) = 40
      // score = 100 - 0 - 40 = 60
      expect(
        StatusRules.computeScore(successiveFailures: 0, lastResponseMs: 2500),
        60,
      );
    });

    test('latencyPenalty plafonné à 40 (latence très haute) → score 60 min sans échec', () {
      expect(
        StatusRules.computeScore(successiveFailures: 0, lastResponseMs: 99999),
        60,
      );
    });

    test('1 échec, latence rapide → score 70', () {
      // failurePenalty = 1 * 30 = 30, latencyPenalty = 0
      // score = 100 - 30 - 0 = 70
      expect(
        StatusRules.computeScore(successiveFailures: 1, lastResponseMs: 100),
        70,
      );
    });

    test('2 échecs, latence rapide → score 40', () {
      // failurePenalty = 2 * 30 = 60, latencyPenalty = 0
      // score = 100 - 60 - 0 = 40
      expect(
        StatusRules.computeScore(successiveFailures: 2, lastResponseMs: 100),
        40,
      );
    });

    test('≥ 3 échecs → score 0 (Offline)', () {
      expect(
        StatusRules.computeScore(successiveFailures: 3, lastResponseMs: null),
        0,
      );
    });

    test('≥ 3 échecs → score 0 même avec bonne latence', () {
      expect(
        StatusRules.computeScore(successiveFailures: 3, lastResponseMs: 10),
        0,
      );
    });

    test('score jamais négatif même en cas extrême', () {
      expect(
        StatusRules.computeScore(successiveFailures: 2, lastResponseMs: 99999),
        greaterThanOrEqualTo(0),
      );
    });

    test('score jamais supérieur à 100', () {
      expect(
        StatusRules.computeScore(successiveFailures: 0, lastResponseMs: 0),
        lessThanOrEqualTo(100),
      );
    });
  });
}
