# Swift ↔ Kotlin Transpilation Rules — FoodShare

*Applied rules to ensure zero-cross-platform bugs between iOS (SwiftUI) and Android (Jetpack Compose) code domains.*

---

## 🔢 Integer Overflow

| Scenario | Swift | Kotlin | Rule |
|---|---|---|---|
| `Int` + `Int` addition may overflow | ✅ Safe (Swift `Int` is 64-bit on 64-bit platforms) | ✅ Safe (`Int` is 64-bit on 64-bit) | **Match** — no special handling needed |
| `UInt` multiplication | ✅ Safe with `&-+` operators | ⚠️ Use `long` or `BigInteger` for large values | **Convert** — use `Int64` explicitly for cross-platform math |
| `Double` == `Int` comparison ⚠️ | **CRITICAL** — Avoid `Double == Int` at compile time | ✅ Kotlin handles `Double`/`Int` comparison | **Rewrite** — use `Double(value) == target` or `abs(a-b) < epsilon` |

---

## ⚠️ Double vs Int Pitfalls

| Anti-Pattern | Swift | Kotlin | Fix |
|---|---|---|---|
| `Double.sqrt()` without Foundation import | ❌ Compile error | ✅ Available via `Foundation` | **Bridge** — use `Foundation.sqrt()` or `sqrt()` from `Darwin` |
| `String.append(Character)` | ❌ deprecated in Swift 5.7 | ✅ `str += char` | **Update** — use `str.append(character)` or `str += "c"` |
| `Array.remove(atOffsets:)` SwiftUI-only | ❌ SwiftUI gotcha | ✅ `array.removeAll(where:)` | **Replace** — use `removeAll(where:)` or `filter` |
| `Double(describing: integer)` | ❌ loses precision | ✅ `String(integer)` | **Fix** — use `String(integer)` directly |
| `Double` literal comparison with `Int` | ❌ compile error in transpiled code | ✅ native Kotlin | **Guard** — `@inline(__always)` annotated wrappers |

---

## `weak`/`unowned` GC Effects

| Reference Type | Swift ARC | Kotlin GC | Rule |
|---|---|---|---|
| `weak var` | ✅ ARC weak reference | ❌ Not directly supported | **Map** — use `UnownedReference` or refactor ownership |
| `unowned var` | ✅ ARC unowned reference | ❌ Not directly supported | **Map** — ensure owner outlives dependent, or use `weak` pattern |
| Closure capture `self` strongly | ❌ Memory risk in GC | ✅ ARC handles this | **Audit** — verify no retain cycles in transpiled code |
| `deinit` becomes `finalize()` | ❌ Non-deterministic | ✅ GC finalizer runs later | **Note** — don't rely on deinit side effects |

---

## 📦 Variadic Init Issues

| Pattern | Swift | Kotlin | Fix |
|---|---|---|---|
| `Array(repeating:count:)` | ✅ Native | ✅ Native | **Match** |
| `Dictionary(minimumCapacity:)` | ✅ Native | ⚠️ Use `HashMap(initialCapacity:)` | **Map** — Kotlin uses `HashMap` |
| Custom variadic `init` | ⚠️ Limited to 3 params | ✅ Kotlin varargs | **Conditional** — limit variadic params or use `listOf()` |

---

## 🌉 Bridge Directives (`@bridge`)

Use `#if SKIP` / `#if !SKIP` directives to guard platform-specific code:

```swift
#if SKIP
// Kotlin/Jetpack Compose equivalent
import skip-ui
#else
// iOS/SwiftUI equivalent
import SwiftUI
#endif
```

---

## 📋 Checklist — Run Before Cross-Platform Build

- [ ] No `Double == Int` comparisons without explicit cast
- [ ] No `Array.remove(atOffsets:)` — use `removeAll(where:)` instead
- [ ] No `String.append(Character)` — use `str += "c"` or `str.append("c")`
- [ ] `weak`/`unowned` references have verified owner lifetime
- [ ] All `#if SKIP` / `#if !SKIP` blocks have both branches maintained
- [ ] `Double.sqrt()` calls use `Foundation.sqrt()` or platform guard
- [ ] Integer literals that cross platforms use `Int64()` or `Int()` explicitly