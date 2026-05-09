import Foundation
import AppKit
import CoreGraphics
import PDFKit

struct Theme {
    let bg = NSColor(calibratedRed: 0.97, green: 0.96, blue: 0.93, alpha: 1)
    let panel = NSColor.white
    let ink = NSColor(calibratedRed: 0.10, green: 0.16, blue: 0.20, alpha: 1)
    let muted = NSColor(calibratedRed: 0.34, green: 0.40, blue: 0.43, alpha: 1)
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
let outputURL = URL(fileURLWithPath: "/Users/sager/Documents/New project/dealism-brazil-private-growth-playbook.pdf")

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
    style.lineSpacing = lineSpacing ?? size * 0.26
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
    style.lineSpacing = lineSpacing ?? size * 0.26
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
    drawText(title, rect: CGRect(x: 106, y: 22, width: 760, height: 38), size: 30, weight: .bold)
    drawText(subtitle, rect: CGRect(x: 106, y: 62, width: 860, height: 22), size: 16, color: theme.muted)
    drawLine(from: CGPoint(x: 56, y: 96), to: CGPoint(x: 1224, y: 96), color: theme.line, width: 1.5)
}

func footer(page: Int) {
    drawText("Dealism x Brazil SMB Private Growth Playbook", rect: CGRect(x: 56, y: 680, width: 360, height: 16), size: 12, color: theme.muted)
    drawText("\(page)", rect: CGRect(x: 1198, y: 676, width: 26, height: 18), size: 12, color: theme.muted, align: .right)
}

func card(_ title: String, _ body: String, rect: CGRect, accent: NSColor, fill: NSColor = theme.panel) {
    drawRect(rect, fill: fill, stroke: theme.line, radius: 24)
    drawRect(CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: 10), fill: accent, radius: 24)
    drawText(title, rect: CGRect(x: rect.minX + 20, y: rect.minY + 22, width: rect.width - 40, height: 28), size: 24, weight: .bold)
    let h = textHeight(body, width: rect.width - 40, size: 16)
    drawText(body, rect: CGRect(x: rect.minX + 20, y: rect.minY + 58, width: rect.width - 40, height: h + 4), size: 16, color: theme.muted)
}

var page = 1

// Page 1
beginPage()
drawRect(CGRect(x: 40, y: 38, width: 1200, height: 644), fill: NSColor(calibratedRed: 0.99, green: 0.98, blue: 0.96, alpha: 1), stroke: theme.line, radius: 36)
pill("Brazil SMB", x: 84, y: 80, fill: theme.sand, width: 130)
pill("Dealism", x: 226, y: 80, fill: theme.tealSoft, width: 108)
pill("Playbook", x: 346, y: 80, fill: theme.coralSoft, width: 120)
drawText("Dealism x 巴西 SMB\n私域增长与销售手册", rect: CGRect(x: 84, y: 138, width: 520, height: 150), size: 48, weight: .bold, lineSpacing: 10)
drawText("这份版本不再只是“巴西化私域运营”。\n它把 Dealism 放进了 WhatsApp / Instagram 销售链路里，明确它在获客、培育、成交、复购中该承担的角色。", rect: CGRect(x: 86, y: 324, width: 520, height: 96), size: 24, color: theme.muted)
drawRect(CGRect(x: 718, y: 138, width: 446, height: 420), fill: theme.panel, stroke: theme.line, radius: 28)
drawText("Dealism 的官方定位", rect: CGRect(x: 748, y: 170, width: 250, height: 26), size: 28, weight: .bold)
drawBulletList([
    "Vibe Selling Agent",
    "Conversational AI Sales Agent",
    "主场景：WhatsApp 与 Instagram DMs",
    "价值：更像真人、更像销售，而不是普通客服机器人"], x: 748, y: 220, width: 370, size: 21, gap: 14)
