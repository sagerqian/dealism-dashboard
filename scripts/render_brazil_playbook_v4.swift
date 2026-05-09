import Foundation
import AppKit
import CoreGraphics
import PDFKit

struct Theme {
    let bg = NSColor(calibratedRed: 0.97, green: 0.96, blue: 0.93, alpha: 1)
    let panel = NSColor.white
    let ink = NSColor(calibratedRed: 0.10, green: 0.16, blue: 0.20, alpha: 1)
    let muted = NSColor(calibratedRed: 0.33, green: 0.39, blue: 0.43, alpha: 1)
    let teal = NSColor(calibratedRed: 0.10, green: 0.49, blue: 0.50, alpha: 1)
    let tealSoft = NSColor(calibratedRed: 0.86, green: 0.95, blue: 0.94, alpha: 1)
    let coral = NSColor(calibratedRed: 0.92, green: 0.60, blue: 0.44, alpha: 1)
    let coralSoft = NSColor(calibratedRed: 0.98, green: 0.89, blue: 0.84, alpha: 1)
    let olive = NSColor(calibratedRed: 0.57, green: 0.64, blue: 0.30, alpha: 1)
    let oliveSoft = NSColor(calibratedRed: 0.92, green: 0.96, blue: 0.85, alpha: 1)
    let navy = NSColor(calibratedRed: 0.16, green: 0.24, blue: 0.39, alpha: 1)
    let navySoft = NSColor(calibratedRed: 0.88, green: 0.91, blue: 0.97, alpha: 1)
    let sand = NSColor(calibratedRed: 0.95, green: 0.90, blue: 0.80, alpha: 1)
    let line = NSColor(calibratedRed: 0.84, green: 0.83, blue: 0.79, alpha: 1)
}

let theme = Theme()
let pageSize = CGSize(width: 1280, height: 720)
let outputURL = URL(fileURLWithPath: "/Users/sager/Documents/New project/dealism-brazil-private-growth-playbook-v2.pdf")

var currentImage: NSImage?
var pageImages: [NSImage] = []

func flip(_ rect: CGRect) -> CGRect {
    CGRect(x: rect.minX, y: pageSize.height - rect.minY - rect.height, width: rect.width, height: rect.height)
}

func font(_ size: CGFloat, _ weight: NSFont.Weight = .regular) -> NSFont {
    NSFont.systemFont(ofSize: size, weight: weight)
}

func beginPage() {
    let image = NSImage(size: pageSize)
    image.lockFocus()
    currentImage = image
    if let ctx = NSGraphicsContext.current?.cgContext {
        ctx.setFillColor(theme.bg.cgColor)
        ctx.fill(CGRect(origin: .zero, size: pageSize))
    }
}

func endPage() {
    currentImage?.unlockFocus()
    if let image = currentImage {
        pageImages.append(image)
    }
    currentImage = nil
}

func textHeight(_ string: String, width: CGFloat, size: CGFloat, weight: NSFont.Weight = .regular, lineSpacing: CGFloat? = nil) -> CGFloat {
    let style = NSMutableParagraphStyle()
    style.lineSpacing = lineSpacing ?? size * 0.24
    let attr = NSAttributedString(string: string, attributes: [.font: font(size, weight), .paragraphStyle: style])
    return ceil(attr.boundingRect(with: CGSize(width: width, height: 10000), options: [.usesLineFragmentOrigin, .usesFontLeading]).height)
}

func drawText(_ string: String,
              rect: CGRect,
              size: CGFloat,
              weight: NSFont.Weight = .regular,
              color: NSColor = theme.ink,
              align: NSTextAlignment = .left,
              lineSpacing: CGFloat? = nil) {
    let style = NSMutableParagraphStyle()
    style.alignment = align
    style.lineSpacing = lineSpacing ?? size * 0.24
    let attr = NSAttributedString(
        string: string,
        attributes: [
            .font: font(size, weight),
            .foregroundColor: color,
            .paragraphStyle: style
        ]
    )
    attr.draw(with: flip(rect), options: [.usesLineFragmentOrigin, .usesFontLeading])
}

