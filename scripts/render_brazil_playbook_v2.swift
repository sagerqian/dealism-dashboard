import Foundation
import AppKit
import CoreGraphics
import PDFKit

struct Theme {
    let bg = NSColor(calibratedRed: 0.97, green: 0.96, blue: 0.93, alpha: 1)
    let panel = NSColor.white
    let ink = NSColor(calibratedRed: 0.10, green: 0.16, blue: 0.20, alpha: 1)
    let muted = NSColor(calibratedRed: 0.34, green: 0.39, blue: 0.42, alpha: 1)
    let teal = NSColor(calibratedRed: 0.08, green: 0.48, blue: 0.50, alpha: 1)
    let tealSoft = NSColor(calibratedRed: 0.86, green: 0.95, blue: 0.94, alpha: 1)
    let sand = NSColor(calibratedRed: 0.95, green: 0.90, blue: 0.80, alpha: 1)
    let coral = NSColor(calibratedRed: 0.92, green: 0.60, blue: 0.43, alpha: 1)
    let coralSoft = NSColor(calibratedRed: 0.98, green: 0.89, blue: 0.84, alpha: 1)
    let olive = NSColor(calibratedRed: 0.57, green: 0.64, blue: 0.30, alpha: 1)
    let oliveSoft = NSColor(calibratedRed: 0.92, green: 0.96, blue: 0.85, alpha: 1)
    let navy = NSColor(calibratedRed: 0.15, green: 0.24, blue: 0.39, alpha: 1)
    let navySoft = NSColor(calibratedRed: 0.87, green: 0.91, blue: 0.97, alpha: 1)
    let line = NSColor(calibratedRed: 0.84, green: 0.83, blue: 0.79, alpha: 1)
}

let theme = Theme()
let pageSize = CGSize(width: 1280, height: 720)
let outputURL = URL(fileURLWithPath: "/Users/sager/Documents/New project/brazil-smb-private-domain-playbook-v2.pdf")

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
    guard let ctx = NSGraphicsContext.current?.cgContext else { return }
    ctx.setFillColor(theme.bg.cgColor)
    ctx.fill(CGRect(origin: .zero, size: pageSize))
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
    style.lineSpacing = lineSpacing ?? size * 0.28
    let attr = NSAttributedString(
        string: string,
        attributes: [
            .font: font(size, weight),
            .paragraphStyle: style
        ]
    )
    return ceil(attr.boundingRect(with: CGSize(width: width, height: 10_000), options: [.usesLineFragmentOrigin, .usesFontLeading]).height)
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
    style.lineSpacing = lineSpacing ?? size * 0.28
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

func drawCircle(center: CGPoint, radius: CGFloat, fill: NSColor, stroke: NSColor? = nil, lineWidth: CGFloat = 2) {
    let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
    let path = NSBezierPath(ovalIn: flip(rect))
    fill.setFill()
    path.fill()
    if let stroke {
        stroke.setStroke()
        path.lineWidth = lineWidth
        path.stroke()
    }
}

func drawLine(from: CGPoint, to: CGPoint, color: NSColor = theme.line, width: CGFloat = 2, dashed: Bool = false) {
    guard let ctx = NSGraphicsContext.current?.cgContext else { return }
    ctx.saveGState()
    ctx.setStrokeColor(color.cgColor)
    ctx.setLineWidth(width)
    if dashed {
        ctx.setLineDash(phase: 0, lengths: [8, 8])
    }
    ctx.move(to: CGPoint(x: from.x, y: pageSize.height - from.y))
    ctx.addLine(to: CGPoint(x: to.x, y: pageSize.height - to.y))
    ctx.strokePath()
    ctx.restoreGState()
}

func drawArrow(from: CGPoint, to: CGPoint, color: NSColor, width: CGFloat = 3) {
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
        drawText("•", rect: CGRect(x: x, y: cursor, width: 18, height: size + 6), size: size, weight: .bold, color: color)
        let h = textHeight(item, width: width - 24, size: size)
        drawText(item, rect: CGRect(x: x + 24, y: cursor, width: width - 24, height: h + 4), size: size, color: color)
        cursor += h + gap
    }
}

func drawPill(_ text: String, x: CGFloat, y: CGFloat, fill: NSColor, textColor: NSColor = theme.ink, width: CGFloat) {
    drawRect(CGRect(x: x, y: y, width: width, height: 34), fill: fill, radius: 17)
    drawText(text, rect: CGRect(x: x, y: y + 7, width: width, height: 20), size: 15, weight: .semibold, color: textColor, align: .center, lineSpacing: 0)
}

