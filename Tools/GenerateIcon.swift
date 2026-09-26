// Генератор App Icon и иллюстрации автомобиля для AutoBudget.
// Запуск: swift Tools/GenerateIcon.swift
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let accent = CGColor(srgbRed: 0, green: 212 / 255, blue: 170 / 255, alpha: 1)
func accentA(_ a: CGFloat) -> CGColor { accent.copy(alpha: a)! }
func gray(_ w: CGFloat, _ a: CGFloat = 1) -> CGColor { CGColor(srgbRed: w, green: w, blue: w, alpha: a) }

func makeContext(width: Int, height: Int) -> CGContext {
    let ctx = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!,
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    // Переворачиваем систему координат: (0,0) — левый верхний угол
    ctx.translateBy(x: 0, y: CGFloat(height))
    ctx.scaleBy(x: 1, y: -1)
    return ctx
}

func save(_ ctx: CGContext, to path: String) {
    let image = ctx.makeImage()!
    let url = URL(fileURLWithPath: path)
    let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, image, nil)
    CGImageDestinationFinalize(dest)
    print("✓ \(path)")
}

/// Силуэт седана (Toyota Aristo-style) в координатах 1024-холста.
func carBodyPath(scale s: CGFloat = 1, dx: CGFloat = 0, dy: CGFloat = 0) -> CGPath {
    func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * s + dx, y: y * s + dy) }
    let path = CGMutablePath()
    path.move(to: p(150, 735))
    path.addCurve(to: p(165, 668), control1: p(140, 715), control2: p(145, 685))
    path.addCurve(to: p(250, 640), control1: p(185, 652), control2: p(215, 645))
    path.addLine(to: p(405, 620))
    path.addCurve(to: p(530, 548), control1: p(450, 590), control2: p(490, 556))
    path.addCurve(to: p(700, 552), control1: p(590, 538), control2: p(650, 540))
    path.addCurve(to: p(805, 612), control1: p(745, 565), control2: p(780, 595))
    path.addLine(to: p(870, 625))
    path.addCurve(to: p(885, 700), control1: p(885, 640), control2: p(890, 675))
    path.addCurve(to: p(865, 735), control1: p(882, 722), control2: p(875, 733))
    path.addLine(to: p(788, 735))
    path.addArc(center: p(722, 735), radius: 66 * s, startAngle: 0, endAngle: .pi, clockwise: true)
    path.addLine(to: p(368, 735))
    path.addArc(center: p(302, 735), radius: 66 * s, startAngle: 0, endAngle: .pi, clockwise: true)
    path.closeSubpath()
    return path
}

func windowPath(scale s: CGFloat = 1, dx: CGFloat = 0, dy: CGFloat = 0) -> CGPath {
    func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * s + dx, y: y * s + dy) }
    let path = CGMutablePath()
    path.move(to: p(432, 615))
    path.addCurve(to: p(538, 562), control1: p(470, 588), control2: p(505, 568))
    path.addCurve(to: p(690, 566), control1: p(590, 555), control2: p(645, 556))
    path.addCurve(to: p(772, 612), control1: p(725, 575), control2: p(752, 595))
    path.closeSubpath()
    return path
}

