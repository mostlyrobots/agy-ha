# Changelog

## 1.0.0

- Initial release of the Google Antigravity Home Assistant Add-on.
- Automated fetching of the latest `agy` binary from Google's release manifest with SHA-512 verification.
- Ingress web terminal powered by `ttyd`.
- Always-Turbo mode enforcement in global and workspace settings.
- Background supervision for `agy remote-control serve`.
- Complete supervisor and container access (Docker API, `/config`, `/share`, `/ssl`).