drawRect(CGRect(x: 744, y: 420, width: 394, height: 92), fill: theme.tealSoft, radius: 22)
drawText("一句话：Dealism 适合写在\n“对话成交层”而不是“泛工具层”。", rect: CGRect(x: 770, y: 440, width: 340, height: 48), size: 24, weight: .semibold, align: .center)
drawRect(CGRect(x: 84, y: 570, width: 1080, height: 56), fill: theme.sand, radius: 20)
drawText("本版重点：修正版面、增强巴西本地化、把 Dealism 嵌入链路，并加入明显 CTA。", rect: CGRect(x: 110, y: 588, width: 1028, height: 20), size: 18, weight: .semibold, align: .center)
endPage()
page += 1

// Page 2
beginPage()
header(page: page, title: "Dealism 该放在什么位置", subtitle: "先讲清楚产品角色，再谈植入方式")
drawRect(CGRect(x: 70, y: 146, width: 240, height: 128), fill: theme.tealSoft, stroke: theme.line, radius: 24)
drawText("内容发现", rect: CGRect(x: 90, y: 176, width: 200, height: 28), size: 28, weight: .bold, align: .center)
drawText("Instagram\nReels / Stories / Ads", rect: CGRect(x: 90, y: 218, width: 200, height: 44), size: 19, color: theme.muted, align: .center)
drawRect(CGRect(x: 364, y: 146, width: 240, height: 128), fill: theme.coralSoft, stroke: theme.line, radius: 24)
drawText("转入聊天", rect: CGRect(x: 384, y: 176, width: 200, height: 28), size: 28, weight: .bold, align: .center)
drawText("Click to WhatsApp\nDM / Link / QR", rect: CGRect(x: 384, y: 218, width: 200, height: 44), size: 19, color: theme.muted, align: .center)
drawRect(CGRect(x: 658, y: 130, width: 270, height: 160), fill: theme.navySoft, stroke: theme.navy, lineWidth: 2, radius: 28)
drawText("Dealism", rect: CGRect(x: 688, y: 166, width: 210, height: 32), size: 34, weight: .bold, align: .center)
drawText("对话承接\n培育 / 跟进 / 成交推进", rect: CGRect(x: 688, y: 214, width: 210, height: 52), size: 21, weight: .semibold, color: theme.muted, align: .center)
drawRect(CGRect(x: 982, y: 146, width: 240, height: 128), fill: theme.oliveSoft, stroke: theme.line, radius: 24)
drawText("成交承接", rect: CGRect(x: 1002, y: 176, width: 200, height: 28), size: 28, weight: .bold, align: .center)
drawText("Pix / Site\nLoja / Retirada", rect: CGRect(x: 1002, y: 218, width: 200, height: 44), size: 19, color: theme.muted, align: .center)
drawArrow(from: CGPoint(x: 310, y: 210), to: CGPoint(x: 364, y: 210), color: theme.teal)
drawArrow(from: CGPoint(x: 604, y: 210), to: CGPoint(x: 658, y: 210), color: theme.coral)
drawArrow(from: CGPoint(x: 928, y: 210), to: CGPoint(x: 982, y: 210), color: theme.olive)
card("Dealism 应该承担的部分", "在 WhatsApp 和 Instagram DMs 里承接对话、理解客户意图、按照品牌语气回答、做销售跟进、把犹豫用户往成交推进。", rect: CGRect(x: 70, y: 360, width: 540, height: 156), accent: theme.teal)
card("Dealism 不该替代的部分", "品牌定位、价格策略、线下服务体验、履约、退款决策和重大客诉升级，仍应由品牌团队掌控。", rect: CGRect(x: 670, y: 360, width: 552, height: 156), accent: theme.coral)
drawRect(CGRect(x: 70, y: 560, width: 1152, height: 86), fill: theme.panel, stroke: theme.line, radius: 24)
drawText("结论：在这份 PDF 里，Dealism 不是“全链路替代品牌”，而是“把聊天这一步从人工低效，升级为可规模化的销售动作”。", rect: CGRect(x: 102, y: 586, width: 1088, height: 32), size: 21, weight: .medium, align: .center)
footer(page: page)
endPage()
page += 1

