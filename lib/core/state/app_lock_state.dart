enum AppLockState {
  /// App is in its initial unconfigured state (no PIN saved)
  setupRequired,

  /// PIN is stored securely, access is locked
  locked,

  /// Recovery process started, waiting for delay
  recoveryPending,

  /// Delay completed, ready for challenge
  challengeReady,

  /// Challenge completed, ready to reveal PIN
  revealReady,

  /// PIN is revealed (temporary state)
  pinRevealed,

  /// Backward clock manipulation detected
  timeAnomalyDetected,
}
