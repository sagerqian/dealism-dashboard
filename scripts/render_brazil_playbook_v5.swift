import Foundation
import AppKit
import CoreGraphics
import PDFKit

struct Theme {
    let bg = NSColor(calibratedRed: 0.97, green: 0.96, blue: 0.93, alpha: 1)
    let panel = NSColor.white
    let ink = NSColor(calibratedRed: 0.10, green: 0.16, blue: 0.20, alpha: 1)
    let muted = NSColor(calibratedRed: 0.34, green: 0.39, blue: 0.43, alpha: 1)
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
let outputURL = URL(fileURLWithPath: "/Users/sager/Documents/New project/dealism-brazil-private-growth-playbook-v3.pdf")

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
    drawText(subtitle, rect: CGRect(x: 106, y: 62, width: 920, height: 22), size: 16, color: theme.muted)
    drawLine(from: CGPoint(x: 56, y: 96), to: CGPoint(x: 1224, y: 96), color: theme.line, width: 1.5)
}

func footer(page: Int) {
    drawText("Brazil SMB Private Domain & Sales Playbook", rect: CGRect(x: 56, y: 680, width: 320, height: 16), size: 12, color: theme.muted)
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

// 1 cover
beginPage()
drawRect(CGRect(x: 40, y: 36, width: 1200, height: 648), fill: NSColor(calibratedRed: 0.99, green: 0.98, blue: 0.96, alpha: 1), stroke: theme.line, radius: 36)
pill("Brazil SMB", x: 84, y: 78, fill: theme.sand, width: 132)
pill("Private Growth", x: 228, y: 78, fill: theme.tealSoft, width: 156)
pill("with Dealism", x: 396, y: 78, fill: theme.coralSoft, width: 152)
drawText("巴西 SMB\n私域运营与销售手册", rect: CGRect(x: 84, y: 134, width: 500, height: 140), size: 50, weight: .bold, lineSpacing: 8)
drawText("主线是私域运营与销售技巧。\nDealism 只放在它真正该出现的位置：聊天承接、销售推进、线索培育、复购跟进。", rect: CGRect(x: 86, y: 310, width: 520, height: 90), size: 24, color: theme.muted)
drawRect(CGRect(x: 710, y: 132, width: 454, height: 430), fill: theme.panel, stroke: theme.line, radius: 30)
drawText("这份手册回答 3 个问题", rect: CGRect(x: 742, y: 168, width: 280, height: 28), size: 28, weight: .bold)
drawBulletList([
    "巴西 SMB 的私域运营逻辑是什么？",
    "私域里真正有效的销售技巧是什么？",
    "Dealism 在这条链路里能承担哪些执行工作？"], x: 742, y: 222, width: 382, size: 22, gap: 16)
drawRect(CGRect(x: 742, y: 450, width: 390, height: 74), fill: theme.navySoft, radius: 22)
drawText("定位原则：Dealism 是执行层，不是主线本身。", rect: CGRect(x: 768, y: 475, width: 338, height: 24), size: 22, weight: .semibold, align: .center)
drawRect(CGRect(x: 84, y: 584, width: 1080, height: 54), fill: theme.sand, radius: 20)
drawText("版本目标：更清楚的方法论主线，更轻的 Dealism 植入，更明显但不抢戏的 CTA。", rect: CGRect(x: 112, y: 602, width: 1024, height: 18), size: 18, weight: .semibold, align: .center)
endPage()
page += 1

// 2 logic
beginPage()
header(page: page, title: "私域运营的底层逻辑", subtitle: "把一次性流量，变成可持续触达、可服务、可复购的客户资产")
let logic = [
    ("1. 先拿到持续触达权", "客户愿意留下 WhatsApp、邮箱或会员身份，后续经营才有价值。", theme.teal),
    ("2. 先识别，再群发", "不知道客户是谁、要什么、买过什么，就谈不上精细化运营。", theme.coral),
    ("3. 服务先于促销", "先帮客户减少决策成本，再谈折扣和刺激。", theme.olive),
    ("4. 分层，而不是一刀切", "新客、老客、VIP、高潜客户，需要不同节奏和不同权益。", theme.navy),
    ("5. 复购比首购更关键", "决定长期 ROI 的往往不是首单，而是后续复购和推荐。", theme.teal),
    ("6. 用户影响用户", "UGC、评价、转介绍、KOC 都是私域放大的关键。", theme.coral)
]
for (idx, item) in logic.enumerated() {
    let x = 56 + CGFloat(idx % 3) * 394
    let y = 130 + CGFloat(idx / 3) * 206
    card(item.0, item.1, rect: CGRect(x: x, y: y, width: 360, height: 170), accent: item.2)
}
footer(page: page)
endPage()
page += 1

// 3 brazil localization
beginPage()
header(page: page, title: "巴西 SMB 的本地化现实", subtitle: "主平台、支付方式、门店半径和法规边界，都会影响私域打法")
let realities = [
    ("Instagram 是发现入口", "内容负责吸引兴趣，真正的成交往往不在内容里完成。", theme.tealSoft, theme.teal),
    ("WhatsApp 是成交入口", "在巴西 SMB 场景里，对话层的质量往往直接影响成交率。", theme.coralSoft, theme.coral),
    ("Pix 缩短支付链路", "聊天里建立信任后，Pix 让“想买”更快变成“已付款”。", theme.oliveSoft, theme.olive),
    ("bairro 半径经营明显", "很多品牌天然有社区半径特征，所以门店、自提、配送、邻里关系很重要。", theme.navySoft, theme.navy),
    ("LGPD 约束触达边界", "要清楚告诉用户为什么收集数据、如何使用、如何退出。", theme.sand, theme.coral)
]
for (idx, item) in realities.enumerated() {
    let y = 128 + CGFloat(idx) * 104
    drawRect(CGRect(x: 72, y: y, width: 1136, height: 80), fill: item.2, stroke: theme.line, radius: 22)
    drawRect(CGRect(x: 72, y: y, width: 12, height: 80), fill: item.3, radius: 22)
    drawText(item.0, rect: CGRect(x: 104, y: y + 18, width: 290, height: 24), size: 24, weight: .bold)
    drawText(item.1, rect: CGRect(x: 390, y: y + 18, width: 780, height: 42), size: 17, color: theme.ink)
}
footer(page: page)
endPage()
page += 1

// 4 sales skills
beginPage()
header(page: page, title: "私域里的销售技巧", subtitle: "真正有效的不是群发促销，而是更像顾问、更像真人的推进")
let skills = [
    ("顾问式销售", "先问需求、预算、使用场景，再推荐方案。不要一上来只发产品。"),
    ("处理异议", "客户犹豫通常是价格、适配性、风险感、时机感。对话要一项项拆。"),
    ("缩短决策链路", "明确给出下一步：Pix 下单、到店试用、选套餐、预约咨询。"),
    ("持续跟进", "很多成交不发生在第一次聊天，follow-up 才是私域销售的分水岭。"),
    ("复购提醒", "补货、季节变化、使用周期、会员权益，都是复购触发点。"),
    ("用户证据", "评价、UGC、前后对比、门店反馈，可以降低成交不确定性。")
]
for (idx, skill) in skills.enumerated() {
    let x = 56 + CGFloat(idx % 2) * 586
    let y = 128 + CGFloat(idx / 2) * 180
    let accent: NSColor = idx % 2 == 0 ? theme.teal : theme.coral
    card(skill.0, skill.1, rect: CGRect(x: x, y: y, width: 552, height: 144), accent: accent)
}
drawRect(CGRect(x: 56, y: 650, width: 1160, height: 32), fill: theme.sand, radius: 16)
drawText("私域中的销售，不是“发活动信息”，而是“把聊天往成交方向推进”。", rect: CGRect(x: 80, y: 658, width: 1112, height: 16), size: 15, weight: .semibold, align: .center)
footer(page: page)
endPage()
page += 1

// 5 funnel and dealism insertion
beginPage()
header(page: page, title: "Dealism 放在哪里最合理", subtitle: "只植入它最擅长的部分：对话承接、异议处理、持续跟进")
let boxes = [
    (CGRect(x: 70, y: 170, width: 220, height: 118), "内容发现", "Instagram / Ads / Reels", theme.tealSoft),
    (CGRect(x: 350, y: 170, width: 220, height: 118), "进入聊天", "DM / WhatsApp / QR", theme.coralSoft),
    (CGRect(x: 630, y: 150, width: 260, height: 158), "Dealism", "接待 / 解答 / 跟进 / 推进", theme.navySoft),
    (CGRect(x: 950, y: 170, width: 220, height: 118), "成交承接", "Pix / Site / Loja", theme.oliveSoft)
]
for box in boxes {
    drawRect(box.0, fill: box.3, stroke: theme.line, radius: 26)
    drawText(box.1, rect: CGRect(x: box.0.minX + 16, y: box.0.minY + 24, width: box.0.width - 32, height: 28), size: box.1 == "Dealism" ? 34 : 28, weight: .bold, align: .center)
    drawText(box.2, rect: CGRect(x: box.0.minX + 16, y: box.0.minY + 66, width: box.0.width - 32, height: 42), size: box.1 == "Dealism" ? 20 : 18, color: theme.muted, align: .center)
}
drawArrow(from: CGPoint(x: 290, y: 229), to: CGPoint(x: 350, y: 229), color: theme.teal)
drawArrow(from: CGPoint(x: 570, y: 229), to: CGPoint(x: 630, y: 229), color: theme.coral)
drawArrow(from: CGPoint(x: 890, y: 229), to: CGPoint(x: 950, y: 229), color: theme.olive)
card("Dealism 能做什么", "按品牌语气接待新线索、回答常见问题、处理异议、对犹豫客户 follow-up、推动下一步动作。", rect: CGRect(x: 70, y: 386, width: 540, height: 150), accent: theme.teal)
card("Dealism 不替代什么", "品牌策略、内容方向、价格体系、履约、客诉升级和门店体验，仍然由团队掌控。", rect: CGRect(x: 670, y: 386, width: 540, height: 150), accent: theme.coral)
drawRect(CGRect(x: 70, y: 578, width: 1140, height: 68), fill: theme.navy, radius: 20)
drawText("一句话植入：Dealism lets your team scale the conversation layer of private sales.", rect: CGRect(x: 100, y: 600, width: 1080, height: 22), size: 22, weight: .bold, color: .white, align: .center)
footer(page: page)
endPage()
page += 1

// 6 sop
beginPage()
header(page: page, title: "把 Dealism 写进 SOP，而不是写成口号", subtitle: "这样它才像真实执行工具，而不是宣传素材")
drawRect(CGRect(x: 64, y: 132, width: 1152, height: 492), fill: theme.panel, stroke: theme.line, radius: 28)
let colXs: [CGFloat] = [90, 310, 544, 830, 1044]
let widths: [CGFloat] = [170, 210, 260, 180, 130]
let heads = ["阶段", "团队动作", "可由 Dealism 承担", "结果", "KPI"]
for i in 0..<heads.count {
    drawRect(CGRect(x: colXs[i], y: 160, width: widths[i], height: 48), fill: i == 0 ? theme.sand : theme.tealSoft, radius: 16)
    drawText(heads[i], rect: CGRect(x: colXs[i], y: 174, width: widths[i], height: 18), size: 18, weight: .bold, align: .center)
}
let rows = [
    ["获客", "做内容 / 广告 / 门店引流", "接住 DM / WhatsApp 新线索", "不丢线索", "Lead reply"],
    ["识别", "定义标签与人群", "问需求 / 预算 / 偏好", "更快分层", "Qualified lead"],
    ["解释", "提供产品知识", "解答问题 / 处理异议", "更高信任", "Reply quality"],
    ["推进", "提供付款与到店选项", "催单 / 比较 / 推荐下一步", "更多成交", "Conversion"],
    ["复购", "规划会员与权益", "补货提醒 / 召回沉默用户", "更高 LTV", "Repeat rate"]
]
for (idx, row) in rows.enumerated() {
    let y = 220 + CGFloat(idx) * 76
    drawLine(from: CGPoint(x: 90, y: y), to: CGPoint(x: 1174, y: y), color: theme.line, width: 1)
    for i in 0..<row.count {
        drawText(row[i], rect: CGRect(x: colXs[i] + 10, y: y + 16, width: widths[i] - 20, height: 42), size: i == 0 ? 19 : 15, weight: i == 0 ? .semibold : .regular, color: i == 0 ? theme.ink : theme.muted, align: i == 0 ? .center : .left)
    }
}
drawRect(CGRect(x: 64, y: 648, width: 1152, height: 34), fill: theme.sand, radius: 16)
drawText("这样写之后，Dealism 是“对话层执行模块”，而不是独立于业务之外的 AI 概念。", rect: CGRect(x: 90, y: 657, width: 1100, height: 16), size: 15, weight: .semibold, align: .center)
footer(page: page)
endPage()
page += 1

// 7 case
beginPage()
header(page: page, title: "案例：社区美妆品牌", subtitle: "主线仍是私域运营和销售，Dealism 只是让聊天层更强")
card("问题", "Instagram 有流量，但 DM 回复慢；用户问完就走；顾问跟进分散；复购没有节律。", rect: CGRect(x: 70, y: 136, width: 340, height: 148), accent: theme.coral)
card("私域解法", "把内容引流、聊天识别、Pix 成交、门店试色、会员日和复购提醒串成闭环。", rect: CGRect(x: 470, y: 136, width: 740, height: 148), accent: theme.teal)
drawRect(CGRect(x: 70, y: 330, width: 1140, height: 232), fill: theme.panel, stroke: theme.line, radius: 28)
drawText("其中 Dealism 的角色", rect: CGRect(x: 102, y: 360, width: 220, height: 26), size: 28, weight: .bold)
let steps = [
    ("1", "先接待新线索", "减少人工漏接"),
    ("2", "识别需求和预算", "更快分层"),
    ("3", "解释产品差异", "提高信任"),
    ("4", "跟进犹豫客户", "推动 Pix 或到店")
]
for (idx, step) in steps.enumerated() {
    let x = 104 + CGFloat(idx) * 266
    drawRect(CGRect(x: x, y: 418, width: 220, height: 102), fill: idx % 2 == 0 ? theme.tealSoft : theme.coralSoft, stroke: theme.line, radius: 22)
    drawText(step.0, rect: CGRect(x: x + 16, y: 436, width: 28, height: 24), size: 24, weight: .bold)
    drawText(step.1, rect: CGRect(x: x + 50, y: 434, width: 150, height: 24), size: 20, weight: .semibold)
    drawText(step.2, rect: CGRect(x: x + 16, y: 472, width: 188, height: 22), size: 16, color: theme.muted)
}
drawRect(CGRect(x: 70, y: 592, width: 1140, height: 58), fill: theme.navySoft, radius: 18)
drawText("这个案例里，Dealism 增强的是“销售对话效率”，不是替代整套私域运营。", rect: CGRect(x: 98, y: 611, width: 1084, height: 18), size: 18, weight: .semibold, align: .center)
footer(page: page)
endPage()
page += 1

// 8 CTA
beginPage()
header(page: page, title: "最后再放 CTA", subtitle: "先讲清主线，再给 Dealism 明确下一步")
drawRect(CGRect(x: 72, y: 136, width: 1136, height: 198), fill: theme.panel, stroke: theme.line, radius: 30)
drawText("推荐 CTA 写法", rect: CGRect(x: 104, y: 168, width: 180, height: 26), size: 28, weight: .bold)
drawText("If your team already gets leads on WhatsApp or Instagram, Dealism can help you reply faster, follow up better, and close more of them.", rect: CGRect(x: 104, y: 226, width: 1040, height: 72), size: 28, weight: .bold, color: theme.ink, lineSpacing: 8)
let ctas = [
    ("Connect WhatsApp and Instagram DMs", theme.tealSoft),
    ("Upload product docs and past chats", theme.coralSoft),
    ("Run a 30-day pilot on one funnel", theme.oliveSoft),
    ("Book a demo or start free trial", theme.navySoft)
]
for (idx, item) in ctas.enumerated() {
    let x = 72 + CGFloat(idx % 2) * 572
    let y = 384 + CGFloat(idx / 2) * 114
    drawRect(CGRect(x: x, y: y, width: 540, height: 86), fill: item.1, stroke: theme.line, radius: 22)
    drawText(item.0, rect: CGRect(x: x + 20, y: y + 28, width: 500, height: 28), size: 24, weight: .bold, align: .center)
}
drawRect(CGRect(x: 72, y: 612, width: 1136, height: 48), fill: theme.navy, radius: 18)
drawText("Main CTA: Turn your conversation layer into a sales layer with Dealism.", rect: CGRect(x: 100, y: 626, width: 1080, height: 20), size: 22, weight: .bold, color: .white, align: .center)
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