// Page 3
beginPage()
header(page: page, title: "为什么巴西市场特别适合 Dealism", subtitle: "产品能力和市场结构是对得上的")
let reasons = [
    ("1. WhatsApp 是主沟通层", "巴西 SMB 大量销售与咨询都在 WhatsApp 发生，因此“会聊、会跟、会推进成交”的工具比泛 CRM 更接近成交现场。", theme.teal),
    ("2. Instagram 负责发现", "Instagram 把人带进 DM 或 WhatsApp，真正决定能否成交的是后续对话质量。", theme.coral),
    ("3. Pix 缩短支付链路", "聊天中一旦建立信任，Pix 可以快速完成支付，这让 Dealism 的跟进动作更容易直接转收入。", theme.olive),
    ("4. SMB 人手有限", "很多品牌内容、客服、销售是同一拨人，Dealism 可以承担大量重复回复与跟进。", theme.navy)
]
for (idx, item) in reasons.enumerated() {
    let x = 72 + CGFloat(idx % 2) * 572
    let y = 132 + CGFloat(idx / 2) * 210
    card(item.0, item.1, rect: CGRect(x: x, y: y, width: 536, height: 174), accent: item.2)
}
drawRect(CGRect(x: 72, y: 574, width: 1136, height: 70), fill: theme.sand, radius: 22)
drawText("因此在巴西版私域手册里，Dealism 最自然的写法不是“AI 助手”，而是“WhatsApp / Instagram 的 AI 销售层”。", rect: CGRect(x: 102, y: 596, width: 1076, height: 24), size: 20, weight: .semibold, align: .center)
footer(page: page)
endPage()
page += 1

// Page 4
beginPage()
header(page: page, title: "Dealism 能替团队做哪些工作", subtitle: "把能力写成任务，而不是概念")
let workCards = [
    ("获客后首轮接待", "进入 WhatsApp / DM 后，先问需求、预算、偏好，代替人工做第一轮意图识别。"),
    ("产品知识回答", "基于历史聊天、FAQ、产品资料，用品牌自己的语气解释差异、功效、适配性。"),
    ("销售推进与催单", "对犹豫用户做 follow-up，把对话从问答推进到比较、选择与付款。"),
    ("线索培育", "不是所有人当天成交。Dealism 适合持续跟进潜客、召回沉默用户、推动复购。"),
    ("多账号收件箱协同", "官方页面强调 all-in-one inbox，适合统一承接 WhatsApp 与 Instagram DMs。"),
    ("自动 + 人工协同", "Autopilot / Copilot 两种模式意味着它既能自动回复，也能辅助人工编辑。")
]
for (idx, item) in workCards.enumerated() {
    let x = 56 + CGFloat(idx % 3) * 394
    let y = 132 + CGFloat(idx / 3) * 206
    let accent: NSColor = idx % 3 == 0 ? theme.teal : (idx % 3 == 1 ? theme.coral : theme.olive)
    card(item.0, item.1, rect: CGRect(x: x, y: y, width: 360, height: 170), accent: accent)
}
footer(page: page)
endPage()
page += 1

// Page 5
beginPage()
header(page: page, title: "把 Dealism 写进巴西私域运营 SOP", subtitle: "这页是你后续可以直接对外讲的版本")
drawRect(CGRect(x: 70, y: 132, width: 1140, height: 500), fill: theme.panel, stroke: theme.line, radius: 28)
let colsX: [CGFloat] = [96, 332, 594, 884]
let colW: [CGFloat] = [180, 220, 250, 250]
let titles = ["阶段", "品牌动作", "Dealism 负责", "结果"]
for i in 0..<4 {
    drawRect(CGRect(x: colsX[i], y: 160, width: colW[i], height: 48), fill: i == 0 ? theme.sand : theme.tealSoft, radius: 16)
    drawText(titles[i], rect: CGRect(x: colsX[i], y: 173, width: colW[i], height: 20), size: 18, weight: .bold, align: .center)
}
let table = [
    ["发现", "做内容、广告、门店 QR", "承接进入 DM / WhatsApp 的新线索", "不丢流量"],
    ["识别", "定义人群与标签", "问预算、需求、偏好、门店", "更快知道客户是谁"],
    ["解释", "提供产品知识库", "用品牌语气解释产品、化解异议", "提升信任"],
    ["成交", "提供 Pix / 站点 / 门店承接", "跟进犹豫客户、推进付款", "提升转化"],
    ["复购", "规划会员日和权益", "做补货提醒、沉默召回、再激活", "提高 LTV"]
]
for (idx, row) in table.enumerated() {
    let y = 220 + CGFloat(idx) * 76
    drawLine(from: CGPoint(x: 96, y: y), to: CGPoint(x: 1134, y: y), color: theme.line, width: 1)
    for i in 0..<4 {
        drawText(row[i], rect: CGRect(x: colsX[i] + 10, y: y + 18, width: colW[i] - 20, height: 40), size: i == 0 ? 20 : 16, weight: i == 0 ? .semibold : .regular, color: i == 0 ? theme.ink : theme.muted, align: i == 0 ? .center : .left)
    }
}
drawRect(CGRect(x: 70, y: 654, width: 1140, height: 34), fill: theme.navySoft, radius: 16)
drawText("这页最重要的变化：Dealism 不再是“额外工具”，而是 SOP 里可被指派的执行模块。", rect: CGRect(x: 90, y: 663, width: 1100, height: 16), size: 15, weight: .semibold, align: .center)
footer(page: page)
endPage()
page += 1

