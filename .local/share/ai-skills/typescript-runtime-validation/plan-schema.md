# Eval-plan schema reference

The eval plan is a JSON file at `<packageDirectory>/.tsupgrader/runtime-validation/eval-plan.json`. The runtime-validation tool loads it and runs `setup[]` then each entry in `assertions[]`.

## Top-level fields

```jsonc
{
  "generatedAt": "2026-05-18T15:30:00Z",        // ISO 8601. Informational.
  "generatedOnPlatform": "win32",                // "win32" | "darwin" | "linux". Informational.
  "projectType": "webapp",                       // Required. See list below.
  "devServer": { /* DevServerSpec */ },          // Optional. Required-ish for plans with playwright-route or http-probe.
  "setup":   [ /* SetupCommand[] */ ],           // Optional. Empty array allowed.
  "assertions": [ /* EvalAssertion[] */ ]        // Required. At least one entry.
}
```

`projectType` must be one of: `webapp`, `server`, `cli`, `electron`, `library`, `framework`, `plugin`, `other`.

## `devServer` — DevServerSpec

A single dev-server process the runtime-validation tool spawns BEFORE running assertions and kills (process tree) AFTER the run, including on assertion failure. Use this for any plan whose `playwright-route` assertions depend on a running webapp. The runner waits for `url` to respond before starting assertions; assertions are auto-failed with an explanatory reason if the server never becomes ready.

The runner owns this server's full lifecycle. Do not run your own dev server on the same `url` during validation — if a separate recording-phase server (see [recording.md](./recording.md)) is still listening on that URL, the runner validates against the stale server and leaves it orphaned. Stop any workflow-owned recording server before calling `typescript_validate_runtime`.

```jsonc
{
  "command": "npm",                  // Required. Executable name or absolute path.
  "args": ["run", "dev"],            // Optional. List of string args.
  "cwd": "client",                    // Optional. Relative to packageDirectory, or absolute.
  "env": { "NODE_ENV": "test" },      // Optional. Merged over the inherited environment.
  "prependPath": ["tools/node/bin"],  // Optional. Prepended using the platform PATH separator.
  "url": "http://localhost:5173",    // Required. Polled for 2xx/3xx before assertions run.
  "readyTimeoutSeconds": 120         // Optional. Default 120s.
}
```

Only one `devServer` block per plan. Each `playwright-route` assertion implicitly relies on it — the tool does NOT additionally start a server per assertion.

## `setup[]` — SetupCommand