func drawHeader(page: Int, title: String, subtitle: String) {
    drawText(String(format: "%02d", page), rect: CGRect(x: 56, y: 28, width: 42, height: 34), size: 22, weight: .bold, color: theme.coral)
    drawText(title, rect: CGRect(x: 106, y: 24, width: 700, height: 38), size: 30, weight: .bold)
    drawText(subtitle, rect: CGRect(x: 106, y: 64, width: 880, height: 24), size: 16, color: theme.muted)
    drawLine(from: CGPoint(x: 56, y: 96), to: CGPoint(x: 1224, y: 96), color: theme.line, width: 1.5)
}

func drawFooter(page: Int) {
    drawText("Brazil SMB Localized Private Domain Playbook", rect: CGRect(x: 56, y: 680, width: 380, height: 16), size: 12, color: theme.muted)
    drawText("\(page)", rect: CGRect(x: 1196, y: 676, width: 30, height: 18), size: 12, color: theme.muted, align: .right)
}

func drawCard(title: String, body: String, rect: CGRect, accent: NSColor, fill: NSColor = theme.panel, bodyColor: NSColor = theme.muted) {
    drawRect(rect, fill: fill, stroke: theme.line, radius: 24)
    drawRect(CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: 10), fill: accent, radius: 24)
    drawText(title, rect: CGRect(x: rect.minX + 20, y: rect.minY + 22, width: rect.width - 40, height: 28), size: 24, weight: .bold)
    let bodyH = textHeight(body, width: rect.width - 40, size: 16)
    drawText(body, rect: CGRect(x: rect.minX + 20, y: rect.minY + 58, width: rect.width - 40, height: bodyH + 4), size: 16, color: bodyColor)
}

var page = 1

// 1 Cover
beginPage()
drawRect(CGRect(x: 44, y: 40, width: 1192, height: 640), fill: NSColor(calibratedRed: 0.99, green: 0.98, blue: 0.96, alpha: 1), stroke: theme.line, radius: 36)
drawPill("Brazil SMB", x: 86, y: 82, fill: theme.sand, width: 134)
drawPill("Localized", x: 232, y: 82, fill: theme.tealSoft, width: 118)
drawPill("Playbook", x: 362, y: 82, fill: theme.coralSoft, width: 122)
drawText("巴西 SMB\n私域运营本地化手册", rect: CGRect(x: 86, y: 136, width: 470, height: 160), size: 46, weight: .bold, lineSpacing: 10)
drawText("这不是“通用私域模板”。\n这是把中国私域方法论抽象后，重新映射到巴西中小品牌真实经营环境里的版本。", rect: CGRect(x: 88, y: 330, width: 500, height: 86), size: 24, color: theme.muted)
drawText("核心本地化锚点：Instagram、WhatsApp、Pix、门店半径经营、LGPD。", rect: CGRect(x: 88, y: 444, width: 520, height: 28), size: 20, weight: .semibold, color: theme.ink)
drawRect(CGRect(x: 720, y: 142, width: 430, height: 430), fill: theme.panel, stroke: theme.line, radius: 30)
drawCircle(center: CGPoint(x: 850, y: 250), radius: 74, fill: theme.tealSoft, stroke: theme.teal)
drawCircle(center: CGPoint(x: 1014, y: 326), radius: 74, fill: theme.coralSoft, stroke: theme.coral)
drawCircle(center: CGPoint(x: 896, y: 468), radius: 74, fill: theme.oliveSoft, stroke: theme.olive)
drawText("发现", rect: CGRect(x: 810, y: 226, width: 80, height: 26), size: 26, weight: .bold, align: .center)
drawText("Instagram", rect: CGRect(x: 798, y: 260, width: 104, height: 22), size: 18, color: theme.muted, align: .center)
drawText("对话", rect: CGRect(x: 974, y: 302, width: 80, height: 26), size: 26, weight: .bold, align: .center)
drawText("WhatsApp", rect: CGRect(x: 960, y: 336, width: 108, height: 22), size: 18, color: theme.muted, align: .center)
drawText("成交", rect: CGRect(x: 856, y: 444, width: 80, height: 26), size: 26, weight: .bold, align: .center)
drawText("Pix / Loja / Site", rect: CGRect(x: 834, y: 478, width: 124, height: 22), size: 18, color: theme.muted, align: .center)
drawArrow(from: CGPoint(x: 910, y: 270), to: CGPoint(x: 954, y: 308), color: theme.teal)
drawArrow(from: CGPoint(x: 980, y: 396), to: CGPoint(x: 932, y: 442), color: theme.coral)
drawArrow(from: CGPoint(x: 860, y: 400), to: CGPoint(x: 846, y: 324), color: theme.olive)
drawRect(CGRect(x: 720, y: 590, width: 430, height: 42), fill: theme.sand, radius: 18)
drawText("目标：让“流量”变成可复购、可推荐、可管理的客户资产。", rect: CGRect(x: 740, y: 602, width: 390, height: 18), size: 16, weight: .semibold, align: .center)
endPage()
page += 1

