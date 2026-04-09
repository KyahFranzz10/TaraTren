// future_train_lines.dart — Master barrel file
// Combines all future rail line data into a single list.
// To edit a specific line's stations, open the corresponding file:
//   • MRT-7                → lib/data/future_lines/mrt7_line.dart
//   • Metro Manila Subway  → lib/data/future_lines/mms_line.dart
//   • NSCR                 → lib/data/future_lines/nscr_line.dart
// To edit models (FutureStation, FutureLine):
//   • lib/data/future_lines/future_line_models.dart

export 'future_lines/future_line_models.dart';
export 'future_lines/mrt7_line.dart';
export 'future_lines/mms_line.dart';
export 'future_lines/nscr_line.dart';
export 'future_lines/mrt4_line.dart';

import 'future_lines/future_line_models.dart';
import 'future_lines/mrt7_line.dart';
import 'future_lines/mms_line.dart';
import 'future_lines/nscr_line.dart';
import 'future_lines/mrt4_line.dart';

final List<FutureLine> futureLines = [
  mrt7Line,
  mmsLine,
  nscrLine,
  mrt4Line,
];