func drawRect(_ rect: CGRect, fill: NSColor, stroke: NSColor? = nil, lineWidth: CGFloat = 1, radius: CGFloat = 24) {
    let path = NSBezierPath(roundedRect: flip(rect), xRadius: radius, yRadius: radius)
    fill.setFill()
    path.fill()
    if let stroke {
        stroke.setStroke()
        path.lineWidth = lineWidth
        path.stroke()
    }
}

func drawLine(from: CGPoint, to: CGPoint, color: NSColor, width: CGFloat = 2) {
    guard let ctx = NSGraphicsContext.current?.cgContext else { return }
    ctx.saveGState()
    ctx.setStrokeColor(color.cgColor)
    ctx.setLineWidth(width)
    ctx.move(to: CGPoint(x: from.x, y: pageSize.height - from.y))
    ctx.addLine(to: CGPoint(x: to.x, y: pageSize.height - to.y))
    ctx.strokePath()
    ctx.restoreGState()
}

func drawArrow(from: CGPoint, to: CGPoint, color: NSColor, width: CGFloat = 4) {
    drawLine(from: from, to: to, color: color, width: width)
    let angle = atan2(to.y - from.y, to.x - from.x)
    let len: CGFloat = 12
    let wing: CGFloat = .pi / 6
    let p1 = CGPoint(x: to.x - len * cos(angle - wing), y: to.y - len * sin(angle - wing))
    let p2 = CGPoint(x: to.x - len * cos(angle + wing), y: to.y - len * sin(angle + wing))
    drawLine(from: to, to: p1, color: color, width: width)
    drawLine(from: to, to: p2, color: color, width: width)
}

func drawBulletList(_ items: [String], x: CGFloat, y: CGFloat, width: CGFloat, size: CGFloat = 18, color: NSColor = theme.ink, gap: CGFloat = 12) {
    var cursor = y
    for item in items {
        drawText("•", rect: CGRect(x: x, y: cursor, width: 18, height: size + 4), size: size, weight: .bold, color: color)
        let h = textHeight(item, width: width - 24, size: size)
        drawText(item, rect: CGRect(x: x + 24, y: cursor, width: width - 24, height: h + 2), size: size, color: color)
        cursor += h + gap
    }
}

func pill(_ text: String, x: CGFloat, y: CGFloat, fill: NSColor, width: CGFloat) {
    drawRect(CGRect(x: x, y: y, width: width, height: 34), fill: fill, radius: 17)
    drawText(text, rect: CGRect(x: x, y: y + 8, width: width, height: 18), size: 15, weight: .semibold, align: .center)
}

func header(page: Int, title: String, subtitle: String) {
    drawText(String(format: "%02d", page), rect: CGRect(x: 56, y: 26, width: 42, height: 34), size: 22, weight: .bold, color: theme.coral)
    drawText(title, rect: CGRect(x: 106, y: 22, width: 780, height: 38), size: 30, weight: .bold)
    drawText(subtitle, rect: CGRect(x: 106, y: 62, width: 900, height: 22), size: 16, color: theme.muted)
    drawLine(from: CGPoint(x: 56, y: 96), to: CGPoint(x: 1224, y: 96), color: theme.line, width: 1.5)
}

func footer(page: Int) {
    drawText("Dealism x Brazil SMB Growth Deck", rect: CGRect(x: 56, y: 680, width: 280, height: 16), size: 12, color: theme.muted)
    drawText("\(page)", rect: CGRect(x: 1198, y: 676, width: 26, height: 18), size: 12, color: theme.muted, align: .right)
}

func card(_ title: String, _ body: String, rect: CGRect, accent: NSColor, fill: NSColor = theme.panel, bodyColor: NSColor = theme.muted) {
    drawRect(rect, fill: fill, stroke: theme.line, radius: 24)
    drawRect(CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: 10), fill: accent, radius: 24)
    drawText(title, rect: CGRect(x: rect.minX + 20, y: rect.minY + 22, width: rect.width - 40, height: 28), size: 24, weight: .bold)
    let h = textHeight(body, width: rect.width - 40, size: 16)
    drawText(body, rect: CGRect(x: rect.minX + 20, y: rect.minY + 58, width: rect.width - 40, height: h + 4), size: 16, color: bodyColor)
}