// 2 Core logic
beginPage()
drawHeader(page: page, title: "先抽象底层逻辑", subtitle: "市场不同，但方法论的骨架一致")
drawRect(CGRect(x: 56, y: 126, width: 1168, height: 92), fill: theme.panel, stroke: theme.line, radius: 24)
drawText("从原文里真正能迁移的，不是某个平台名，而是这 6 个商业动作。", rect: CGRect(x: 84, y: 156, width: 1080, height: 28), size: 26, weight: .medium)
let baseLogic = [
    ("1. 先拿到可持续触达权", "不是一锤子买卖，而是得到客户允许，之后还能继续联系。", theme.teal),
    ("2. 把客户识别成“一个人”", "订单、门店、客服、社媒、会员不能各自为政。", theme.coral),
    ("3. 分层，而不是群发", "新客、老客、VIP、高潜客户，不应使用同样的话术和频率。", theme.olive),
    ("4. 服务先于促销", "先降低选择成本和信任成本，再谈折扣。", theme.navy),
    ("5. 复购比首购更值钱", "真正决定 ROI 的不是第一次成交，而是第二次、第三次。", theme.teal),
    ("6. 满意客户会带来新客户", "UGC、转介绍、KOC、本地口碑，都是增长飞轮。", theme.coral)
]
for (idx, item) in baseLogic.enumerated() {
    let x = 56 + CGFloat(idx % 3) * 394
    let y = 246 + CGFloat(idx / 3) * 184
    drawCard(title: item.0, body: item.1, rect: CGRect(x: x, y: y, width: 360, height: 152), accent: item.2)
}
drawRect(CGRect(x: 56, y: 624, width: 1168, height: 34), fill: theme.tealSoft, radius: 16)
drawText("结论：原方法论可以保留，但必须用巴西真实渠道、支付方式、门店场景和法规重新落地。", rect: CGRect(x: 76, y: 633, width: 1128, height: 16), size: 16, weight: .semibold)
drawFooter(page: page)
endPage()
page += 1

// 3 Brazil localization
beginPage()
drawHeader(page: page, title: "巴西本地化：必须重写的 5 个现实", subtitle: "这一页就是你要的“巴西信息层”")
let brazilItems = [
    ("1. 发现入口", "Instagram 仍是很多 SMB 的第一内容入口。用户先看 Reels / Stories，再决定要不要进入聊天。", theme.tealSoft, theme.teal),
    ("2. 对话入口", "WhatsApp 不是补充渠道，而是默认沟通和成交入口。客服、咨询、复购提醒都适合在这里发生。", theme.coralSoft, theme.coral),
    ("3. 支付入口", "Pix 极大缩短了从“想买”到“付款”的链路，特别适合聊天成交、补货、预约与门店提货。", theme.oliveSoft, theme.olive),
    ("4. 经营半径", "巴西 SMB 很多生意天然带有 bairro（社区半径）属性，所以门店、配送、自提、邻里关系都很重要。", theme.navySoft, theme.navy),
    ("5. 合规边界", "LGPD 要求品牌解释为什么收集数据、怎么使用、怎么退出。高亲密度渠道越要克制使用。", theme.sand, theme.coral)
]
for (idx, item) in brazilItems.enumerated() {
    let y = 128 + CGFloat(idx) * 108
    drawRect(CGRect(x: 76, y: y, width: 1128, height: 84), fill: item.2, stroke: theme.line, radius: 22)
    drawRect(CGRect(x: 76, y: y, width: 14, height: 84), fill: item.3, radius: 22)
    drawText(item.0, rect: CGRect(x: 110, y: y + 20, width: 280, height: 28), size: 24, weight: .bold)
    drawText(item.1, rect: CGRect(x: 386, y: y + 18, width: 780, height: 42), size: 17, color: theme.ink)
}
drawFooter(page: page)
endPage()
page += 1

