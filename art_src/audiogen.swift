import Foundation

// Synthesises every sound Cindrune ships. Mono 44.1 kHz, 16-bit WAV.
// Usage: audiogen <output-directory>

let outDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."
let SR = 44_100.0

// MARK: - RNG

var rs: UInt64 = 0x243F6A8885A308D3
func seedAudio(_ v: UInt64) { rs = v | 1 }
func urand() -> Double {
    rs ^= rs << 13; rs ^= rs >> 7; rs ^= rs << 17
    return Double(rs % 2_000_001) / 1_000_000.0 - 1.0
}

// MARK: - WAV writer

func writeWAV(_ samples: [Double], _ name: String) {
    var peak = 0.0
    for s in samples { peak = max(peak, abs(s)) }
    let norm = peak > 0.0001 ? 0.92 / peak : 1.0

    var data = Data()
    func le32(_ v: UInt32) { withUnsafeBytes(of: v.littleEndian) { data.append(contentsOf: $0) } }
    func le16(_ v: UInt16) { withUnsafeBytes(of: v.littleEndian) { data.append(contentsOf: $0) } }

    let byteCount = UInt32(samples.count * 2)
    data.append(contentsOf: Array("RIFF".utf8)); le32(36 + byteCount)
    data.append(contentsOf: Array("WAVE".utf8))
    data.append(contentsOf: Array("fmt ".utf8)); le32(16)
    le16(1); le16(1); le32(UInt32(SR)); le32(UInt32(SR) * 2); le16(2); le16(16)
    data.append(contentsOf: Array("data".utf8)); le32(byteCount)
    for s in samples {
        let v = max(-1.0, min(1.0, s * norm))
        le16(UInt16(bitPattern: Int16(v * 32_600)))
    }
    let url = URL(fileURLWithPath: outDir).appendingPathComponent("\(name).wav")
    try? data.write(to: url)
    print("wrote \(name).wav  \(samples.count) frames")
}

// MARK: - Building blocks

func env(_ i: Int, _ n: Int, attack: Double, decay: Double, curve: Double = 2.4) -> Double {
    let t = Double(i) / SR
    let total = Double(n) / SR
    if t < attack { return t / max(0.0001, attack) }
    let d = (t - attack) / max(0.0001, decay)
    let e = exp(-d * curve)
    // Fade the very tail so loops and one-shots never click.
    let tail = min(1.0, (total - t) / 0.01)
    return e * max(0, tail)
}

/// One-pole low-pass.
func lowpass(_ input: [Double], cutoff: Double) -> [Double] {
    let dt = 1.0 / SR
    let rc = 1.0 / (2 * Double.pi * cutoff)
    let a = dt / (rc + dt)
    var out = [Double](repeating: 0, count: input.count)
    var prev = 0.0
    for i in input.indices {
        prev += a * (input[i] - prev)
        out[i] = prev
    }
    return out
}

func highpass(_ input: [Double], cutoff: Double) -> [Double] {
    let dt = 1.0 / SR
    let rc = 1.0 / (2 * Double.pi * cutoff)
    let a = rc / (rc + dt)
    var out = [Double](repeating: 0, count: input.count)
    var prevIn = 0.0, prevOut = 0.0
    for i in input.indices {
        let v = a * (prevOut + input[i] - prevIn)
        out[i] = v
        prevIn = input[i]
        prevOut = v
    }
    return out
}

/// A struck metal body: a handful of inharmonic partials, each with its own decay.
func metalHit(duration: Double, partials: [(freq: Double, amp: Double, decay: Double)],
              noiseAmount: Double, noiseCut: Double, attack: Double = 0.0012) -> [Double] {
    let n = Int(duration * SR)
    var out = [Double](repeating: 0, count: n)
    for p in partials {
        let drift = p.freq * 0.0015
        for i in 0..<n {
            let t = Double(i) / SR
            let e = exp(-t / p.decay)
            let f = p.freq + drift * sin(2 * Double.pi * 3.1 * t)
            out[i] += sin(2 * Double.pi * f * t) * p.amp * e
        }
    }
    if noiseAmount > 0 {
        var noise = [Double](repeating: 0, count: n)
        for i in 0..<n { noise[i] = urand() }
        let filtered = lowpass(noise, cutoff: noiseCut)
        for i in 0..<n {
            let t = Double(i) / SR
            out[i] += filtered[i] * noiseAmount * exp(-t / 0.035)
        }
    }
    for i in 0..<n { out[i] *= env(i, n, attack: attack, decay: duration * 0.5, curve: 1.0) }
    return out
}