var page = 1

// 1 Cover
beginPage()
drawRect(CGRect(x: 38, y: 36, width: 1204, height: 648), fill: NSColor(calibratedRed: 0.99, green: 0.98, blue: 0.96, alpha: 1), stroke: theme.line, radius: 36)
pill("Dealism", x: 84, y: 78, fill: theme.tealSoft, width: 112)
pill("Brazil SMB", x: 208, y: 78, fill: theme.sand, width: 136)
pill("Growth Deck", x: 356, y: 78, fill: theme.coralSoft, width: 142)
drawText("Your best sales rep,\nnow AI.", rect: CGRect(x: 84, y: 132, width: 480, height: 120), size: 50, weight: .bold, lineSpacing: 8)
drawText("More leads. More bookings. More deals.", rect: CGRect(x: 86, y: 274, width: 500, height: 30), size: 28, weight: .semibold)
drawText("把 Dealism 的官网定位，重写进巴西 SMB 的私域与销售场景。\n主叙事不再是“工具功能”，而是“AI 销售代表如何在 WhatsApp 和 Instagram 里替你推进成交”。", rect: CGRect(x: 86, y: 338, width: 520, height: 96), size: 23, color: theme.muted)
drawRect(CGRect(x: 710, y: 132, width: 454, height: 442), fill: theme.panel, stroke: theme.line, radius: 30)
drawText("一句话定位", rect: CGRect(x: 740, y: 166, width: 180, height: 26), size: 28, weight: .bold)
drawText("Set it up by chatting. It learns your business and how you sell, then works 24/7 to follow up and move every lead toward a deal.", rect: CGRect(x: 740, y: 220, width: 394, height: 112), size: 24, color: theme.ink, lineSpacing: 8)
drawRect(CGRect(x: 740, y: 380, width: 394, height: 134), fill: theme.navySoft, radius: 22)
drawText("核心解释", rect: CGRect(x: 768, y: 404, width: 120, height: 24), size: 24, weight: .bold)
drawBulletList([
    "不是记录销售，而是推动销售。",
    "不是被动回答，而是主动跟进。",
    "不是客服脚本，而是成交对话。"], x: 768, y: 448, width: 332, size: 18, gap: 10)
drawRect(CGRect(x: 84, y: 586, width: 1080, height: 54), fill: theme.sand, radius: 20)
drawText("这版重点：Dealism 官方叙事 + 巴西本地化 + 明显 CTA + 更稳的版面。", rect: CGRect(x: 112, y: 604, width: 1024, height: 18), size: 18, weight: .semibold, align: .center)
endPage()
page += 1

// 2 Core promise
beginPage()
header(page: page, title: "Dealism 的核心承诺", subtitle: "这 5 句话就是你对外讲产品时最该保留的骨架")
let promises = [
    ("Human in the Loop", "它可以自主运行，但知道什么时候应该找人。品牌始终在环。", theme.teal),
    ("Gets better over time", "从每次对话里学习，越来越懂你的业务和销售方式。", theme.coral),
    ("No culture gap", "理解语言与文化，适合品牌探索新市场时降低摩擦。", theme.olive),
    ("Built for real conversations", "理解用户意图，能把问题谈清楚，让交易继续推进。", theme.navy),
    ("No missed opportunities", "每条消息都被处理，每个线索都被跟进。", theme.teal),
    ("Sells like a pro", "会识别意图、处理异议、像资深销售一样推进对话。", theme.coral)
]
for (idx, item) in promises.enumerated() {
    let x = 56 + CGFloat(idx % 3) * 394
    let y = 130 + CGFloat(idx / 3) * 206
    card(item.0, item.1, rect: CGRect(x: x, y: y, width: 360, height: 170), accent: item.2)
}
footer(page: page)
endPage()
page += 1

