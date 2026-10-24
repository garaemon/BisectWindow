// Draws the BisectWindow app icon and writes every size that a macOS
// AppIcon.appiconset needs, together with its Contents.json.
//
// Usage: swift scripts/generate-app-icon.swift <path/to/AppIcon.appiconset>

import AppKit

/// Point sizes of a macOS app icon. Each one ships at 1x and 2x.
let iconPointSizes = [16, 32, 128, 256, 512]

/// The icon is designed on Apple's 1024 px macOS grid: the rounded body
/// leaves a 100 px margin and uses a corner radius of about 185 px.
let canvasSize: CGFloat = 1024
let bodyInset: CGFloat = 100
let bodyCornerRadius: CGFloat = 185

func drawIcon(in context: CGContext) {
    let canvas = CGRect(x: 0, y: 0, width: canvasSize, height: canvasSize)
    let body = canvas.insetBy(dx: bodyInset, dy: bodyInset)
    drawBody(body, in: context)
    drawTiles(in: body.insetBy(dx: 110, dy: 110), context: context)
}

func drawBody(_ body: CGRect, in context: CGContext) {
    let bodyPath = CGPath(
        roundedRect: body, cornerWidth: bodyCornerRadius,
        cornerHeight: bodyCornerRadius, transform: nil
    )
    context.saveGState()
    context.setShadow(
        offset: CGSize(width: 0, height: -12), blur: 28,
        color: NSColor.black.withAlphaComponent(0.35).cgColor
    )
    context.addPath(bodyPath)
    context.setFillColor(NSColor.black.cgColor)
    context.fillPath()
    context.restoreGState()

    context.saveGState()
    context.addPath(bodyPath)
    context.clip()
    let gradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: [
            NSColor(red: 0.20, green: 0.24, blue: 0.40, alpha: 1).cgColor,
            NSColor(red: 0.08, green: 0.09, blue: 0.18, alpha: 1).cgColor,
        ] as CFArray,
        locations: [0, 1]
    )!
    context.drawLinearGradient(
        gradient,
        start: CGPoint(x: body.midX, y: body.maxY),
        end: CGPoint(x: body.midX, y: body.minY),
        options: []
    )
    context.restoreGState()
}

/// Draws the screen split into four quarters, with the top-right quarter
/// highlighted as the tile a window was just bisected into.
func drawTiles(in area: CGRect, context: CGContext) {
    let gap: CGFloat = 28
    let tileWidth = (area.width - gap) / 2
    let tileHeight = (area.height - gap) / 2
    let tileOrigins = [
        CGPoint(x: area.minX, y: area.minY + tileHeight + gap),
        CGPoint(x: area.minX + tileWidth + gap, y: area.minY + tileHeight + gap),
        CGPoint(x: area.minX, y: area.minY),
        CGPoint(x: area.minX + tileWidth + gap, y: area.minY),
    ]
    let highlightedTileIndex = 1
    for (index, origin) in tileOrigins.enumerated() {
        let tile = CGRect(
            origin: origin, size: CGSize(width: tileWidth, height: tileHeight)
        )
        let tileColor = index == highlightedTileIndex
            ? NSColor(red: 0.36, green: 0.78, blue: 1.0, alpha: 1)
            : NSColor.white.withAlphaComponent(0.18)
        context.addPath(CGPath(
            roundedRect: tile, cornerWidth: 44, cornerHeight: 44,
            transform: nil
        ))
        context.setFillColor(tileColor.cgColor)
        context.fillPath()
    }
}

func renderPNG(pixelSize: Int) -> Data {
    let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: pixelSize, pixelsHigh: pixelSize,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    let graphicsContext = NSGraphicsContext(bitmapImageRep: bitmap)!
    let context = graphicsContext.cgContext
    let scale = CGFloat(pixelSize) / canvasSize
    context.scaleBy(x: scale, y: scale)
    context.interpolationQuality = .high
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = graphicsContext
    drawIcon(in: context)
    NSGraphicsContext.restoreGraphicsState()
    return bitmap.representation(using: .png, properties: [:])!
}

func writeIconSet(to directory: URL) throws {
    try FileManager.default.createDirectory(
        at: directory, withIntermediateDirectories: true
    )
    var images: [[String: String]] = []
    for pointSize in iconPointSizes {
        for scale in [1, 2] {
            let fileName = "icon_\(pointSize)x\(pointSize)@\(scale)x.png"
            let png = renderPNG(pixelSize: pointSize * scale)
            try png.write(to: directory.appendingPathComponent(fileName))
            images.append([
                "filename": fileName,
                "idiom": "mac",
                "scale": "\(scale)x",
                "size": "\(pointSize)x\(pointSize)",
            ])
        }
    }
    let contents: [String: Any] = [
        "images": images,
        "info": ["author": "xcode", "version": 1],
    ]
    let json = try JSONSerialization.data(
        withJSONObject: contents, options: [.prettyPrinted, .sortedKeys]
    )
    try json.write(to: directory.appendingPathComponent("Contents.json"))
}

guard CommandLine.arguments.count == 2 else {
    FileHandle.standardError.write(
        Data("usage: generate-app-icon.swift <AppIcon.appiconset>\n".utf8)
    )
    exit(1)
}
try writeIconSet(to: URL(fileURLWithPath: CommandLine.arguments[1]))