// 4 Channel map
beginPage()
drawHeader(page: page, title: "巴西版私域渠道地图", subtitle: "不是单点平台，而是发现 → 聊天 → 支付 → 复购的组合")
let topBoxes = [
    (CGRect(x: 80, y: 178, width: 210, height: 110), "内容发现", "Instagram\nReels / Stories / Ads", theme.tealSoft),
    (CGRect(x: 342, y: 178, width: 210, height: 110), "转入聊天", "Click to WhatsApp\nDM / QR / Link", theme.coralSoft),
    (CGRect(x: 604, y: 178, width: 210, height: 110), "身份沉淀", "Cadastro / Telefone\nCRM / Loyalty", theme.oliveSoft),
    (CGRect(x: 866, y: 178, width: 210, height: 110), "成交承接", "Pix / Site\nLoja / Retirada", theme.navySoft)
]
for box in topBoxes {
    drawRect(box.0, fill: box.3, stroke: theme.line, radius: 24)
    drawText(box.1, rect: CGRect(x: box.0.minX + 16, y: box.0.minY + 18, width: box.0.width - 32, height: 24), size: 24, weight: .bold, align: .center)
    drawText(box.2, rect: CGRect(x: box.0.minX + 16, y: box.0.minY + 54, width: box.0.width - 32, height: 40), size: 18, color: theme.muted, align: .center)
}
drawArrow(from: CGPoint(x: 290, y: 234), to: CGPoint(x: 342, y: 234), color: theme.teal, width: 4)
drawArrow(from: CGPoint(x: 552, y: 234), to: CGPoint(x: 604, y: 234), color: theme.coral, width: 4)
drawArrow(from: CGPoint(x: 814, y: 234), to: CGPoint(x: 866, y: 234), color: theme.olive, width: 4)
drawRect(CGRect(x: 166, y: 382, width: 948, height: 194), fill: theme.panel, stroke: theme.line, radius: 30)
drawText("复购与推荐层", rect: CGRect(x: 204, y: 410, width: 220, height: 28), size: 28, weight: .bold)
let lowerCols = [
    ("复购", ["补货提醒", "VIP 日", "售后回访"]),
    ("服务", ["1:1 顾问", "预约提醒", "门店服务"]),
    ("内容", ["UGC", "本地口碑", "生活方式内容"]),
    ("推荐", ["Referral", "KOC", "社区裂变"])
]
for (idx, col) in lowerCols.enumerated() {
    let x = 220 + CGFloat(idx) * 214
    drawText(col.0, rect: CGRect(x: x, y: 462, width: 160, height: 24), size: 22, weight: .semibold, align: .center)
    drawBulletList(col.1, x: x, y: 500, width: 170, size: 17, color: theme.muted, gap: 8)
}
drawArrow(from: CGPoint(x: 970, y: 288), to: CGPoint(x: 970, y: 382), color: theme.coral, width: 4)
drawFooter(page: page)
endPage()
page += 1

// 5 Vertical mapping
beginPage()
drawHeader(page: page, title: "按巴西 SMB 业态重写", subtitle: "同样是私域，不同行业的重点完全不同")
let verticals = [
    ("Beleza / 美妆", ["Instagram 先种草", "WhatsApp 做肤质与预算咨询", "Pix 缩短成交"], theme.coralSoft, theme.coral),
    ("Mini mercado / 食品零售", ["门店收银台强留资", "做 bairro 清单和到货提醒", "补货与家庭套餐驱动复购"], theme.oliveSoft, theme.olive),
    ("Moda / 服饰", ["Stories 上新", "WhatsApp 发尺码与搭配建议", "门店试穿与自提"], theme.tealSoft, theme.teal),
    ("Clínica / 服务业", ["先做预约与问诊", "顾问式 1:1", "复诊 / 续费 / 追加服务"], theme.navySoft, theme.navy)
]
for (idx, v) in verticals.enumerated() {
    let x = 64 + CGFloat(idx % 2) * 586
    let y = 138 + CGFloat(idx / 2) * 246
    drawRect(CGRect(x: x, y: y, width: 556, height: 210), fill: v.3, stroke: theme.line, radius: 26)
    drawText(v.0, rect: CGRect(x: x + 24, y: y + 24, width: 260, height: 30), size: 30, weight: .bold)
    drawBulletList(v.1, x: x + 24, y: y + 72, width: 500, size: 19, gap: 12)
    drawRect(CGRect(x: x + 420, y: y + 22, width: 110, height: 34), fill: theme.panel, stroke: v.3, lineWidth: 2, radius: 17)
    drawText("Brazil fit", rect: CGRect(x: x + 420, y: y + 29, width: 110, height: 18), size: 14, weight: .semibold, align: .center)
}
drawFooter(page: page)
endPage()
page += 1