func drawCar(in ctx: CGContext, scale s: CGFloat = 1, dx: CGFloat = 0, dy: CGFloat = 0, glow: Bool = true) {
    func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * s + dx, y: y * s + dy) }
    let body = carBodyPath(scale: s, dx: dx, dy: dy)

    // Свечение под машиной
    if glow {
        ctx.saveGState()
        let g = CGGradient(colorsSpace: nil, colors: [accentA(0.45), accentA(0)] as CFArray, locations: [0, 1])!
        ctx.translateBy(x: p(512, 800).x, y: p(512, 800).y)
        ctx.scaleBy(x: 1, y: 0.12)
        ctx.drawRadialGradient(g, startCenter: .zero, startRadius: 0, endCenter: .zero, endRadius: 420 * s, options: [])
        ctx.restoreGState()
    }

    // Кузов — графитовый градиент
    ctx.saveGState()
    ctx.addPath(body)
    ctx.clip()
    let bodyGradient = CGGradient(colorsSpace: nil,
                                  colors: [gray(0.36), gray(0.17), gray(0.08)] as CFArray,
                                  locations: [0, 0.55, 1])!
    ctx.drawLinearGradient(bodyGradient, start: p(512, 540), end: p(512, 740), options: [])
    // Характерная линия по борту
    ctx.setStrokeColor(accentA(0.9))
    ctx.setLineWidth(5 * s)
    ctx.move(to: p(180, 668))
    ctx.addCurve(to: p(870, 650), control1: p(400, 650), control2: p(700, 640))
    ctx.strokePath()
    ctx.restoreGState()

    // Контур кузова
    ctx.addPath(body)
    ctx.setStrokeColor(gray(1, 0.18))
    ctx.setLineWidth(3 * s)
    ctx.strokePath()

    // Стёкла
    ctx.saveGState()
    ctx.addPath(windowPath(scale: s, dx: dx, dy: dy))
    ctx.clip()
    let glass = CGGradient(colorsSpace: nil, colors: [gray(0.02), gray(0.14)] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(glass, start: p(500, 560), end: p(600, 615), options: [])
    ctx.setStrokeColor(gray(0.3))
    ctx.setLineWidth(10 * s)
    ctx.move(to: p(605, 555)); ctx.addLine(to: p(598, 620))
    ctx.strokePath()
    ctx.restoreGState()

    // Фары
    ctx.setFillColor(gray(0.95))
    ctx.fillEllipse(in: CGRect(x: p(160, 660).x, y: p(160, 660).y, width: 38 * s, height: 12 * s))
    ctx.setFillColor(CGColor(srgbRed: 1, green: 0.2, blue: 0.25, alpha: 1))
    ctx.fill(CGRect(x: p(862, 640).x, y: p(862, 640).y, width: 18 * s, height: 16 * s))

    // Колёса
    for cx in [302.0, 722.0] {
        let c = p(cx, 735)
        ctx.setFillColor(gray(0.04))
        ctx.fillEllipse(in: CGRect(x: c.x - 56 * s, y: c.y - 56 * s, width: 112 * s, height: 112 * s))
        ctx.setStrokeColor(gray(0.55))
        ctx.setLineWidth(6 * s)
        ctx.strokeEllipse(in: CGRect(x: c.x - 34 * s, y: c.y - 34 * s, width: 68 * s, height: 68 * s))
        ctx.setLineWidth(5 * s)
        for i in 0..<5 {
            let a = CGFloat(i) * 2 * .pi / 5 - .pi / 2
            ctx.move(to: c)
            ctx.addLine(to: CGPoint(x: c.x + cos(a) * 32 * s, y: c.y + sin(a) * 32 * s))
        }
        ctx.strokePath()
        ctx.setFillColor(accent)
        ctx.fillEllipse(in: CGRect(x: c.x - 8 * s, y: c.y - 8 * s, width: 16 * s, height: 16 * s))
    }
}

// MARK: - App Icon 1024×1024 (стиль референса: белый спидометр с красной зоной, авто анфас)

let red = CGColor(srgbRed: 1, green: 0.23, blue: 0.23, alpha: 1)

