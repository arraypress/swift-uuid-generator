# Swift UUID Generator

A modern Swift package for generating, parsing, and reformatting UUIDs with extensive formatting options. Built on Foundation's cryptographically secure `UUID`, it adds seven output formats, batch generation, validation, and flexible parsing — ideal for unique identifiers, session tokens, and any system with specific UUID formatting needs.

## Features

- 🔐 **Secure generation** — Uses Foundation's `UUID` (128 bits of entropy) for cryptographically secure v4 UUIDs.
- 🎯 **Sensible defaults** — `generate()` returns a standard uppercase, dashed UUID.
- 🎨 **Seven formats** — Standard, lowercase, uppercase, no-dashes, no-dashes lowercase, bracketed, and URN.
- 📦 **Batch generation** — `generateMultiple` produces 1–10,000 UUIDs in one call.
- 🔄 **Parse and reformat** — `generate(from:format:)` accepts existing UUIDs (with or without dashes, bracketed, or URN) and re-emits them in any format.
- ✅ **Validation** — `isValid(_:)` checks for canonical UUID strings.
- ℹ️ **Generator metadata** — `generatorInfo()` reports supported versions, formats, and entropy.
- 🧩 **Flexible normalization** — Strips brackets and URN prefixes and reinserts dashes for 32-character hex input.
- 🛡️ **Safe bounds** — Batch counts are automatically clamped.
- 🧱 **Zero dependencies** — Pure Foundation.

## Requirements

- iOS 13.0+ / macOS 10.15+ / tvOS 13.0+ / watchOS 6.0+
- Swift 6.1+
- Xcode 16.0+

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/arraypress/swift-uuid-generator.git", from: "1.0.0")
]
```

## Usage

### Quick start

```swift
import UUIDGenerator

let uuid = UUIDGenerator.generate()
// "550E8400-E29B-41D4-A716-446655440000"
```

### Custom formats

```swift
import UUIDGenerator

UUIDGenerator.generate(version: .v4, format: .lowercase)
// "550e8400-e29b-41d4-a716-446655440000"

UUIDGenerator.generate(format: .noDashes)
// "550E8400E29B41D4A716446655440000"

UUIDGenerator.generate(format: .bracketed)
// "{550E8400-E29B-41D4-A716-446655440000}"

UUIDGenerator.generate(format: .urn)
// "urn:uuid:550e8400-e29b-41d4-a716-446655440000"
```

### Batch generation

```swift
import UUIDGenerator

let uuids = UUIDGenerator.generateMultiple(count: 5)

let compact = UUIDGenerator.generateMultiple(
    count: 3,
    version: .v4,
    format: .noDashes
)
```

### Parsing and reformatting

```swift
import UUIDGenerator

let reformatted = UUIDGenerator.generate(
    from: "550E8400-E29B-41D4-A716-446655440000",
    format: .noDashes
)
// "550E8400E29B41D4A716446655440000"

// Returns nil for invalid input
let invalid = UUIDGenerator.generate(from: "not-a-uuid")  // nil
```

### Validation and info

```swift
import UUIDGenerator

UUIDGenerator.isValid("550E8400-E29B-41D4-A716-446655440000")  // true

let info = UUIDGenerator.generatorInfo()
print(info.entropyBits)           // 128
print(info.supportedFormats.count)
```

## Models

| Type | Description |
|------|-------------|
| `UUIDVersion` | `.v4` (random) and `.v1` (time-based); each with `description` and `isRandom`. |
| `UUIDFormat` | `.standard`, `.lowercase`, `.uppercase`, `.noDashes`, `.noDashesLowercase`, `.bracketed`, `.urn`; each exposes an `example`. |
| `UUIDGeneratorInfo` | Supported versions, supported formats, `entropyBits`, and a `description`. |

## How It Works

Generation delegates to Foundation's `UUID`, which produces cryptographically secure version-4 UUIDs. The chosen `UUIDFormat` then transforms the canonical string — adjusting case, stripping dashes, or wrapping it in braces or a `urn:uuid:` prefix. When parsing existing values, the input is normalized first: brackets and URN prefixes are removed and 32-character hex strings have dashes reinserted at the 8-4-4-4-12 boundaries before being validated.

> **Note:** Foundation only provides version-4 UUIDs, so requesting `.v1` still yields a v4 UUID.

## Testing

```bash
swift test
```

The test suite covers default and custom generation, all formats, batch generation, parsing/reformatting, and validation.

## License

MIT License — see LICENSE file for details.

## Author

Created by David Sherlock ([ArrayPress](https://github.com/arraypress)) in 2026.
