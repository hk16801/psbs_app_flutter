import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:dio/dio.dart';

class CameraModal extends StatefulWidget {
  final String cameraId;
  final VoidCallback onClose;
  final bool open;

  const CameraModal({
    required this.cameraId,
    required this.onClose,
    this.open = true,
    Key? key,
  }) : super(key: key);

  @override
  _CameraModalState createState() => _CameraModalState();
}

class _CameraModalState extends State<CameraModal> {
  late VideoPlayerController _videoController;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  double _loadingProgress = 0;
  Timer? _retryTimer;
  int _retryCount = 0;
  final int _maxRetries = 30;

  @override
  void initState() {
    super.initState();
    if (widget.open) {
      _startStream();
    }
  }

  @override
  void didUpdateWidget(CameraModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.open != oldWidget.open) {
      if (widget.open) {
        _startStream();
      } else {
        _cleanUp();
      }
    }
  }

  Future<void> _startStream() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _loadingProgress = 0;
      _retryCount = 0;
    });

    try {
      // Start the stream on the server
      final response = await Dio().post(
        'http://10.0.2.2:5050/api/stream/start/${widget.cameraId}',
      );

      if (response.data['flag'] == true) {
        final streamUrl = response.data['data'];
        _initializeVideoPlayer(streamUrl);
      } else {
        setState(() {
          _hasError = true;
          _errorMessage = response.data['message'] ?? 'Failed to start stream';
          _isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to start stream';
        _isLoading = false;
      });
      print('Error starting stream: $error');
    }
  }

  void _initializeVideoPlayer(String streamUrl) async {
  // Extract the relative path from the response data
  String relativePath = streamUrl.replaceAll('http://localhost:5050', '');

  _videoController = VideoPlayerController.network('http://10.0.2.2:5050$relativePath')
    ..initialize().then((_) {
      setState(() {
        _isLoading = false;
      });
      _videoController.play();
    }).catchError((error) {
      _handleStreamError(error);
    });


    _videoController.addListener(() {
      if (_videoController.value.isBuffering) {
        setState(() {
          _loadingProgress = _videoController.value.buffered
              .map((range) => range.end.inMilliseconds.toDouble())
              .fold(0.0, (a, b) => a + b) /
              _videoController.value.duration.inMilliseconds.toDouble() *
              100;
        });
      }
    });
  }

  void _handleStreamError(dynamic error) {
    print('Stream error: $error');
    
    if (_retryCount < _maxRetries) {
      setState(() {
        _loadingProgress = (_retryCount / _maxRetries) * 100;
        _retryCount++;
      });

      _retryTimer = Timer(const Duration(seconds: 2), () {
        _videoController.initialize().then((_) {
          setState(() {
            _isLoading = false;
          });
          _videoController.play();
        }).catchError(_handleStreamError);
      });
    } else {
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to load stream after multiple attempts';
        _isLoading = false;
      });
    }
  }

  void _cleanUp() {
    _retryTimer?.cancel();
    _videoController.dispose();
    
    // Stop the stream on the server
    Dio().post('http://10.0.2.2:5050/api/stream/stop/${widget.cameraId}')
        .catchError((error) => print('Error stopping stream: $error'));
  }

  @override
  void dispose() {
    _cleanUp();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.open) return const SizedBox.shrink();

    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      backgroundColor: Colors.transparent,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 800),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.videocam,
                        color: Theme.of(context).primaryColor,
                        size: 28,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Live Camera Feed',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: widget.onClose,
                  ),
                ],
              ),
            ),
            
            const Divider(height: 1),
            
            // Video Player
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (!_isLoading && !_hasError)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: VideoPlayer(_videoController),
                    ),
                  
                  if (_isLoading)
                    Container(
                      color: Colors.black,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Starting stream...',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(color: Colors.white),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'This may take up to a minute',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: Colors.white70),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: 300,
                              child: LinearProgressIndicator(
                                value: _loadingProgress / 100,
                                backgroundColor: Colors.grey[800],
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.blue),
                                minHeight: 8,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Initializing camera feed (${_loadingProgress.toStringAsFixed(0)}%)',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.white54),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Error message
            if (_hasError)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Theme.of(context).colorScheme.error),
                      ),
                    ),
                  ],
                ),
              ),
            
            const Divider(height: 1),
            
            // Footer
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!_isLoading && !_hasError)
                    IconButton(
                      icon: Icon(
                        _videoController.value.isPlaying
                            ? Icons.pause
                            : Icons.play_arrow,
                      ),
                      onPressed: () {
                        setState(() {
                          if (_videoController.value.isPlaying) {
                            _videoController.pause();
                          } else {
                            _videoController.play();
                          }
                        });
                      },
                    ),
                  if (_hasError)
                    TextButton(
                      onPressed: _startStream,
                      child: const Text('Retry'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}