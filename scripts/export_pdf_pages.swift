import Foundation
import PDFKit
import AppKit

let input = URL(fileURLWithPath: "/Users/sager/Desktop/brazil-smb-private-domain-playbook-v2.pdf")
let outputDir = URL(fileURLWithPath: "/Users/sager/Desktop/brazil-smb-private-domain-playbook-v2-pages", isDirectory: true)

let fm = FileManager.default
try fm.createDirectory(at: outputDir, withIntermediateDirectories: true)

guard let doc = PDFDocument(url: input) else {
    fatalError("Cannot open PDF")
}

for index in 0..<doc.pageCount {
    guard let page = doc.page(at: index) else { continue }
    let bounds = page.bounds(for: .mediaBox)
    let image = NSImage(size: bounds.size)
    image.lockFocus()
    NSColor.white.set()
    NSBezierPath(rect: NSRect(origin: .zero, size: bounds.size)).fill()
    if let ctx = NSGraphicsContext.current?.cgContext {
        page.draw(with: .mediaBox, to: ctx)
    }
    image.unlockFocus()

    guard let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let data = rep.representation(using: .png, properties: [:]) else {
        continue
    }

    let url = outputDir.appendingPathComponent(String(format: "page-%02d.png", index + 1))
    try data.write(to: url)
}

print(outputDir.path)
