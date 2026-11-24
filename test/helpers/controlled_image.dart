import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

class ControlledImage extends ImageProvider<ControlledImage> {
  ControlledImage(this.result);

  final Future<ImageInfo> result;

  @override
  Future<ControlledImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    ControlledImage key,
    ImageDecoderCallback decode,
  ) => OneFrameImageStreamCompleter(result);
}
