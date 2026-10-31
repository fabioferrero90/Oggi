// Genera i livelli dell'icona di Oggi: sfondo all'alba e spunta bianca.
// Uso: swift Scripts/make-icon.swift <cartella dei livelli> [anteprima.png]
import AppKit

let out = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? ".")
let size = CGFloat(1024)

func render(_ name: String, to file: URL? = nil, _ draw: (CGContext) -> Void) {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size),
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    draw(NSGraphicsContext.current!.cgContext)
    NSGraphicsContext.restoreGraphicsState()
    try! rep.representation(using: .png, properties: [:])!.write(to: file ?? out.appendingPathComponent(name))
}

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(red: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: alpha)
}

func drawBackground(_ ctx: CGContext) {
    // Cielo all'alba: dall'albicocca in alto al corallo in basso.
    let sky = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                         colors: [color(0xFFC46B), color(0xFF8A5B), color(0xF2545B)] as CFArray,
                         locations: [0, 0.55, 1])!
    ctx.drawLinearGradient(sky, start: CGPoint(x: 0, y: size), end: CGPoint(x: 0, y: 0), options: [])
    // Sole che sorge, appena accennato dietro la spunta.
    let sun = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                         colors: [color(0xFFF1C9, 0.85), color(0xFFE29A, 0)] as CFArray, locations: [0, 1])!
    ctx.drawRadialGradient(sun, startCenter: CGPoint(x: size * 0.5, y: size * 0.42), startRadius: 0,
                           endCenter: CGPoint(x: size * 0.5, y: size * 0.42), endRadius: size * 0.42, options: [])
}

func checkPath() -> CGPath {
    let p = CGMutablePath()
    p.move(to: CGPoint(x: size * 0.30, y: size * 0.50))
    p.addLine(to: CGPoint(x: size * 0.44, y: size * 0.36))
    p.addLine(to: CGPoint(x: size * 0.71, y: size * 0.66))
    return p
}

func drawCheck(_ ctx: CGContext) {
    ctx.setLineCap(.round)
    ctx.setLineJoin(.round)
    ctx.setLineWidth(size * 0.105)
    ctx.setStrokeColor(.white)
    ctx.addPath(checkPath())
    ctx.strokePath()
}

render("background.png", drawBackground)
render("check.png", drawCheck)

// Versione già composta, per il README.
guard CommandLine.arguments.count > 2 else { exit(0) }
render("", to: URL(fileURLWithPath: CommandLine.arguments[2])) { ctx in
    let rect = CGRect(x: 100, y: 100, width: 824, height: 824)
    let shape = CGPath(roundedRect: rect, cornerWidth: 185, cornerHeight: 185, transform: nil)
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -12), blur: 28, color: color(0x000000, 0.3))
    ctx.addPath(shape); ctx.setFillColor(.white); ctx.fillPath()
    ctx.restoreGState()
    ctx.addPath(shape); ctx.clip()
    ctx.translateBy(x: 100, y: 100); ctx.scaleBy(x: 824 / size, y: 824 / size)
    drawBackground(ctx)
    ctx.setShadow(offset: CGSize(width: 0, height: -10), blur: 24, color: color(0x9E2B2B, 0.35))
    drawCheck(ctx)
}