Sequential commands that prepare the project to run the assertions. Prefer a
lockfile-preserving install such as `npm ci` (or the project's equivalent).
Without an npm lockfile, use `npm install --no-package-lock`. Never let runtime
validation setup create or rewrite a project lockfile. Each command is invoked
via direct spawn (no shell), with the package directory as CWD.

```jsonc
{
  "command": "npm",                // Required. Executable name or absolute path.
  "args": ["ci"],                  // Optional. List of string args.
  "cwd": "client",                 // Optional. Relative to packageDirectory, or absolute.
  "env": { "NODE_ENV": "test" },   // Optional. Merged over the inherited environment.
  "prependPath": ["tools/node"],   // Optional. Prepended using the platform PATH separator.
  "timeoutSeconds": 600            // Optional. Default 600s (10 minutes) per setup step.
}
```

Setup failures are fatal — if any step's exit code is nonzero, the run aborts and no assertions execute. Keep `setup[]` minimal: anything that takes longer than installing dependencies probably belongs in an assertion (so its result is comparable across runs).

## `assertions[]` — EvalAssertion

### Common fields (every assertion)

```jsonc
{
  "name": "tsc-no-emit",                 // Required. Unique within the plan. Stable across runs.
  "kind": "process",                     // Required. "process" | "http-probe" | "playwright-route".
  "verificationMethod": "exit-code",     // Required. "exit-code" | "output-contains" | "http-status" | "test-results".
  "expected": "0",                       // Required. Always a string.
  "cwd": "client",                       // Optional for process/http-probe.
  "env": { "CHROME_BIN": "tools/chrome" }, // Optional for process/http-probe.
  "prependPath": ["node_modules/.bin"],  // Optional for process/http-probe.
  "timeoutSeconds": 60                   // Optional. Default 60s.
}
```

### Structured execution context

`setup[]`, `devServer`, `process`, and `http-probe` commands support the same optional execution fields:

- `cwd`: Relative paths resolve beneath `packageDirectory`; absolute paths remain absolute. Relative paths that escape `packageDirectory` are rejected.
- `env`: String-valued overrides merged into the inherited process environment. It does not replace inherited variables.
- `prependPath`: Directory entries prepended to the effective `PATH` with the current platform's path separator. Relative entries resolve beneath `packageDirectory`. If `env.PATH` is present, it is the base PATH that receives these entries.

The runner still spawns `command`/`startCommand` directly with the argument array. Do not wrap ordinary commands in `cmd.exe /c`, PowerShell, or `sh -c` to set environment variables or change directories. Use an absolute `command` when selecting a specific Node executable; paths and arguments containing spaces require no manual quoting.

Every result artifact records each plan execution's resolved executable, argument array, resolved cwd, explicit environment overrides, prepended PATH entries, and runtime platform. Environment values whose names look credential-bearing (for example `TOKEN`, `PASSWORD`, `SECRET`, `API_KEY`, or `CONNECTION_STRING`) are stored as `<redacted>`.

`name` is the diff key when comparing two runs — keep it descriptive and stable.

`expected` is always a string: stringified integer for `exit-code` (`"0"`), stringified status code for `http-status` (`"200"`), literal substring for `output-contains` (see [output-contains.md](./output-contains.md)).

### Kind-specific fields

| `kind` | Required fields | Forbidden fields |
|---|---|---|
| `process` | `command`, optional `args`, `cwd`, `env`, `prependPath` | `startCommand`, `startArgs`, `url`, `scriptPath` |
| `http-probe` | `startCommand`, optional `startArgs`, `cwd`, `env`, `prependPath`, `url` | `command`, `args`, `scriptPath` |
| `playwright-route` | exactly one of `url` or `scriptPath` | `command`, `startCommand`, `cwd`, `env`, `prependPath` |

`http-probe` polls `url` until it responds, then validates the response and kills the process. `playwright-route` with `scriptPath` replays a Playwright `.spec.ts`; `url`-only mode is reserved for a future "navigate-and-snapshot" path and is not yet implemented.

### Verification-method × kind matrix

| | `exit-code` | `output-contains` | `http-status` | `test-results` |
|---|---|---|---|---|
| `process` | ✅ exit code | ✅ stdout+stderr substring | ❌ | ✅ exit code 0; parsed test counts attached to result |
| `http-probe` | ❌ | ✅ response body substring | ✅ HTTP status | ❌ |
| `playwright-route` | ✅ exit code of `playwright test` | ❌ | ❌ | ❌ |

`test-results` is a specialization of `exit-code` for the `tests-pass` assertion: same pass criterion (exit code 0), but the runner additionally parses the test framework's output and persists `testsTotal / testsPassed / testsFailed / testsSkipped / testFramework` on the assertion result so baseline vs. post-upgrade comparisons can show the count diff. `expected` must be `"0"`. See [tests-assertion.md](./tests-assertion.md).

## Naming

- kebab-case: `tsc-no-emit`, `cli-help-banner`, `health-endpoint-200`.
- Unique within `assertions[]`.
- No version numbers, dates, or environment markers — those drift; the comparison report uses `name` as the join key.

## Timeouts

- Assertion default: 60s.
- Setup default: 600s (`npm ci` on cold cache).

## Minimal valid plan

```jsonc
{
  "projectType": "library",
  "setup":   [ { "command": "npm", "args": ["ci"] } ],
  "assertions": [
    {
      "name": "tsc-builds",
      "kind": "process",
      "command": "npx",
      "args": ["tsc", "--noEmit"],
      "verificationMethod": "exit-code",
      "expected": "0"
    }
  ]
}
```

See [per-project-type.md](./per-project-type.md) for type-specific templates.
