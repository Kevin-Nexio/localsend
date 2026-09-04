import 'package:localsend_app/model/persistence/favorite_device.dart';
import 'package:localsend_app/provider/favorites_provider.dart';
import 'package:mockito/mockito.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:test/test.dart';

import '../../mocks.mocks.dart';

void main() {
  late _QuickSendMockPersistenceService persistenceService;

  setUp(() {
    persistenceService = _QuickSendMockPersistenceService();
  });

  test('Should add a favorite device', () async {
    final service = ReduxNotifier.test(
      redux: FavoritesService(persistenceService),
    );

    expect(service.state, []);

    final device = _createDevice('1');

    await service.dispatchAsync(AddFavoriteAction(device));

    expect(service.state, [device]);
    verify(persistenceService.setFavorites([device]));
  });

  test('Should update a favorite device', () async {
    final initialDevice = _createDevice('1', alias: 'A');
    final service = ReduxNotifier.test(
      redux: FavoritesService(persistenceService),
      initialState: [initialDevice],
    );

    // Sanity check
    expect(service.state, [initialDevice]);
    expect(service.state.first.alias, 'A');

    final updatedDevice = _createDevice('1', alias: 'B');
    await service.dispatchAsync(UpdateFavoriteAction(updatedDevice));

    expect(service.state, [updatedDevice]);
    expect(service.state.first.alias, 'B');
    verify(persistenceService.setFavorites([updatedDevice]));
  });

  test('Should not update a favorite device if unknown id', () async {
    final initialDevice = _createDevice('1', alias: 'A');
    final service = ReduxNotifier.test(
      redux: FavoritesService(persistenceService),
      initialState: [initialDevice],
    );

    // Sanity check
    expect(service.state, [initialDevice]);
    expect(service.state.first.alias, 'A');

    final updatedDevice = _createDevice('2', alias: 'B');
    await service.dispatchAsync(UpdateFavoriteAction(updatedDevice));

    expect(service.state, [initialDevice]);
    expect(service.state.first.alias, 'A');
    verifyNever(persistenceService.setFavorites(any));
  });

  test('Should delete favorite device', () async {
    final initialDevice = _createDevice('1', fingerprint: '111');
    final service = ReduxNotifier.test(
      redux: FavoritesService(persistenceService),
      initialState: [initialDevice],
    );

    // Sanity check
    expect(service.state, [initialDevice]);

    await service.dispatchAsync(RemoveFavoriteAction(deviceFingerprint: '111'));

    expect(service.state, []);
    verify(persistenceService.setFavorites([]));
  });

  test('Should clear quick send target when deleting the selected favorite device', () async {
    final initialDevice = _createDevice('1', fingerprint: '111');
    final service = ReduxNotifier.test(
      redux: FavoritesService(persistenceService),
      initialState: [initialDevice],
    );
    persistenceService.quickSendFavorite = '1';

    await service.dispatchAsync(RemoveFavoriteAction(deviceFingerprint: '111'));

    expect(persistenceService.quickSendFavorite, null);
    verify(persistenceService.setFavorites([]));
  });

  test('Should set quick send target if favorite exists', () async {
    final initialDevice = _createDevice('1');
    final service = ReduxNotifier.test(
      redux: FavoritesService(persistenceService),
      initialState: [initialDevice],
    );

    await service.dispatchAsync(SetQuickSendFavoriteAction('1'));

    expect(persistenceService.quickSendFavorite, '1');
  });

  test('Should not delete favorite device if unknown fingerprint', () async {
    final initialDevice = _createDevice('1', fingerprint: '111');
    final service = ReduxNotifier.test(
      redux: FavoritesService(persistenceService),
      initialState: [initialDevice],
    );

    // Sanity check
    expect(service.state, [initialDevice]);

    await service.dispatchAsync(RemoveFavoriteAction(deviceFingerprint: '222'));

    expect(service.state, [initialDevice]);
    verifyNever(persistenceService.setFavorites(any));
  });
}

class _QuickSendMockPersistenceService extends MockPersistenceService {
  String? quickSendFavorite;

  @override
  String? getQuickSendFavorite() => quickSendFavorite;

  @override
  Future<void> setQuickSendFavorite(String? favoriteId) async {
    quickSendFavorite = favoriteId;
  }
}

FavoriteDevice _createDevice(
  String id, {
  String fingerprint = '123',
  String alias = 'A',
}) {
  return FavoriteDevice(
    id: id,
    fingerprint: fingerprint,
    ip: '1.2.3.4',
    port: 123,
    alias: alias,
  );
}
