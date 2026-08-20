/// Represents the visual & functional lifecycle state of the Editor screen.
enum EditorState {
  /// Circle is centered with nothing else on screen. Pure zen void.
  sleep,

  /// Circle smoothly animates to the bottom and editor elements fade in.
  awake,

  /// Full interactive editing mode (defined in next steps).
  active,
}