// 6 Operating table
beginPage()
drawHeader(page: page, title: "运营动作表", subtitle: "把客户旅程翻译成巴西品牌团队每天真的会做的事")
drawRect(CGRect(x: 56, y: 132, width: 1168, height: 510), fill: theme.panel, stroke: theme.line, radius: 26)
let colXs: [CGFloat] = [72, 310, 562, 814, 1048]
let widths: [CGFloat] = [200, 220, 220, 200, 150]
let headers = ["阶段", "巴西主触点", "核心动作", "目标", "KPI"]
for i in 0..<headers.count {
    drawRect(CGRect(x: colXs[i], y: 156, width: widths[i], height: 52), fill: i == 0 ? theme.sand : theme.tealSoft, radius: 16)
    drawText(headers[i], rect: CGRect(x: colXs[i], y: 171, width: widths[i], height: 20), size: 18, weight: .bold, align: .center)
}
let rows = [
    ["发现", "Instagram / Ads / Loja", "Reels、Stories、门店 QR、Click to WhatsApp", "把流量导入可触达名单", "Opt-in rate"],
    ["识别", "WhatsApp / Cadastro / CRM", "收手机号、偏好、门店、历史订单", "知道客户是谁", "绑定率"],
    ["激活", "Broadcast / 1:1 / Group", "欢迎语、内容节律、问卷、顾问建议", "建立回复习惯", "7日活跃率"],
    ["成交", "Pix / Site / Loja", "套组、补货、预约、到店自提", "缩短决策链路", "转化率"],
    ["复购", "Loyalty / WhatsApp / Loja", "会员日、提醒、售后、推荐", "提高 LTV", "30/60/90日复购"]
]
for (idx, row) in rows.enumerated() {
    let y = 220 + CGFloat(idx) * 78
    drawLine(from: CGPoint(x: 72, y: y), to: CGPoint(x: 1188, y: y), color: theme.line, width: 1)
    for i in 0..<row.count {
        drawText(row[i], rect: CGRect(x: colXs[i] + 10, y: y + 16, width: widths[i] - 20, height: 46), size: i == 0 ? 20 : 16, weight: i == 0 ? .semibold : .regular, color: i == 0 ? theme.ink : theme.muted, align: i == 0 ? .center : .left)
    }
}
drawRect(CGRect(x: 56, y: 662, width: 1168, height: 32), fill: theme.tealSoft, radius: 16)
drawText("巴西版私域最常见错误：把 Instagram 当成交工具，或者把 WhatsApp 只当客服工具。真正有效的是两者分工协同。", rect: CGRect(x: 74, y: 670, width: 1128, height: 16), size: 15, weight: .semibold)
drawFooter(page: page)
endPage()
page += 1

// 7 Case 1 Beauty
beginPage()
drawHeader(page: page, title: "案例 1：巴西社区美妆品牌", subtitle: "让本地化不再只是“平台替换”，而是经营逻辑的替换")
drawRect(CGRect(x: 66, y: 136, width: 286, height: 474), fill: theme.coralSoft, stroke: theme.line, radius: 26)
drawText("场景", rect: CGRect(x: 92, y: 166, width: 90, height: 24), size: 26, weight: .bold)
drawBulletList([
    "Sao Paulo 社区美妆店",
    "Instagram 有内容，但 DM 很散",
    "顾客会问：肤质、预算、色号",
    "问题：咨询很多，复购弱"], x: 92, y: 214, width: 220, size: 20, gap: 14)
