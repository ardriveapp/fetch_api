part of 'readable_stream_source.dart';

ReadableStreamSource<T> createReadableStreamSourceFromStream<T>(
  Stream<T> stream, [
  bool handleBackPressure = false,
]) {
  if (handleBackPressure) {
    return _createReadableStreamSourceFromStreamWithBackPressure(stream);
  } else {
    return _createReadableStreamSourceFromStream(stream);
  }
}

/// Create [ReadableStreamSource] from Dart [Stream].
ReadableStreamSource<T> _createReadableStreamSourceFromStream<T>(
    Stream<T> stream) {
  late final StreamSubscription<T> subscription;
  return ReadableStreamSource(
    start: allowInterop((controller) {
      subscription = stream.listen(
        (event) {
          controller.enqueue(event);
        },
        onDone: () {
          controller.close();
        },
      );
    }),
    cancel: allowInterop(
      (reason) async => subscription.cancel(),
    ),
  );
}

// TODO: remove the print statements
// TODO: pass a callback to pass the progress update

/// Create [ReadableStreamSource] from Dart [Stream].
/// This version of the function is used for browsers that support backpressure.
ReadableStreamSource<T>
    _createReadableStreamSourceFromStreamWithBackPressure<T>(Stream<T> stream) {
  late final StreamSubscription<T> subscription;

  final readableStream = ReadableStreamSource<T>(
    start: allowInterop((controller) {
      var uploadedData = 0;

      subscription = stream.listen(
        (event) async {
          controller.enqueue(event);

          print(controller.desiredSize);

          if (controller.desiredSize < 0) {
            subscription.pause();

            while (true) {
              await Future.delayed(const Duration(milliseconds: 300), () {});
              if (controller.desiredSize > 0) {
                print('desiredSize > 0');
                print(controller.desiredSize);
                print('subscription.resume()');
                subscription.resume();
                break;
              }
            }
          }

          uploadedData += (event as List<int>).length;
          print('uploadedData: $uploadedData');
        },
        onDone: () {
          print(
              'onDone: uploadedData: $uploadedData, desiredSize: ${controller.desiredSize}');
          controller.close();
        },
      );
    }),
    cancel: allowInterop(
      (reason) async => subscription.cancel(),
    ),
  );

  return readableStream;
}
