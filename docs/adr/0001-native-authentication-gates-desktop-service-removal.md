# ADR-0001: Native authentication gates Desktop Service removal

- **Status**: pointer. The canonical text lives in the atlas spec, and its status
  there governs. This file lets a session that starts in this repo find it.
- **Canonical ADR**:
  [`atlas/specs/2026-10-sketchup-native-authentication/adr/0001-native-authentication-gates-desktop-service-removal.md`](../../../atlas/specs/2026-10-sketchup-native-authentication/adr/0001-native-authentication-gates-desktop-service-removal.md)
- **Spec**:
  [`atlas/specs/2026-10-sketchup-native-authentication/spec.md`](../../../atlas/specs/2026-10-sketchup-native-authentication/spec.md)
- **Repos affected**: speckle-sketchup, connector-installers, speckle-connectors-dui, speckle-docs-NEW

## Decision (summary; the atlas ADR is authoritative)

New SketchUp releases sign in through the system browser. They do not use
Desktop Service. The connector exposes `authenticateAccount` on its accounts
binding and uses the server's `connectrV3` app with the registered
`http://localhost:29355` callback. It supports the modern and older token
endpoints in the same way as the .NET and Archicad connectors, and saves the
account in the existing shape before it answers. Public server 2.31.0 is the
minimum for this flow. The DUI's existing capability check selects native sign-in
and hides Log in (Legacy). Installers drop Desktop Service only together with a
connector that passes these checks.

## What this binds in this repo

- `speckle_connector_3/src/ui/bindings/accounts_binding.rb`: `authenticateAccount`
  is the DUI's capability signal. `getAccounts`, `addAccount` and `removeAccount`
  keep their contracts. `addAccount` stays because the DUI's Log in button needs it.
- `speckle_connector_3/src/commands/authenticate_account_command.rb`: answers each
  request once, with the saved account or a host-app error.
- `speckle_connector_3/src/auth/`: `connectrV3`, callback port 29355, S256 PKCE with
  a fallback to the older plain challenge, a five-minute wait, and no Desktop
  Service calls.
