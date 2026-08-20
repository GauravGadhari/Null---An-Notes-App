import 'package:flutter_test/flutter_test.dart';
import 'package:null_notes/widgets/null_selection_controls.dart';

void main() {
  test('NullTextSelectionControls instantiation test', () {
    final controls = NullTextSelectionControls();
    expect(controls, isNotNull);
  });
}
