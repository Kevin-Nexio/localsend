import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:localsend_app/model/cross_file.dart';
import 'package:localsend_app/pages/home_page.dart';
import 'package:localsend_app/pages/home_page_controller.dart';
import 'package:localsend_app/provider/favorites_provider.dart';
import 'package:localsend_app/provider/network/nearby_devices_provider.dart';
import 'package:localsend_app/provider/network/send_provider.dart';
import 'package:localsend_app/provider/persistence_provider.dart';
import 'package:localsend_app/provider/selection/selected_sending_files_provider.dart';
import 'package:localsend_app/util/native/file_picker.dart';
import 'package:localsend_app/util/native/tray_helper.dart';
import 'package:refena_flutter/refena_flutter.dart';

class SendToQuickTargetAction extends AsyncGlobalActionWithResult<bool> {
  final List<CrossFile> files;

  SendToQuickTargetAction(this.files);

  @override
  Future<bool> reduce() async {
    return sendToQuickTarget(ref: ref, files: files);
  }
}

Future<bool> sendToQuickTarget({required Ref ref, required List<CrossFile> files}) async {
  if (files.isEmpty) {
    return false;
  }

  final quickSendFavoriteId = ref.read(persistenceProvider).getQuickSendFavorite();
  if (quickSendFavoriteId == null) {
    return false;
  }

  final favorite = ref.read(favoritesProvider).firstWhereOrNull((favorite) => favorite.id == quickSendFavoriteId);
  if (favorite == null) {
    await ref.read(persistenceProvider).setQuickSendFavorite(null);
    return false;
  }

  final target = ref.read(nearbyDevicesProvider).allDevices[favorite.fingerprint];
  if (target?.ip == null) {
    return false;
  }

  await ref.notifier(sendProvider).startSession(target: target!, files: files, background: true);
  return true;
}

class SendClipboardToQuickTargetAction extends AsyncGlobalAction {
  final BuildContext context;

  SendClipboardToQuickTargetAction(this.context);

  @override
  Future<void> reduce() async {
    final previousCount = ref.read(selectedSendingFilesProvider).length;
    await dispatchAsync(
      PickFileAction(option: FilePickerOption.clipboard, context: context),
    );

    final selection = ref.read(selectedSendingFilesProvider);
    if (selection.length <= previousCount) {
      return;
    }

    final files = selection.sublist(previousCount);
    final sent = await sendToQuickTarget(ref: ref, files: files);
    if (!sent) {
      await showFromTray();
      ref.redux(homePageControllerProvider).dispatch(ChangeTabAction(HomeTab.send));
    }
  }
}