// 3 Beyond old stack
beginPage()
header(page: page, title: "Built beyond the old stack", subtitle: "Dealism 的价值对比，不应该写成功能表")
card("CRMs record. Dealism closes.", "CRM 记录已经发生的事；Dealism 处理正在发生的对话，把实时聊天推进成真实决策和真实收入。", rect: CGRect(x: 72, y: 138, width: 1136, height: 142), accent: theme.teal)
card("Workflows make you build. Dealism lets you talk.", "传统软件要求你学界面、学流程、学系统；Dealism 通过对话工作，你告诉它目标，它直接执行。", rect: CGRect(x: 72, y: 308, width: 1136, height: 142), accent: theme.coral)
card("Dealism lets you outgrow the product.", "传统产品的边界就是功能边界；Dealism 的叙事是：你只要说出需要，它可以生成技能去完成。", rect: CGRect(x: 72, y: 478, width: 1136, height: 142), accent: theme.navy)
drawRect(CGRect(x: 72, y: 646, width: 1136, height: 34), fill: theme.sand, radius: 16)
drawText("这页建议直接保留英文主标题，因为它更像产品心智锚点。", rect: CGRect(x: 92, y: 655, width: 1096, height: 16), size: 15, weight: .semibold, align: .center)
footer(page: page)
endPage()
page += 1

// 4 Brazil fit
beginPage()
header(page: page, title: "为什么这个叙事在巴西更容易成立", subtitle: "Dealism 的产品逻辑，和巴西 SMB 的销售现实是匹配的")
let fit = [
    ("WhatsApp 是主战场", "很多品牌真正成交发生在聊天，而不是网站表单。", theme.tealSoft, theme.teal),
    ("Instagram 负责把人带进 DM", "内容带来兴趣，聊天决定能不能成交。", theme.coralSoft, theme.coral),
    ("Pix 让聊天更接近付款", "一旦信任建立，聊天到支付的链路更短。", theme.oliveSoft, theme.olive),
    ("SMB 团队人少", "内容、客服、销售经常是同一批人，最缺的是 24/7 跟进能力。", theme.navySoft, theme.navy)
]
for (idx, item) in fit.enumerated() {
    let x = 78 + CGFloat(idx % 2) * 570
    let y = 138 + CGFloat(idx / 2) * 220
    drawRect(CGRect(x: x, y: y, width: 536, height: 182), fill: item.2, stroke: theme.line, radius: 26)
    drawText(item.0, rect: CGRect(x: x + 24, y: y + 28, width: 320, height: 28), size: 28, weight: .bold)
    drawText(item.1, rect: CGRect(x: x + 24, y: y + 76, width: 472, height: 52), size: 20, color: theme.muted)
    drawRect(CGRect(x: x + 398, y: y + 24, width: 102, height: 32), fill: theme.panel, stroke: item.3, lineWidth: 2, radius: 16)
    drawText("Brazil fit", rect: CGRect(x: x + 398, y: y + 32, width: 102, height: 14), size: 14, weight: .semibold, align: .center)
}
footer(page: page)
endPage()
page += 1