/// Автомобиль анфас: серебристый кузов, тёмное стекло, узкие LED-фары
func drawCarFront(in ctx: CGContext) {
    // Тень / свечение под машиной
    ctx.saveGState()
    let shadow = CGGradient(colorsSpace: nil, colors: [gray(1, 0.18), gray(1, 0)] as CFArray, locations: [0, 1])!
    ctx.translateBy(x: 512, y: 830)
    ctx.scaleBy(x: 1, y: 0.1)
    ctx.drawRadialGradient(shadow, startCenter: .zero, startRadius: 0, endCenter: .zero, endRadius: 360, options: [])
    ctx.restoreGState()

    // Колёса (видны снизу)
    ctx.setFillColor(gray(0.06))
    for x in [248.0, 694.0] {
        ctx.addPath(CGPath(roundedRect: CGRect(x: x, y: 770, width: 82, height: 62), cornerWidth: 14, cornerHeight: 14, transform: nil))
    }
    ctx.fillPath()

    // Кузов
    let body = CGMutablePath()
    body.move(to: CGPoint(x: 335, y: 600))
    body.addLine(to: CGPoint(x: 689, y: 600))
    body.addCurve(to: CGPoint(x: 790, y: 668), control1: CGPoint(x: 740, y: 604), control2: CGPoint(x: 770, y: 640))
    body.addCurve(to: CGPoint(x: 808, y: 760), control1: CGPoint(x: 806, y: 690), control2: CGPoint(x: 812, y: 730))
    body.addCurve(to: CGPoint(x: 772, y: 800), control1: CGPoint(x: 806, y: 785), control2: CGPoint(x: 792, y: 798))
    body.addLine(to: CGPoint(x: 252, y: 800))
    body.addCurve(to: CGPoint(x: 216, y: 760), control1: CGPoint(x: 232, y: 798), control2: CGPoint(x: 218, y: 785))
    body.addCurve(to: CGPoint(x: 234, y: 668), control1: CGPoint(x: 212, y: 730), control2: CGPoint(x: 218, y: 690))
    body.addCurve(to: CGPoint(x: 335, y: 600), control1: CGPoint(x: 254, y: 640), control2: CGPoint(x: 284, y: 604))
    body.closeSubpath()
    ctx.saveGState()
    ctx.addPath(body)
    ctx.clip()
    let paint = CGGradient(colorsSpace: nil, colors: [gray(0.98), gray(0.78), gray(0.55)] as CFArray, locations: [0, 0.55, 1])!
    ctx.drawLinearGradient(paint, start: CGPoint(x: 512, y: 600), end: CGPoint(x: 512, y: 800), options: [])
    ctx.restoreGState()

    // Кабина и лобовое стекло
    let cabin = CGMutablePath()
    cabin.move(to: CGPoint(x: 392, y: 500))
    cabin.addLine(to: CGPoint(x: 632, y: 500))
    cabin.addCurve(to: CGPoint(x: 700, y: 604), control1: CGPoint(x: 660, y: 504), control2: CGPoint(x: 684, y: 560))
    cabin.addLine(to: CGPoint(x: 324, y: 604))
    cabin.addCurve(to: CGPoint(x: 392, y: 500), control1: CGPoint(x: 340, y: 560), control2: CGPoint(x: 364, y: 504))
    cabin.closeSubpath()
    ctx.addPath(cabin)
    ctx.setFillColor(gray(0.92))
    ctx.fillPath()

    let glass = CGMutablePath()
    glass.move(to: CGPoint(x: 404, y: 516))
    glass.addLine(to: CGPoint(x: 620, y: 516))
    glass.addCurve(to: CGPoint(x: 676, y: 596), control1: CGPoint(x: 644, y: 522), control2: CGPoint(x: 664, y: 564))
    glass.addLine(to: CGPoint(x: 348, y: 596))
    glass.addCurve(to: CGPoint(x: 404, y: 516), control1: CGPoint(x: 360, y: 564), control2: CGPoint(x: 380, y: 522))
    glass.closeSubpath()
    ctx.saveGState()
    ctx.addPath(glass)
    ctx.clip()
    let glassGrad = CGGradient(colorsSpace: nil, colors: [gray(0.22), gray(0.04)] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(glassGrad, start: CGPoint(x: 512, y: 516), end: CGPoint(x: 512, y: 596), options: [])
    ctx.restoreGState()

    // Зеркала
    ctx.setFillColor(gray(0.85))
    ctx.fillEllipse(in: CGRect(x: 292, y: 586, width: 46, height: 26))
    ctx.fillEllipse(in: CGRect(x: 686, y: 586, width: 46, height: 26))

    // Фары — тёмный корпус и узкая LED-полоса
    for mirror in [false, true] {
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: mirror ? 1024 - x : x, y: y) }
        let housing = CGMutablePath()
        housing.move(to: p(238, 676))
        housing.addLine(to: p(400, 700))
        housing.addLine(to: p(392, 734))
        housing.addLine(to: p(236, 716))
        housing.closeSubpath()
        ctx.addPath(housing)
        ctx.setFillColor(gray(0.08))
        ctx.fillPath()

        ctx.saveGState()
        ctx.setShadow(offset: .zero, blur: 18, color: gray(1, 0.9))
        ctx.setStrokeColor(gray(1))
        ctx.setLineWidth(6)
        ctx.setLineCap(.round)
        ctx.move(to: p(252, 686))
        ctx.addLine(to: p(388, 706))
        ctx.strokePath()
        ctx.restoreGState()
    }

    // Решётка радиатора и нижний воздухозаборник
    ctx.addPath(CGPath(roundedRect: CGRect(x: 432, y: 704, width: 160, height: 36), cornerWidth: 12, cornerHeight: 12, transform: nil))
    ctx.setFillColor(gray(0.1))
    ctx.fillPath()
    ctx.addPath(CGPath(roundedRect: CGRect(x: 350, y: 758, width: 324, height: 26), cornerWidth: 12, cornerHeight: 12, transform: nil))
    ctx.setFillColor(gray(0.14))
    ctx.fillPath()
    ctx.setFillColor(gray(0.8))
    ctx.fillEllipse(in: CGRect(x: 500, y: 712, width: 24, height: 20))
}