// Page 6
beginPage()
header(page: page, title: "案例：巴西社区美妆品牌怎么用 Dealism", subtitle: "从内容驱动，升级为内容 + 聊天 + 成交")
card("原问题", "Instagram 内容有流量，但 DM 回复慢、顾问跟进分散、很多用户问完就走。", rect: CGRect(x: 70, y: 134, width: 340, height: 144), accent: theme.coral)
card("接入 Dealism 后", "进入 DM / WhatsApp 的新线索先由 Dealism 接待，识别肤质、预算和购买意图，再把高价值客户交给人工。", rect: CGRect(x: 470, y: 134, width: 740, height: 144), accent: theme.teal)
drawRect(CGRect(x: 70, y: 324, width: 1140, height: 242), fill: theme.panel, stroke: theme.line, radius: 28)
drawText("新的工作流", rect: CGRect(x: 100, y: 354, width: 180, height: 26), size: 28, weight: .bold)
let flow = [
    ("Reels", "种草与引流", theme.tealSoft),
    ("DM / WA", "Dealism 首轮接待", theme.coralSoft),
    ("Segmentation", "按肤质 / 预算 / 价值分层", theme.oliveSoft),
    ("Pix / Loja", "付款或到店试色", theme.navySoft)
]
for (idx, item) in flow.enumerated() {
    let x = 100 + CGFloat(idx) * 260
    drawRect(CGRect(x: x, y: 418, width: 200, height: 100), fill: item.2, stroke: theme.line, radius: 22)
    drawText(item.0, rect: CGRect(x: x + 16, y: 440, width: 168, height: 24), size: 24, weight: .bold, align: .center)
    drawText(item.1, rect: CGRect(x: x + 16, y: 474, width: 168, height: 24), size: 16, color: theme.muted, align: .center)
    if idx < flow.count - 1 {
        drawArrow(from: CGPoint(x: x + 200, y: 468), to: CGPoint(x: x + 260, y: 468), color: theme.coral)
    }
}
drawRect(CGRect(x: 70, y: 590, width: 1140, height: 52), fill: theme.sand, radius: 18)
drawText("可对外说法：Dealism 让品牌把“聊不完的咨询”变成“可被持续推进的销售对话”。", rect: CGRect(x: 98, y: 606, width: 1084, height: 18), size: 18, weight: .semibold, align: .center)
footer(page: page)
endPage()
page += 1