// 5 Funnel
beginPage()
header(page: page, title: "把 Dealism 放进巴西私域漏斗", subtitle: "这页要让人一眼看懂：Dealism 管哪一段")
let boxes = [
    (CGRect(x: 70, y: 170, width: 220, height: 118), "发现", "Instagram / Ads / Reels", theme.tealSoft),
    (CGRect(x: 350, y: 170, width: 220, height: 118), "进入聊天", "DM / WhatsApp / QR", theme.coralSoft),
    (CGRect(x: 630, y: 150, width: 260, height: 158), "Dealism", "接待 / 解答 / 跟进 / 推进", theme.navySoft),
    (CGRect(x: 950, y: 170, width: 220, height: 118), "成交", "Pix / Site / Loja", theme.oliveSoft)
]
for box in boxes {
    drawRect(box.0, fill: box.3, stroke: theme.line, radius: 26)
    drawText(box.1, rect: CGRect(x: box.0.minX + 20, y: box.0.minY + 26, width: box.0.width - 40, height: 26), size: box.1 == "Dealism" ? 34 : 28, weight: .bold, align: .center)
    drawText(box.2, rect: CGRect(x: box.0.minX + 20, y: box.0.minY + 66, width: box.0.width - 40, height: 42), size: box.1 == "Dealism" ? 20 : 18, color: theme.muted, align: .center)
}
drawArrow(from: CGPoint(x: 290, y: 229), to: CGPoint(x: 350, y: 229), color: theme.teal)
drawArrow(from: CGPoint(x: 570, y: 229), to: CGPoint(x: 630, y: 229), color: theme.coral)
drawArrow(from: CGPoint(x: 890, y: 229), to: CGPoint(x: 950, y: 229), color: theme.olive)
card("Dealism 最适合承担", "新线索首轮接待、产品咨询、异议处理、犹豫客户 follow-up、沉默线索再激活、复购提醒。", rect: CGRect(x: 70, y: 386, width: 540, height: 152), accent: theme.teal)
card("品牌团队继续掌控", "定价、促销策略、履约、门店服务、退款政策、重大客诉升级、长期品牌内容方向。", rect: CGRect(x: 670, y: 386, width: 540, height: 152), accent: theme.coral)
drawRect(CGRect(x: 70, y: 578, width: 1140, height: 68), fill: theme.sand, radius: 20)
drawText("正确写法：Dealism 是巴西私域漏斗中的对话成交层，而不是取代品牌的全能 AI。", rect: CGRect(x: 98, y: 600, width: 1084, height: 22), size: 20, weight: .semibold, align: .center)
footer(page: page)
endPage()
page += 1

// 6 SOP
beginPage()
header(page: page, title: "Dealism 写进 SOP 的方式", subtitle: "从“工具”升级成“可分配的销售动作”")
drawRect(CGRect(x: 64, y: 132, width: 1152, height: 492), fill: theme.panel, stroke: theme.line, radius: 28)
let colXs: [CGFloat] = [90, 322, 560, 828, 1048]
let widths: [CGFloat] = [180, 200, 230, 190, 120]
let heads = ["阶段", "品牌做什么", "Dealism 做什么", "输出结果", "KPI"]
for i in 0..<heads.count {
    drawRect(CGRect(x: colXs[i], y: 160, width: widths[i], height: 48), fill: i == 0 ? theme.sand : theme.tealSoft, radius: 16)
    drawText(heads[i], rect: CGRect(x: colXs[i], y: 174, width: widths[i], height: 18), size: 18, weight: .bold, align: .center)
}
let rows = [
    ["获客", "投内容、广告、门店 QR", "接住 DM / WhatsApp 新线索", "不丢线索", "Lead reply"],
    ["识别", "定义标签与人群", "问预算、需求、偏好", "更快分层", "Qualified lead"],
    ["解释", "准备知识库", "回答问题、处理异议", "更高信任", "Reply quality"],
    ["推进", "给付款与到店选项", "催单、比较、推荐下一步", "更多成交", "Conversion"],
    ["复购", "规划会员与权益", "提醒补货、召回沉默用户", "更高 LTV", "Repeat rate"]
]
for (idx, row) in rows.enumerated() {
    let y = 220 + CGFloat(idx) * 76
    drawLine(from: CGPoint(x: 90, y: y), to: CGPoint(x: 1168, y: y), color: theme.line, width: 1)
    for i in 0..<row.count {
        drawText(row[i], rect: CGRect(x: colXs[i] + 10, y: y + 16, width: widths[i] - 20, height: 42), size: i == 0 ? 19 : 15, weight: i == 0 ? .semibold : .regular, color: i == 0 ? theme.ink : theme.muted, align: i == 0 ? .center : .left)
    }
}
drawRect(CGRect(x: 64, y: 648, width: 1152, height: 34), fill: theme.navySoft, radius: 16)
drawText("Dealism 的价值不在于“自动回复”，而在于让销售 SOP 可以 24/7 发生。", rect: CGRect(x: 90, y: 657, width: 1100, height: 16), size: 15, weight: .semibold, align: .center)
footer(page: page)
endPage()
page += 1