drawRect(CGRect(x: 386, y: 136, width: 386, height: 474), fill: theme.panel, stroke: theme.line, radius: 26)
drawText("巴西版解法", rect: CGRect(x: 412, y: 166, width: 180, height: 24), size: 26, weight: .bold)
drawBulletList([
    "Reels 用前后对比和肤质教学引流。",
    "点击聊天后先收集：肤质、预算、购买频率。",
    "新客进入广播层；买过的进入会员层；高价值用户进入 1:1 VIP。",
    "会员日不做纯打折，而做“本周肤质清单 + Pix 快速下单”。"], x: 412, y: 214, width: 330, size: 18, gap: 12)
drawRect(CGRect(x: 806, y: 136, width: 408, height: 474), fill: theme.tealSoft, stroke: theme.line, radius: 26)
drawText("你能看到的巴西化变化", rect: CGRect(x: 832, y: 166, width: 300, height: 24), size: 26, weight: .bold)
drawBulletList([
    "从“IG 内容运营”升级成“IG 发现 + WhatsApp 成交”。",
    "对话会更像顾问，而不是客服。",
    "Pix 让聊天中的意向更快落单。",
    "本地门店可承接试色、取货、复购和评价。"], x: 832, y: 214, width: 340, size: 18, gap: 12)
drawRect(CGRect(x: 386, y: 628, width: 828, height: 40), fill: theme.sand, radius: 18)
drawText("一句话：这不是“把微信换成 WhatsApp”，而是把“内容获客”改造成“内容 + 聊天 + 支付 + 门店”的闭环。", rect: CGRect(x: 408, y: 639, width: 784, height: 18), size: 16, weight: .semibold)
drawFooter(page: page)
endPage()
page += 1

// 8 Case 2 Retail
beginPage()
drawHeader(page: page, title: "案例 2：bairro 社区零售 / mini mercado", subtitle: "巴西本地化最强的地方，恰恰是“社区半径经营”")
drawRect(CGRect(x: 56, y: 140, width: 1168, height: 188), fill: theme.oliveSoft, stroke: theme.line, radius: 26)
drawText("为什么这个案例更像巴西？", rect: CGRect(x: 84, y: 170, width: 300, height: 24), size: 28, weight: .bold)
drawBulletList([
    "因为很多社区零售生意天然靠 bairro（社区）关系、门店距离、当日到货和即时购买。",
    "客户在店内只停留几分钟，但真实需求发生在下班后、周末前、家庭采购前。",
    "所以 WhatsApp + Pix + loja física 是极强组合。"], x: 84, y: 214, width: 1080, size: 20, gap: 12)
let flowBoxes = [
    ("门店收银", "邀请加入会员清单", theme.sand),
    ("WhatsApp", "发今日到货 / 家庭套餐", theme.tealSoft),
    ("Pix", "聊天内快速支付", theme.coralSoft),
    ("到店 / 配送", "自提、门店加购、邻里复购", theme.navySoft)
]
for (idx, box) in flowBoxes.enumerated() {
    let x = 84 + CGFloat(idx) * 286
    drawRect(CGRect(x: x, y: 384, width: 240, height: 148), fill: box.2, stroke: theme.line, radius: 24)
    drawText(box.0, rect: CGRect(x: x + 18, y: 412, width: 204, height: 26), size: 26, weight: .bold, align: .center)
    drawText(box.1, rect: CGRect(x: x + 22, y: 454, width: 196, height: 44), size: 18, color: theme.muted, align: .center)
    if idx < flowBoxes.count - 1 {
        drawArrow(from: CGPoint(x: x + 240, y: 458), to: CGPoint(x: x + 286, y: 458), color: theme.coral, width: 4)
    }
}
drawRect(CGRect(x: 84, y: 572, width: 540, height: 74), fill: theme.panel, stroke: theme.line, radius: 22)
drawText("最适合发什么？", rect: CGRect(x: 110, y: 594, width: 160, height: 22), size: 24, weight: .bold)
drawText("今日到货、周末家庭清单、补货提醒、限定组合、门店活动。", rect: CGRect(x: 286, y: 595, width: 300, height: 20), size: 17, color: theme.muted)
drawRect(CGRect(x: 652, y: 572, width: 540, height: 74), fill: theme.panel, stroke: theme.line, radius: 22)
drawText("最不该发什么？", rect: CGRect(x: 678, y: 594, width: 180, height: 22), size: 24, weight: .bold)
drawText("无差别群发、纯折扣噪音、与本地门店和家庭场景无关的内容。", rect: CGRect(x: 864, y: 595, width: 294, height: 20), size: 17, color: theme.muted)
drawFooter(page: page)
endPage()
page += 1