// Page 7
beginPage()
header(page: page, title: "明显 CTA 应该怎么写", subtitle: "让 PDF 不只是方法论，而是带行动指令")
let ctas = [
    ("CTA 1", "Connect WhatsApp and Instagram DMs", "先把 Dealism 接入你的主要聊天入口，而不是先做复杂系统集成。"),
    ("CTA 2", "Upload your product docs and past chats", "让 Dealism 学会你的产品知识、FAQ 和销售语气。"),
    ("CTA 3", "Start free trial / book a demo", "给业务方一个明确动作，而不是只看完 PDF。"),
    ("CTA 4", "Use Dealism for 30 days on one pilot funnel", "先跑一个品类、一个门店、一个 WhatsApp 入口，验证聊天到成交的提升。")
]
for (idx, item) in ctas.enumerated() {
    let x = 70 + CGFloat(idx % 2) * 572
    let y = 130 + CGFloat(idx / 2) * 190
    drawRect(CGRect(x: x, y: y, width: 540, height: 154), fill: idx % 2 == 0 ? theme.tealSoft : theme.coralSoft, stroke: theme.line, radius: 26)
    drawText(item.0, rect: CGRect(x: x + 24, y: y + 24, width: 90, height: 24), size: 22, weight: .bold)
    drawText(item.1, rect: CGRect(x: x + 24, y: y + 58, width: 492, height: 28), size: 24, weight: .bold)
    drawText(item.2, rect: CGRect(x: x + 24, y: y + 96, width: 492, height: 36), size: 16, color: theme.muted)
}
drawRect(CGRect(x: 70, y: 560, width: 1140, height: 92), fill: theme.navy, radius: 28)
drawText("建议放在封底的主 CTA", rect: CGRect(x: 100, y: 584, width: 220, height: 24), size: 24, weight: .bold, color: .white)
drawText("Start using Dealism on your WhatsApp and Instagram sales funnel.", rect: CGRect(x: 340, y: 582, width: 620, height: 28), size: 24, weight: .bold, color: .white)
drawText("Free trial · Demo · Pilot one funnel in 30 days", rect: CGRect(x: 340, y: 618, width: 440, height: 20), size: 18, color: NSColor(calibratedWhite: 0.92, alpha: 1))
footer(page: page)
endPage()
page += 1

// Page 8
beginPage()
header(page: page, title: "最后一页：把 Dealism 讲成结果", subtitle: "少讲功能，多讲收入与效率")
drawRect(CGRect(x: 72, y: 136, width: 1136, height: 252), fill: theme.panel, stroke: theme.line, radius: 30)
drawText("推荐你在 PDF 封底直接这样写", rect: CGRect(x: 106, y: 168, width: 320, height: 28), size: 30, weight: .bold)
drawText("Dealism helps Brazil SMB brands turn WhatsApp and Instagram conversations into revenue.\nIt learns your tone, answers like your best sales rep, follows up 24/7, and helps move hesitant buyers toward payment.", rect: CGRect(x: 106, y: 226, width: 1020, height: 90), size: 24, color: theme.ink, lineSpacing: 8)
drawRect(CGRect(x: 72, y: 430, width: 540, height: 174), fill: theme.tealSoft, stroke: theme.line, radius: 26)
drawText("官方信息依据", rect: CGRect(x: 98, y: 460, width: 180, height: 24), size: 26, weight: .bold)
drawBulletList([
    "官方站点把自己定义为 Vibe Selling Agent / AI Sales Agent。",
    "主场景明确写到 WhatsApp 与 Instagram DMs。",
    "强调 learns from your knowledge & conversations。",
    "强调 autopilot / copilot、all-in-one inbox、24/7。"], x: 98, y: 504, width: 470, size: 17, gap: 10)
drawRect(CGRect(x: 648, y: 430, width: 560, height: 174), fill: theme.sand, stroke: theme.line, radius: 26)
drawText("建议落地动作", rect: CGRect(x: 676, y: 460, width: 180, height: 24), size: 26, weight: .bold)
drawBulletList([
    "先选一个 WhatsApp 入口做 pilot。",
    "接入产品资料与历史聊天。",
    "设置 Dealism 的销售目标与升级规则。",
    "30 天后看：回复率、成交率、复购率。"], x: 676, y: 504, width: 490, size: 17, gap: 10)
drawRect(CGRect(x: 72, y: 630, width: 1136, height: 44), fill: theme.navy, radius: 18)
drawText("CTA: Start free trial or book a demo at Dealism.ai", rect: CGRect(x: 100, y: 643, width: 1080, height: 18), size: 20, weight: .bold, color: .white, align: .center)
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