// 7 CTA
beginPage()
header(page: page, title: "更明显的 CTA 怎么放", subtitle: "让这份 PDF 带出明确行动，而不是停在认知")
let ctas = [
    ("Connect your WhatsApp and Instagram DMs", "先连主入口，让 Dealism 接住真实对话。"),
    ("Upload product docs, FAQs, and past chats", "把知识和销售语气喂进去，让它更像你的 best sales rep。"),
    ("Start a 30-day pilot", "只选一个 funnel、一个品类、一个团队，先验证成交提升。"),
    ("Book a demo or start free trial", "让读者看完 PDF 后有明确下一步。")
]
for (idx, item) in ctas.enumerated() {
    let x = 70 + CGFloat(idx % 2) * 572
    let y = 138 + CGFloat(idx / 2) * 182
    drawRect(CGRect(x: x, y: y, width: 540, height: 146), fill: idx % 2 == 0 ? theme.tealSoft : theme.coralSoft, stroke: theme.line, radius: 26)
    drawText(item.0, rect: CGRect(x: x + 24, y: y + 24, width: 492, height: 54), size: 28, weight: .bold)
    drawText(item.1, rect: CGRect(x: x + 24, y: y + 92, width: 492, height: 24), size: 17, color: theme.muted)
}
drawRect(CGRect(x: 70, y: 542, width: 1140, height: 110), fill: theme.navy, radius: 30)
drawText("Main CTA", rect: CGRect(x: 104, y: 572, width: 120, height: 24), size: 24, weight: .bold, color: .white)
drawText("Turn your WhatsApp and Instagram conversations into revenue with Dealism.", rect: CGRect(x: 244, y: 570, width: 820, height: 28), size: 28, weight: .bold, color: .white)
drawText("Start free trial · Book a demo · Pilot one funnel in 30 days", rect: CGRect(x: 244, y: 612, width: 520, height: 20), size: 18, color: NSColor(calibratedWhite: 0.92, alpha: 1))
footer(page: page)
endPage()
page += 1

// 8 Close
beginPage()
header(page: page, title: "封底建议", subtitle: "用结果视角收尾，而不是再列一遍功能")
drawRect(CGRect(x: 72, y: 142, width: 1136, height: 220), fill: theme.panel, stroke: theme.line, radius: 30)
drawText("建议封底主文案", rect: CGRect(x: 104, y: 174, width: 220, height: 26), size: 28, weight: .bold)
drawText("Dealism helps Brazil SMB brands turn live conversations into real decisions and real revenue.", rect: CGRect(x: 104, y: 230, width: 1040, height: 40), size: 32, weight: .bold, color: theme.ink)
drawText("It learns how you sell, replies like a real sales rep, follows up 24/7, and keeps every lead moving toward a deal.", rect: CGRect(x: 104, y: 290, width: 1040, height: 54), size: 24, color: theme.muted)
card("推荐放上的短句", "CRMs record. Dealism closes.", rect: CGRect(x: 72, y: 410, width: 356, height: 140), accent: theme.teal)
card("推荐放上的业务句", "No missed opportunities. Every message handled. Every lead followed up.", rect: CGRect(x: 462, y: 410, width: 356, height: 140), accent: theme.coral)
card("推荐放上的扩张句", "No culture gap. Explore new markets without friction.", rect: CGRect(x: 852, y: 410, width: 356, height: 140), accent: theme.olive)
drawRect(CGRect(x: 72, y: 586, width: 1136, height: 70), fill: theme.sand, radius: 22)
drawText("CTA: Book a demo or start a free trial at Dealism.ai", rect: CGRect(x: 100, y: 608, width: 1080, height: 22), size: 24, weight: .bold, align: .center)
footer(page: page)
endPage()

let pdf = PDFDocument()
for (idx, image) in pageImages.enumerated() {
    if let page = PDFPage(image: image) {
        pdf.insert(page, at: idx)
    }
}
guard pdf.write(to: outputURL) else {
    fatalError("Failed to write PDF")
}
print(outputURL.path)
