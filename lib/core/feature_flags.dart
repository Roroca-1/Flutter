/// Experimental user-font support is kept in source, but omitted from normal
/// releases. Enable explicitly with `--dart-define=ENABLE_READER_FONTS=true`.
const bool enableReaderFonts = bool.fromEnvironment(
  'ENABLE_READER_FONTS',
  defaultValue: false,
);
