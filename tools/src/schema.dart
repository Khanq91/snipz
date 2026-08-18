// Allowed frontmatter values (spec §5.2, §0.3). validate.dart check #6/#9.

const List<String> kinds = ['paint', 'carrier', 'effect', 'composite'];
const List<String> paintSources = ['shader', 'painter', 'widget', 'none'];
const List<String> carrierNames = [
  'fullscreen',
  'card',
  'button',
  'text',
  'border',
  'icon',
  'divider',
];
const List<String> portabilities = [
  'single_file',
  'folder',
  'folder_with_assets',
];

/// `stale` is intentionally NOT here — it is computed at runtime from
/// last_verified (decision #5). validate fails hard on it.
const List<String> statuses = ['verified', 'needs_patch', 'broken'];
const List<String> origins = ['original', 'reimplemented', 'adapted', 'copied'];
const List<String> verifyResults = [
  'pass',
  'pass_warning',
  'needs_patch',
  'fail',
];

final RegExp dateRe = RegExp(r'^\d{4}-\d{2}-\d{2}$');
final RegExp semverRe = RegExp(r'^\d+\.\d+\.\d+$');
final RegExp idRe = RegExp(r'^[a-z][a-z0-9_]*$');