// 9 Roadmap
beginPage()
drawHeader(page: page, title: "90 天落地路线", subtitle: "更聚焦、更少页、更直接")
let roadmap = [
    ("Day 1-30", "先搭底座", ["确定手机号 / 会员 ID", "梳理 5 个留资触点", "搭欢迎语、退出机制、LGPD 告知"], theme.tealSoft, theme.teal),
    ("Day 31-60", "跑出节律", ["固定每周内容节奏", "开始 1:1 顾问跟进", "用 Pix/门店活动做第一次波峰"], theme.coralSoft, theme.coral),
    ("Day 61-90", "做复购飞轮", ["启动会员日", "补货提醒", "转介绍与 UGC"], theme.oliveSoft, theme.olive)
]
for (idx, item) in roadmap.enumerated() {
    let x = 72 + CGFloat(idx) * 392
    drawRect(CGRect(x: x, y: 186, width: 344, height: 334), fill: item.3, stroke: theme.line, radius: 28)
    drawText(item.0, rect: CGRect(x: x + 24, y: 216, width: 296, height: 34), size: 38, weight: .bold)
    drawText(item.1, rect: CGRect(x: x + 24, y: 270, width: 240, height: 28), size: 28, weight: .bold)
    drawBulletList(item.2, x: x + 24, y: 322, width: 286, size: 20, gap: 14)
    if idx < roadmap.count - 1 {
        drawArrow(from: CGPoint(x: x + 344, y: 354), to: CGPoint(x: x + 392, y: 354), color: item.4, width: 4)
    }
}
drawRect(CGRect(x: 72, y: 560, width: 1144, height: 84), fill: theme.panel, stroke: theme.line, radius: 24)
drawText("建议先看这 4 个 KPI", rect: CGRect(x: 100, y: 586, width: 220, height: 24), size: 24, weight: .bold)
drawText("1. 留资率    2. 7 日回复 / 活跃率    3. 聊天到成交率    4. 30 日复购率", rect: CGRect(x: 346, y: 588, width: 720, height: 20), size: 18, weight: .medium)
drawFooter(page: page)
endPage()
page += 1

// 10 Scripts and sources
beginPage()
drawHeader(page: page, title: "葡语话术模板 + 本地化依据", subtitle: "最后一页只放最实用的内容")
let templates: [(String, String, NSColor)] = [
    ("拉新邀请", "Oi! Criamos uma lista VIP para clientes que querem novidades, reposição e vantagens sem spam. Quer entrar?", theme.teal),
    ("进线欢迎", "Me conta seu objetivo e sua faixa de preço. Assim eu te mando só o que realmente faz sentido.", theme.coral),
    ("复购提醒", "Seu último produto já deve estar acabando. Quer repetir o pedido via Pix ou ver uma opção nova?", theme.olive),
    ("门店承接", "Se preferir, eu separo na loja para retirada hoje.", theme.navy)
]
for (idx, t) in templates.enumerated() {
    let x = 66 + CGFloat(idx % 2) * 584
    let y = 134 + CGFloat(idx / 2) * 132
    drawCard(title: t.0, body: t.1, rect: CGRect(x: x, y: y, width: 554, height: 108), accent: t.2)
}
drawRect(CGRect(x: 66, y: 438, width: 1148, height: 188), fill: theme.sand, radius: 28)
drawText("本地化依据为什么这样写？", rect: CGRect(x: 94, y: 468, width: 280, height: 26), size: 28, weight: .bold)
drawBulletList([
    "Sebrae 面向巴西小企业的培训与文章长期把 WhatsApp Business + Instagram 作为常见数字销售组合。",
    "Meta 官方 2025 年更新继续强调：WhatsApp 商业消息要建立在 opt-in、相关性和用户可控之上。",
    "巴西央行明确将 Pix 定义为即时支付基础设施，这让聊天成交在巴西比很多市场更容易闭环。",
    "LGPD 要求品牌清楚说明数据目的、使用方式和退出机制，因此私域不能只是“多发消息”。"], x: 94, y: 516, width: 1060, size: 18, gap: 12)
drawFooter(page: page)
endPage()

let pdf = PDFDocument()
for (index, image) in pageImages.enumerated() {
    if let page = PDFPage(image: image) {
        pdf.insert(page, at: index)
    }
}

guard pdf.write(to: outputURL) else {
    fatalError("Failed to write PDF to \(outputURL.path)")
}

print(outputURL.path)
