import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:paulonia_cache_image/paulonia_cache_image.dart';
import 'package:paulonia_cache_image/paulonia_cache_image_mobile.dart'
if (dart.library.html) 'package:paulonia_cache_image/paulonia_cache_image_web.dart';

import 'constants.dart';

class InMemoryManager {
  /// Stores the images in memory
  static HashMap<String, ImageStreamCompleter> _manager = HashMap();
  static HashMap<String, ImageStreamCompleterHandle> _managerHandles =
  HashMap();
  static late List<String> _savedImages;
  static List<String> get savedImages => _savedImages;
  static late int _maxInMemoryImages;
  static int get maxInMemoryImages => _maxInMemoryImages;

  /// Initialize the the In-memory manager
  static void init(
      {int maxInMemoryImages = Constants.INFINITE_IN_MEMORY_IMAGES}) {
    _maxInMemoryImages = maxInMemoryImages;
    _savedImages = [];
  }

  /// Get the image
  ///
  /// Verifies if the image is in memory cache and returns it. Otherwise it calls
  /// [getImage()] from the service of the platform.
  static ImageStreamCompleter getImage(PCacheImage key,
      {bool clearMemoryImg = false}) {
    // remove token stuff
    final String keyUrl = key.url.split('?').first;

    if (clearMemoryImg) {
      _manager.remove(keyUrl);
      _managerHandles[keyUrl]?.dispose();
      _managerHandles.remove(keyUrl);
      _savedImages.remove(keyUrl);
    }
    if (_manager.containsKey(keyUrl)) return _manager[keyUrl]!;
    ImageStreamCompleter res = MultiFrameImageStreamCompleter(
      codec: PCacheImageService.getImage(
        key.url,
        key.retryDuration!,
        key.maxRetryDuration!,
        key.enableCache!,
      ),
      scale: key.imageScale!,
    );
    if (_maxInMemoryImages != Constants.INFINITE_IN_MEMORY_IMAGES &&
        _savedImages.length == _maxInMemoryImages) {
      String removedUrl = _savedImages.removeAt(0);
      _manager.remove(removedUrl);
      _managerHandles[removedUrl]?.dispose();
      _managerHandles.remove(removedUrl);
    }
    _savedImages.add(keyUrl);
    _manager[keyUrl] = res;
    _managerHandles[keyUrl] = res.keepAlive();
    return res;
  }

  /// Clears all the cached images
  static Future<void> clearAllImages() async {
    _savedImages.clear();
    _manager.clear();
    _managerHandles.forEach((key, value) {
      _managerHandles[key]?.dispose();
    });
    _managerHandles.clear();
  }

  /// Get the number of saved images in memory
  static int get length => _savedImages.length;
}
