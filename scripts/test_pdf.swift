import Foundation
import AppKit
import CoreGraphics

let output = URL(fileURLWithPath: "/Users/sager/Documents/New project/out-test.pdf")
var mediaBox = CGRect(x: 0, y: 0, width: 1280, height: 720)

guard let consumer = CGDataConsumer(url: output as CFURL),
      let ctx = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
    fatalError("Failed to create PDF context")
}

ctx.beginPDFPage(nil)
let graphics = NSGraphicsContext(cgContext: ctx, flipped: false)
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = graphics

func flip(_ rect: CGRect) -> CGRect {
    CGRect(x: rect.minX, y: mediaBox.height - rect.minY - rect.height, width: rect.width, height: rect.height)
}

ctx.setFillColor(NSColor.white.cgColor)
ctx.fill(mediaBox)

let block = flip(CGRect(x: 60, y: 80, width: 1160, height: 140))
ctx.setFillColor(NSColor(calibratedRed: 0.90, green: 0.95, blue: 0.96, alpha: 1).cgColor)
ctx.fill(block)

let title = NSAttributedString(
    string: "巴西 SMB 私域运营测试页",
    attributes: [
        .font: NSFont(name: "PingFang SC", size: 34) ?? NSFont.systemFont(ofSize: 34, weight: .bold),
        .foregroundColor: NSColor(calibratedRed: 0.05, green: 0.19, blue: 0.23, alpha: 1)
    ]
)
title.draw(in: flip(CGRect(x: 70, y: 100, width: 900, height: 50)))

let body = NSAttributedString(
    string: "如果你能看到这段中文，说明当前环境可以直接生成带中文和图形的 PDF。",
    attributes: [
        .font: NSFont(name: "PingFang SC", size: 18) ?? NSFont.systemFont(ofSize: 18),
        .foregroundColor: NSColor(calibratedWhite: 0.2, alpha: 1)
    ]
)
body.draw(with: flip(CGRect(x: 70, y: 160, width: 900, height: 80)), options: [.usesLineFragmentOrigin, .usesFontLeading])

NSGraphicsContext.restoreGraphicsState()
ctx.endPDFPage()
ctx.closePDF()

print(output.path)
