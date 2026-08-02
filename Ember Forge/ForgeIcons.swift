import SwiftUI

// Every glyph in Ember Forge is drawn here. Nothing comes from the system icon
// set, and nothing is an emoji.

// MARK: - Tab glyphs

struct AnvilGlyph: View {
    var size: CGFloat = 24
    var color: Color = Forge.chalk

    var body: some View {
        Canvas { ctx, s in
            let w = s.width, h = s.height
            var p = Path()
            // Anvil body with its horn.
            p.move(to: CGPoint(x: w * 0.06, y: h * 0.36))
            p.addLine(to: CGPoint(x: w * 0.72, y: h * 0.36))
            p.addQuadCurve(to: CGPoint(x: w * 0.96, y: h * 0.45),
                           control: CGPoint(x: w * 0.90, y: h * 0.34))
            p.addQuadCurve(to: CGPoint(x: w * 0.70, y: h * 0.50),
                           control: CGPoint(x: w * 0.88, y: h * 0.52))
            p.addLine(to: CGPoint(x: w * 0.60, y: h * 0.50))
            p.addLine(to: CGPoint(x: w * 0.54, y: h * 0.74))
            p.addLine(to: CGPoint(x: w * 0.70, y: h * 0.88))
            p.addLine(to: CGPoint(x: w * 0.18, y: h * 0.88))
            p.addLine(to: CGPoint(x: w * 0.34, y: h * 0.74))
            p.addLine(to: CGPoint(x: w * 0.28, y: h * 0.50))
            p.addLine(to: CGPoint(x: w * 0.06, y: h * 0.50))
            p.closeSubpath()
            ctx.fill(p, with: .color(color))
        }
        .frame(width: size, height: size)
    }
}

struct ScrollGlyph: View {
    var size: CGFloat = 24
    var color: Color = Forge.chalk

    var body: some View {
        Canvas { ctx, s in
            let w = s.width, h = s.height
            var page = Path()
            page.addRoundedRect(in: CGRect(x: w * 0.20, y: h * 0.10, width: w * 0.60, height: h * 0.80),
                                cornerSize: CGSize(width: w * 0.07, height: w * 0.07))
            ctx.stroke(page, with: .color(color), lineWidth: max(1.2, w * 0.075))
            for i in 0..<3 {
                var line = Path()
                let y = h * (0.32 + Double(i) * 0.18)
                line.move(to: CGPoint(x: w * 0.33, y: y))
                line.addLine(to: CGPoint(x: w * 0.67, y: y))
                ctx.stroke(line, with: .color(color), lineWidth: max(1, w * 0.065))
            }
        }
        .frame(width: size, height: size)
    }
}

struct BookGlyph: View {
    var size: CGFloat = 24
    var color: Color = Forge.chalk

    var body: some View {
        Canvas { ctx, s in
            let w = s.width, h = s.height
            var left = Path()
            left.move(to: CGPoint(x: w * 0.50, y: h * 0.24))
            left.addQuadCurve(to: CGPoint(x: w * 0.08, y: h * 0.20),
                              control: CGPoint(x: w * 0.28, y: h * 0.12))
            left.addLine(to: CGPoint(x: w * 0.08, y: h * 0.80))
            left.addQuadCurve(to: CGPoint(x: w * 0.50, y: h * 0.84),
                              control: CGPoint(x: w * 0.28, y: h * 0.74))
            left.closeSubpath()
            ctx.fill(left, with: .color(color.opacity(0.92)))

            var right = Path()
            right.move(to: CGPoint(x: w * 0.50, y: h * 0.24))
            right.addQuadCurve(to: CGPoint(x: w * 0.92, y: h * 0.20),
                               control: CGPoint(x: w * 0.72, y: h * 0.12))
            right.addLine(to: CGPoint(x: w * 0.92, y: h * 0.80))
            right.addQuadCurve(to: CGPoint(x: w * 0.50, y: h * 0.84),
                               control: CGPoint(x: w * 0.72, y: h * 0.74))
            right.closeSubpath()
            ctx.fill(right, with: .color(color.opacity(0.62)))
        }
        .frame(width: size, height: size)
    }
}

struct LedgerGlyph: View {
    var size: CGFloat = 24
    var color: Color = Forge.chalk

