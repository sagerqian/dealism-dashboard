import Foundation
import PDFKit
import Vision
import AppKit

struct Config {
    let inputPath: String
    let outputDir: String
    let scale: CGFloat
    let pageLimit: Int?
}

func parseArgs() -> Config {
    let args = CommandLine.arguments
    guard args.count >= 3 else {
        fputs("Usage: swift ocr_pdf.swift <input.pdf> <output-dir> [scale] [page-limit]\n", stderr)
        exit(1)
    }
    let scale = args.count >= 4 ? CGFloat(Double(args[3]) ?? 1.6) : 1.6
    let pageLimit = args.count >= 5 ? Int(args[4]) : nil
    return Config(inputPath: args[1], outputDir: args[2], scale: scale, pageLimit: pageLimit)
}

func render(page: PDFPage, scale: CGFloat) -> CGImage? {
    let pageRect = page.bounds(for: .mediaBox)
    let imageSize = NSSize(width: pageRect.width * scale, height: pageRect.height * scale)
    let image = NSImage(size: imageSize)
    image.lockFocus()
    NSColor.white.set()
    NSBezierPath(rect: NSRect(origin: .zero, size: imageSize)).fill()
    guard let context = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return nil
    }
    context.scaleBy(x: scale, y: scale)
    page.draw(with: .mediaBox, to: context)
    image.unlockFocus()

    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff) else {
        return nil
    }
    return bitmap.cgImage
}

func recognizeText(from image: CGImage) throws -> [String] {
    let request = VNRecognizeTextRequest()
    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = true
    request.recognitionLanguages = ["zh-Hans", "en-US"]

    let handler = VNImageRequestHandler(cgImage: image, options: [:])
    try handler.perform([request])

    return request.results?.compactMap { observation in
        observation.topCandidates(1).first?.string.trimmingCharacters(in: .whitespacesAndNewlines)
    }.filter { !$0.isEmpty } ?? []
}

let config = parseArgs()
let inputURL = URL(fileURLWithPath: config.inputPath)
let outputURL = URL(fileURLWithPath: config.outputDir, isDirectory: true)
let fileManager = FileManager.default

try fileManager.createDirectory(at: outputURL, withIntermediateDirectories: true)

guard let document = PDFDocument(url: inputURL) else {
    fputs("Failed to open PDF: \(config.inputPath)\n", stderr)
    exit(1)
}

let pageCount = config.pageLimit.map { min($0, document.pageCount) } ?? document.pageCount
var indexLines: [String] = []

for pageIndex in 0..<pageCount {
    autoreleasepool {
        let pageNumber = pageIndex + 1
        guard let page = document.page(at: pageIndex) else {
            indexLines.append("PAGE \(pageNumber)\n")
            return
        }

        guard let image = render(page: page, scale: config.scale) else {
            indexLines.append("PAGE \(pageNumber)\n")
            return
        }

        let textLines: [String]
        do {
            textLines = try recognizeText(from: image)
        } catch {
            indexLines.append("PAGE \(pageNumber)\n")
            return
        }

        let pageText = textLines.joined(separator: "\n")
        let filename = String(format: "page-%03d.txt", pageNumber)
        let pageURL = outputURL.appendingPathComponent(filename)
        try? pageText.write(to: pageURL, atomically: true, encoding: .utf8)

        indexLines.append("PAGE \(pageNumber)\n\(pageText)\n")
        fputs("Processed page \(pageNumber)/\(pageCount)\n", stderr)
    }
}

let combinedURL = outputURL.appendingPathComponent("combined.txt")
try indexLines.joined(separator: "\n").write(to: combinedURL, atomically: true, encoding: .utf8)
