

enum UploadStatus {
  idle,
  uploading,
  completed,
  error,
}

class UploadState {
  final UploadStatus status;
  final double progress;
  final String? fileName;
  final String? errorMessage;

  UploadState({
    this.status = UploadStatus.idle,
    this.progress = 0.0,
    this.fileName,
    this.errorMessage,
  });

  UploadState copyWith({
    UploadStatus? status,
    double? progress,
    String? fileName,
    String? errorMessage,
  }) {
    return UploadState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      fileName: fileName ?? this.fileName,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}