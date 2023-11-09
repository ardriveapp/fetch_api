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
  Timer? backpressureTimer;

  final readableStream = ReadableStreamSource<T>(
    start: allowInterop((controller) {
      subscription = stream.listen(
        (event) {
          controller.enqueue(event);

          if (controller.desiredSize < 0 && backpressureTimer == null) {
            subscription.pause();

            backpressureTimer =
                Timer.periodic(const Duration(milliseconds: 300), (timer) {
              if (controller.desiredSize > 0) {
                subscription.resume();
                backpressureTimer?.cancel();
                backpressureTimer = null;
              }
            });
          }
        },
        onDone: () {
          backpressureTimer?.cancel();
          controller.close();
        },
        onError: (error) {
          backpressureTimer?.cancel();
          controller.error(error);
          subscription.cancel();
        },
      );
    }),
    cancel: allowInterop(
      (reason) async {
        backpressureTimer?.cancel();
        await subscription.cancel();
      },
    ),
  );

  return readableStream;
}