    var body: some View {
        Canvas { ctx, s in
            let w = s.width, h = s.height
            var frame = Path()
            frame.addRoundedRect(in: CGRect(x: w * 0.12, y: h * 0.14, width: w * 0.76, height: h * 0.72),
                                 cornerSize: CGSize(width: w * 0.08, height: w * 0.08))
            ctx.stroke(frame, with: .color(color), lineWidth: max(1.2, w * 0.075))
            for r in 0..<3 {
                for c in 0..<3 {
                    let x = w * (0.26 + Double(c) * 0.20)
                    let y = h * (0.30 + Double(r) * 0.19)
                    let filled = (r + c) % 2 == 0
                    let dot = Path(ellipseIn: CGRect(x: x - w * 0.045, y: y - w * 0.045,
                                                     width: w * 0.09, height: w * 0.09))
                    ctx.fill(dot, with: .color(color.opacity(filled ? 1 : 0.35)))
                }
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Tools

struct ToolGlyph: View {
    let tool: ForgeTool
    var size: CGFloat = 26
    var color: Color = Forge.chalk

    var body: some View {
        Canvas { ctx, s in
            let w = s.width, h = s.height
            let lw = max(1.4, w * 0.09)
            switch tool {
            case .hammer:
                var head = Path()
                head.addRoundedRect(in: CGRect(x: w * 0.14, y: h * 0.16, width: w * 0.72, height: h * 0.22),
                                    cornerSize: CGSize(width: w * 0.05, height: w * 0.05))
                ctx.fill(head, with: .color(color))
                var handle = Path()
                handle.addRoundedRect(in: CGRect(x: w * 0.44, y: h * 0.36, width: w * 0.12, height: h * 0.52),
                                      cornerSize: CGSize(width: w * 0.05, height: w * 0.05))
                ctx.fill(handle, with: .color(color.opacity(0.7)))

            case .crossPeen:
                var head = Path()
                head.move(to: CGPoint(x: w * 0.12, y: h * 0.18))
                head.addLine(to: CGPoint(x: w * 0.62, y: h * 0.18))
                head.addLine(to: CGPoint(x: w * 0.90, y: h * 0.27))
                head.addLine(to: CGPoint(x: w * 0.62, y: h * 0.36))
                head.addLine(to: CGPoint(x: w * 0.12, y: h * 0.36))
                head.closeSubpath()
                ctx.fill(head, with: .color(color))
                var handle = Path()
                handle.addRoundedRect(in: CGRect(x: w * 0.30, y: h * 0.36, width: w * 0.12, height: h * 0.52),
                                      cornerSize: CGSize(width: w * 0.05, height: w * 0.05))
                ctx.fill(handle, with: .color(color.opacity(0.7)))

            case .fuller:
                var body = Path()
                body.addRoundedRect(in: CGRect(x: w * 0.38, y: h * 0.10, width: w * 0.24, height: h * 0.52),
                                    cornerSize: CGSize(width: w * 0.06, height: w * 0.06))
                ctx.fill(body, with: .color(color.opacity(0.75)))
                var nose = Path()
                nose.addEllipse(in: CGRect(x: w * 0.30, y: h * 0.56, width: w * 0.40, height: h * 0.30))
                ctx.fill(nose, with: .color(color))

            case .punch:
                var body = Path()
                body.move(to: CGPoint(x: w * 0.36, y: h * 0.08))
                body.addLine(to: CGPoint(x: w * 0.64, y: h * 0.08))
                body.addLine(to: CGPoint(x: w * 0.56, y: h * 0.70))
                body.addLine(to: CGPoint(x: w * 0.44, y: h * 0.70))
                body.closeSubpath()
                ctx.fill(body, with: .color(color))
                var tip = Path()
                tip.move(to: CGPoint(x: w * 0.44, y: h * 0.70))
                tip.addLine(to: CGPoint(x: w * 0.56, y: h * 0.70))
                tip.addLine(to: CGPoint(x: w * 0.50, y: h * 0.94))
                tip.closeSubpath()
                ctx.fill(tip, with: .color(color.opacity(0.65)))

            case .bendFork:
                var stem = Path()
                stem.move(to: CGPoint(x: w * 0.50, y: h * 0.92))
                stem.addLine(to: CGPoint(x: w * 0.50, y: h * 0.42))
                ctx.stroke(stem, with: .color(color), lineWidth: lw * 1.3)
                var l = Path()
                l.move(to: CGPoint(x: w * 0.50, y: h * 0.44))
                l.addLine(to: CGPoint(x: w * 0.26, y: h * 0.10))
                var r = Path()
                r.move(to: CGPoint(x: w * 0.50, y: h * 0.44))
                r.addLine(to: CGPoint(x: w * 0.74, y: h * 0.10))
                ctx.stroke(l, with: .color(color), lineWidth: lw)
                ctx.stroke(r, with: .color(color), lineWidth: lw)

            case .twistWrench:
                var jaw = Path()
                jaw.addRoundedRect(in: CGRect(x: w * 0.14, y: h * 0.12, width: w * 0.52, height: h * 0.30),
                                   cornerSize: CGSize(width: w * 0.06, height: w * 0.06))
                ctx.stroke(jaw, with: .color(color), lineWidth: lw)
                var handle = Path()
                handle.move(to: CGPoint(x: w * 0.58, y: h * 0.42))
                handle.addLine(to: CGPoint(x: w * 0.84, y: h * 0.92))
                ctx.stroke(handle, with: .color(color), lineWidth: lw * 1.2)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Small marks

struct StarMark: View {
    var size: CGFloat = 14
    var filled: Bool = true
    var color: Color = Forge.spark

    var body: some View {
        Canvas { ctx, s in
            let c = CGPoint(x: s.width / 2, y: s.height / 2)
            let outer = min(s.width, s.height) / 2
            let inner = outer * 0.44
            var p = Path()
            for i in 0..<10 {
                let r = i % 2 == 0 ? outer : inner
                let a = -Double.pi / 2 + Double(i) * Double.pi / 5
                let pt = CGPoint(x: c.x + cos(a) * r, y: c.y + sin(a) * r)
                if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
            }
            p.closeSubpath()
            if filled {
                ctx.fill(p, with: .color(color))
            } else {
                ctx.stroke(p, with: .color(color.opacity(0.4)), lineWidth: max(1, s.width * 0.08))
            }
        }
        .frame(width: size, height: size)
    }
}

struct FlameMark: View {
    var size: CGFloat = 16
    var color: Color = Forge.flame

    var body: some View {
        Canvas { ctx, s in
            let w = s.width, h = s.height
            var p = Path()
            p.move(to: CGPoint(x: w * 0.50, y: h * 0.04))
            p.addQuadCurve(to: CGPoint(x: w * 0.86, y: h * 0.56),
                           control: CGPoint(x: w * 0.72, y: h * 0.26))
            p.addQuadCurve(to: CGPoint(x: w * 0.50, y: h * 0.96),
                           control: CGPoint(x: w * 0.92, y: h * 0.88))
            p.addQuadCurve(to: CGPoint(x: w * 0.14, y: h * 0.56),
                           control: CGPoint(x: w * 0.08, y: h * 0.88))
            p.addQuadCurve(to: CGPoint(x: w * 0.50, y: h * 0.04),
                           control: CGPoint(x: w * 0.28, y: h * 0.26))
            ctx.fill(p, with: .color(color))
            var core = Path()
            core.move(to: CGPoint(x: w * 0.50, y: h * 0.42))
            core.addQuadCurve(to: CGPoint(x: w * 0.68, y: h * 0.72),
                              control: CGPoint(x: w * 0.66, y: h * 0.54))
            core.addQuadCurve(to: CGPoint(x: w * 0.50, y: h * 0.92),
                              control: CGPoint(x: w * 0.70, y: h * 0.88))
            core.addQuadCurve(to: CGPoint(x: w * 0.32, y: h * 0.72),
                              control: CGPoint(x: w * 0.30, y: h * 0.88))
            core.addQuadCurve(to: CGPoint(x: w * 0.50, y: h * 0.42),
                              control: CGPoint(x: w * 0.34, y: h * 0.54))
            ctx.fill(core, with: .color(Forge.spark.opacity(0.85)))
        }
        .frame(width: size, height: size)
    }
}

struct ChevronMark: View {
    var size: CGFloat = 12
    var color: Color = Forge.chalkDim
    /// 0 = right, 1 = down, 2 = left, 3 = up
    var direction: Int = 0

    var body: some View {
        Canvas { ctx, s in
            let w = s.width, h = s.height
            var p = Path()
            p.move(to: CGPoint(x: w * 0.34, y: h * 0.18))
            p.addLine(to: CGPoint(x: w * 0.70, y: h * 0.50))
            p.addLine(to: CGPoint(x: w * 0.34, y: h * 0.82))
            ctx.stroke(p, with: .color(color),
                       style: StrokeStyle(lineWidth: max(1.3, w * 0.12), lineCap: .round, lineJoin: .round))
        }
        .frame(width: size, height: size)
        .rotationEffect(.degrees(Double(direction) * 90))
    }
}

struct CrossMark: View {
    var size: CGFloat = 14
    var color: Color = Forge.chalkDim

    var body: some View {
        Canvas { ctx, s in
            let w = s.width, h = s.height
            var p = Path()
            p.move(to: CGPoint(x: w * 0.22, y: h * 0.22))
            p.addLine(to: CGPoint(x: w * 0.78, y: h * 0.78))
            p.move(to: CGPoint(x: w * 0.78, y: h * 0.22))
            p.addLine(to: CGPoint(x: w * 0.22, y: h * 0.78))
            ctx.stroke(p, with: .color(color),
                       style: StrokeStyle(lineWidth: max(1.4, w * 0.12), lineCap: .round))
        }
        .frame(width: size, height: size)
    }
}

struct CheckMark: View {
    var size: CGFloat = 14
    var color: Color = Forge.good

    var body: some View {
        Canvas { ctx, s in
            let w = s.width, h = s.height
            var p = Path()
            p.move(to: CGPoint(x: w * 0.18, y: h * 0.52))
            p.addLine(to: CGPoint(x: w * 0.42, y: h * 0.76))
            p.addLine(to: CGPoint(x: w * 0.84, y: h * 0.24))
            ctx.stroke(p, with: .color(color),
                       style: StrokeStyle(lineWidth: max(1.6, w * 0.14), lineCap: .round, lineJoin: .round))
        }
        .frame(width: size, height: size)
    }
}

struct LockMark: View {
    var size: CGFloat = 14
    var color: Color = Forge.chalkFaint

    var body: some View {
        Canvas { ctx, s in
            let w = s.width, h = s.height
            var shackle = Path()
            shackle.addArc(center: CGPoint(x: w * 0.5, y: h * 0.42),
                           radius: w * 0.22,
                           startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
            ctx.stroke(shackle, with: .color(color), lineWidth: max(1.2, w * 0.11))
            var body = Path()
            body.addRoundedRect(in: CGRect(x: w * 0.22, y: h * 0.44, width: w * 0.56, height: h * 0.40),
                                cornerSize: CGSize(width: w * 0.08, height: w * 0.08))
            ctx.fill(body, with: .color(color))
        }
        .frame(width: size, height: size)
    }
}

struct GearMark: View {
    var size: CGFloat = 16
    var color: Color = Forge.chalkDim

    var body: some View {
        Canvas { ctx, s in
            let c = CGPoint(x: s.width / 2, y: s.height / 2)
            let r = min(s.width, s.height) * 0.34
            var teeth = Path()
            for i in 0..<8 {
                let a = Double(i) * Double.pi / 4
                let p1 = CGPoint(x: c.x + cos(a) * r * 0.92, y: c.y + sin(a) * r * 0.92)
                let p2 = CGPoint(x: c.x + cos(a) * r * 1.42, y: c.y + sin(a) * r * 1.42)
                teeth.move(to: p1)
                teeth.addLine(to: p2)
            }
            ctx.stroke(teeth, with: .color(color),
                       style: StrokeStyle(lineWidth: max(1.4, s.width * 0.12), lineCap: .round))
            var ring = Path()
            ring.addEllipse(in: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2))
            ctx.stroke(ring, with: .color(color), lineWidth: max(1.4, s.width * 0.11))
        }
        .frame(width: size, height: size)
    }
}

struct HeatDropMark: View {
    var size: CGFloat = 16
    var color: Color = Forge.quench

    var body: some View {
        Canvas { ctx, s in
            let w = s.width, h = s.height
            var p = Path()
            p.move(to: CGPoint(x: w * 0.50, y: h * 0.08))
            p.addQuadCurve(to: CGPoint(x: w * 0.84, y: h * 0.62),
                           control: CGPoint(x: w * 0.78, y: h * 0.32))
            p.addArc(center: CGPoint(x: w * 0.50, y: h * 0.62), radius: w * 0.34,
                     startAngle: .degrees(0), endAngle: .degrees(180), clockwise: false)
            p.closeSubpath()
            ctx.fill(p, with: .color(color))
        }
        .frame(width: size, height: size)
    }
}

/// A small ring of hammer marks used as a decorative divider.
struct HammerRule: View {
    var color: Color = Forge.slate

    var body: some View {
        Canvas { ctx, s in
            var line = Path()
            line.move(to: CGPoint(x: 0, y: s.height / 2))
            line.addLine(to: CGPoint(x: s.width, y: s.height / 2))
            ctx.stroke(line, with: .color(color), lineWidth: 1)
            let mid = s.width / 2
            var dot = Path()
            dot.addEllipse(in: CGRect(x: mid - 3, y: s.height / 2 - 3, width: 6, height: 6))
            ctx.fill(dot, with: .color(color))
        }
        .frame(height: 8)
    }
}