// MARK: - Sounds

func makeHitHot() {
    seedAudio(11)
    // Hot steel absorbs the blow: low thud, very short ring.
    let s = metalHit(duration: 0.42,
                     partials: [(148, 0.85, 0.055), (233, 0.42, 0.040),
                                (392, 0.22, 0.028), (611, 0.10, 0.018)],
                     noiseAmount: 0.55, noiseCut: 1800)
    writeWAV(s, "fx_hit_hot")
}

func makeHitCold() {
    seedAudio(22)
    // Cold steel rings hard and bright, and it is not a nice sound.
    let s = metalHit(duration: 0.85,
                     partials: [(523, 0.70, 0.30), (911, 0.55, 0.24),
                                (1_477, 0.34, 0.17), (2_213, 0.20, 0.11), (3_190, 0.10, 0.07)],
                     noiseAmount: 0.30, noiseCut: 5200)
    writeWAV(s, "fx_hit_cold")
}

func makeRing() {
    seedAudio(33)
    // The anvil's own note, struck on the face.
    let s = metalHit(duration: 1.6,
                     partials: [(396, 0.60, 0.75), (658, 0.40, 0.55),
                                (1_044, 0.26, 0.36), (1_589, 0.14, 0.22), (2_402, 0.07, 0.14)],
                     noiseAmount: 0.14, noiseCut: 4000)
    writeWAV(s, "fx_ring")
}

func makeBellows() {
    seedAudio(44)
    let n = Int(0.9 * SR)
    var noise = [Double](repeating: 0, count: n)
    for i in 0..<n { noise[i] = urand() }
    var band = lowpass(noise, cutoff: 900)
    band = highpass(band, cutoff: 120)
    var out = [Double](repeating: 0, count: n)
    for i in 0..<n {
        let t = Double(i) / SR
        // A swell and fall, like one push of the handle.
        let shape = sin(Double.pi * min(1, t / 0.9))
        out[i] = band[i] * shape * 0.9
        // A little low roar underneath as the fire takes the air.
        out[i] += sin(2 * Double.pi * 58 * t) * 0.10 * shape
    }
    writeWAV(out, "fx_bellows")
}

func makeQuench() {
    seedAudio(55)
    let n = Int(1.5 * SR)
    var noise = [Double](repeating: 0, count: n)
    for i in 0..<n { noise[i] = urand() }
    var hiss = highpass(noise, cutoff: 1500)
    hiss = lowpass(hiss, cutoff: 8500)
    var out = [Double](repeating: 0, count: n)
    for i in 0..<n {
        let t = Double(i) / SR
        let burst = t < 0.05 ? t / 0.05 : exp(-(t - 0.05) / 0.42)
        out[i] = hiss[i] * burst
        // The bubbling underneath.
        out[i] += sin(2 * Double.pi * (90 + 40 * sin(2 * Double.pi * 7 * t)) * t) * 0.10
            * exp(-t / 0.30)
        let tail = min(1.0, (Double(n) / SR - t) / 0.05)
        out[i] *= max(0, tail)
    }
    writeWAV(out, "fx_quench")
}

func makeCrack() {
    seedAudio(66)
    let n = Int(0.5 * SR)
    var out = [Double](repeating: 0, count: n)
    // A sharp snap: broadband transient plus a dying high partial.
    for i in 0..<n {
        let t = Double(i) / SR
        let snap = exp(-t / 0.006)
        out[i] = urand() * snap
        out[i] += sin(2 * Double.pi * 1_820 * t) * 0.35 * exp(-t / 0.09)
        out[i] += sin(2 * Double.pi * 2_960 * t) * 0.20 * exp(-t / 0.05)
    }
    let filtered = highpass(out, cutoff: 400)
    var shaped = filtered
    for i in 0..<n { shaped[i] *= env(i, n, attack: 0.0004, decay: 0.14, curve: 1.2) }
    writeWAV(shaped, "fx_crack")
}

func makePunch() {
    seedAudio(77)
    let s = metalHit(duration: 0.55,
                     partials: [(96, 0.90, 0.09), (172, 0.50, 0.07), (311, 0.24, 0.05)],
                     noiseAmount: 0.75, noiseCut: 1100, attack: 0.002)
    writeWAV(s, "fx_punch")
}

