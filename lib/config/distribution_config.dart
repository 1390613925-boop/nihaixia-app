/// Build-time distribution switches. The ordinary release defaults to the
/// card-key gate; only app-unlocked-release.apk overrides it.
const licenseGateEnabled = bool.fromEnvironment(
  'LICENSE_GATE_ENABLED',
  defaultValue: true,
);