let icon = makeContext(width: 1024, height: 1024)
let bgGrad = CGGradient(colorsSpace: nil, colors: [CGColor(srgbRed: 0.13, green: 0.14, blue: 0.16, alpha: 1),
                                                  CGColor(srgbRed: 0.02, green: 0.02, blue: 0.03, alpha: 1)] as CFArray,
                        locations: [0, 1])!
icon.drawLinearGradient(bgGrad, start: CGPoint(x: 512, y: 0), end: CGPoint(x: 512, y: 1024), options: [])

let center = CGPoint(x: 512, y: 560)
let radius: CGFloat = 330
func arcPoint(_ deg: CGFloat, _ r: CGFloat) -> CGPoint {
    let a = deg * .pi / 180
    return CGPoint(x: center.x + cos(a) * r, y: center.y - sin(a) * r)
}
func strokeArc(from: CGFloat, to: CGFloat, color: CGColor, width: CGFloat) {
    icon.setStrokeColor(color)
    icon.setLineWidth(width)
    icon.setLineCap(.round)
    icon.move(to: arcPoint(from, radius))
    var d = from
    while d > to { d = max(d - 1, to); icon.addLine(to: arcPoint(d, radius)) }
    icon.strokePath()
}

// Белая дуга и красная зона в конце
strokeArc(from: 165, to: 38, color: gray(0.96), width: 30)
icon.saveGState()
icon.setShadow(offset: .zero, blur: 24, color: red.copy(alpha: 0.8)!)
strokeArc(from: 45, to: 15, color: red, width: 30)
icon.restoreGState()

// Деления
icon.setLineCap(.round)
for (deg, long) in [(140.0, false), (115.0, false), (90.0, true), (65.0, false)] {
    icon.setStrokeColor(gray(0.96, long ? 1 : 0.8))
    icon.setLineWidth(long ? 14 : 10)
    icon.move(to: arcPoint(deg, radius - 50))
    icon.addLine(to: arcPoint(deg, radius - (long ? 100 : 82)))
    icon.strokePath()
}

drawCarFront(in: icon)
save(icon, to: "AutoBudget/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png")

// MARK: - Иллюстрация для главного экрана (прозрачный фон)

let hero = makeContext(width: 1200, height: 520)
drawCar(in: hero, scale: 1.4, dx: -121, dy: -690)
save(hero, to: "AutoBudget/Resources/Assets.xcassets/CarHero.imageset/CarHero.png")