func makeTwist() {
    seedAudio(88)
    let n = Int(0.9 * SR)
    var out = [Double](repeating: 0, count: n)
    // Metal groaning as it takes the twist: a rising creak built from stick-slip.
    var phase = 0.0
    for i in 0..<n {
        let t = Double(i) / SR
        let f = 210 + 190 * t + 26 * sin(2 * Double.pi * 11 * t)
        phase += 2 * Double.pi * f / SR
        let grit = (sin(phase) > 0 ? 1.0 : -1.0) * 0.35 + sin(phase) * 0.65
        out[i] = grit * exp(-abs(t - 0.35) / 0.30) * 0.7
        out[i] += urand() * 0.10 * exp(-t / 0.4)
    }
    var shaped = lowpass(out, cutoff: 2600)
    for i in 0..<n { shaped[i] *= env(i, n, attack: 0.03, decay: 0.5, curve: 1.1) }
    writeWAV(shaped, "fx_twist")
}

func makeChime() {
    seedAudio(99)
    let n = Int(1.9 * SR)
    var out = [Double](repeating: 0, count: n)
    // A small brass triad, struck in sequence.
    let notes: [(Double, Double)] = [(523.25, 0.0), (659.25, 0.075), (783.99, 0.15), (1046.5, 0.26)]
    for (f, delay) in notes {
        let start = Int(delay * SR)
        for i in start..<n {
            let t = Double(i - start) / SR
            let e = exp(-t / 0.55)
            out[i] += (sin(2 * Double.pi * f * t) * 0.6
                       + sin(2 * Double.pi * f * 2.76 * t) * 0.16
                       + sin(2 * Double.pi * f * 5.4 * t) * 0.06) * e * 0.45
        }
    }
    for i in 0..<n { out[i] *= env(i, n, attack: 0.002, decay: 1.2, curve: 0.9) }
    writeWAV(out, "fx_chime")
}

func makeTap() {
    seedAudio(111)
    let s = metalHit(duration: 0.16,
                     partials: [(880, 0.45, 0.020), (1_320, 0.22, 0.014)],
                     noiseAmount: 0.35, noiseCut: 3500)
    writeWAV(s, "fx_tap")
}

func makeAmbient() {
    seedAudio(222)
    // Twelve seconds of coal fire: a low roar, a wandering hiss, and pops.
    let seconds = 12.0
    let n = Int(seconds * SR)
    var noise = [Double](repeating: 0, count: n)
    for i in 0..<n { noise[i] = urand() }
    var roar = lowpass(noise, cutoff: 260)
    roar = highpass(roar, cutoff: 35)
    var hiss = highpass(noise, cutoff: 2400)
    hiss = lowpass(hiss, cutoff: 7000)

    var out = [Double](repeating: 0, count: n)
    for i in 0..<n {
        let t = Double(i) / SR
        // Slow breathing so the loop never sounds static.
        let breath = 0.72 + 0.28 * sin(2 * Double.pi * t / 6.0) * cos(2 * Double.pi * t / 3.7)
        out[i] = roar[i] * 1.5 * breath + hiss[i] * 0.16 * breath
    }
    // Occasional pops from the coal bed.
    var popAt = 0.4
    while popAt < seconds - 0.4 {
        let start = Int(popAt * SR)
        let len = Int(0.09 * SR)
        let f = 320.0 + Double((rs % 400))
        for k in 0..<len where start + k < n {
            let t = Double(k) / SR
            let e = exp(-t / 0.014)
            out[start + k] += (sin(2 * Double.pi * f * t) * 0.5 + urand() * 0.5) * e * 0.32
        }
        popAt += 0.35 + abs(urand()) * 1.5
    }
    // Fold the last quarter-second back over the first so the loop is seamless,
    // then drop the folded tail entirely.
    let fade = Int(0.25 * SR)
    for k in 0..<fade {
        let f = Double(k) / Double(fade)
        out[k] = out[k] * f + out[n - fade + k] * (1 - f)
    }
    out.removeLast(fade)
    writeWAV(out, "amb_forge")
}

// MARK: - Run

makeHitHot()
makeHitCold()
makeRing()
makeBellows()
makeQuench()
makeCrack()
makePunch()
makeTwist()
makeChime()
makeTap()
makeAmbient()
print("done")
