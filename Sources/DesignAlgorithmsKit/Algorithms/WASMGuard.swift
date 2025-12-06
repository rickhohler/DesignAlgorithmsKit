#if !os(WASI) && !arch(wasm32)
// Hash and crypto types are not available in WASM builds
// These types use NSLock which is not available in WASM runtime
#error("This file should not be compiled for WASM. Exclude from target.")
#endif
