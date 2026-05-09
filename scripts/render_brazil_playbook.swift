import Foundation
import AppKit
import CoreGraphics
import PDFKit

struct Theme {
    let bg = NSColor(calibratedRed: 0.97, green: 0.96, blue: 0.93, alpha: 1)
    let panel = NSColor.white
    let ink = NSColor(calibratedRed: 0.08, green: 0.14, blue: 0.18, alpha: 1)
    let muted = NSColor(calibratedRed: 0.31, green: 0.38, blue: 0.42, alpha: 1)
    let teal = NSColor(calibratedRed: 0.10, green: 0.45, blue: 0.46, alpha: 1)
    let tealSoft = NSColor(calibratedRed: 0.85, green: 0.94, blue: 0.92, alpha: 1)
    let sand = NSColor(calibratedRed: 0.95, green: 0.90, blue: 0.79, alpha: 1)
    let coral = NSColor(calibratedRed: 0.91, green: 0.58, blue: 0.43, alpha: 1)
    let coralSoft = NSColor(calibratedRed: 0.98, green: 0.88, blue: 0.83, alpha: 1)
    let olive = NSColor(calibratedRed: 0.57, green: 0.63, blue: 0.31, alpha: 1)
    let oliveSoft = NSColor(calibratedRed: 0.92, green: 0.95, blue: 0.84, alpha: 1)
    let line = NSColor(calibratedRed: 0.84, green: 0.83, blue: 0.78, alpha: 1)
}

let theme = Theme()
let pageSize = CGSize(width: 1280, height: 720)
let outputURL = URL(fileURLWithPath: "/Users/sager/Documents/New project/brazil-smb-private-domain-playbook.pdf")
var pageImages: [NSImage] = []
var currentPageImage: NSImage?

func flip(_ rect: CGRect) -> CGRect {
    CGRect(x: rect.minX, y: pageSize.height - rect.minY - rect.height, width: rect.width, height: rect.height)
}

func font(_ size: CGFloat, _ weight: NSFont.Weight = .regular) -> NSFont {
    NSFont.systemFont(ofSize: size, weight: weight)
}

func textHeight(_ string: String, width: CGFloat, size: CGFloat, weight: NSFont.Weight = .regular, lineSpacing: CGFloat? = nil) -> CGFloat {
    let paragraph = NSMutableParagraphStyle()
    paragraph.lineSpacing = lineSpacing ?? size * 0.32
    let attr = NSAttributedString(
        string: string,
        attributes: [
            .font: font(size, weight),
            .paragraphStyle: paragraph
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
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = align
    paragraph.lineSpacing = lineSpacing ?? size * 0.32
    let attr = NSAttributedString(
        string: string,
        attributes: [
            .font: font(size, weight),
            .foregroundColor: color,
            .paragraphStyle: paragraph
        ]
    )
    attr.draw(with: flip(rect), options: [.usesLineFragmentOrigin, .usesFontLeading])
}

func drawRect(_ rect: CGRect, fill: NSColor, stroke: NSColor? = nil, lineWidth: CGFloat = 1, radius: CGFloat = 20) {
    let path = NSBezierPath(roundedRect: flip(rect), xRadius: radius, yRadius: radius)
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

func drawArrow(from: CGPoint, to: CGPoint, color: NSColor = theme.teal, width: CGFloat = 3) {
    drawLine(from: from, to: to, color: color, width: width)
    let angle = atan2(to.y - from.y, to.x - from.x)
    let len: CGFloat = 12
    let wing: CGFloat = .pi / 6
    let p1 = CGPoint(x: to.x - len * cos(angle - wing), y: to.y - len * sin(angle - wing))
    let p2 = CGPoint(x: to.x - len * cos(angle + wing), y: to.y - len * sin(angle + wing))
    drawLine(from: to, to: p1, color: color, width: width)
    drawLine(from: to, to: p2, color: color, width: width)
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

func pill(_ label: String, x: CGFloat, y: CGFloat, color: NSColor, width: CGFloat? = nil) {
    let w = width ?? max(120, CGFloat(label.count) * 18 + 32)
    drawRect(CGRect(x: x, y: y, width: w, height: 34), fill: color, radius: 17)
    drawText(label, rect: CGRect(x: x + 12, y: y + 7, width: w - 24, height: 22), size: 15, weight: .semibold, color: theme.ink, align: .center, lineSpacing: 0)
}

func bulletList(_ items: [String], x: CGFloat, y: CGFloat, width: CGFloat, size: CGFloat = 19, color: NSColor = theme.ink, gap: CGFloat = 12) {
    var cursor = y
    for item in items {
        drawText("•", rect: CGRect(x: x, y: cursor, width: 18, height: size + 8), size: size, weight: .bold, color: color)
        let h = textHeight(item, width: width - 24, size: size)
        drawText(item, rect: CGRect(x: x + 22, y: cursor, width: width - 24, height: h + 6), size: size, color: color)
        cursor += h + gap
    }
}

func beginCanvas() {
    let image = NSImage(size: pageSize)
    image.lockFocus()
    currentPageImage = image
    guard let ctx = NSGraphicsContext.current?.cgContext else { return }
    ctx.setFillColor(theme.bg.cgColor)
    ctx.fill(CGRect(origin: .zero, size: pageSize))
}

func endCanvas() {
    currentPageImage?.unlockFocus()
    if let image = currentPageImage {
        pageImages.append(image)
    }
    currentPageImage = nil
}

func startPage(number: Int, title: String, subtitle: String) {
    beginCanvas()
    drawText(String(format: "%02d", number), rect: CGRect(x: 58, y: 36, width: 44, height: 34), size: 22, weight: .bold, color: theme.coral)
    drawText(title, rect: CGRect(x: 110, y: 30, width: 780, height: 38), size: 28, weight: .bold)
    drawText(subtitle, rect: CGRect(x: 110, y: 68, width: 880, height: 28), size: 16, color: theme.muted)
    drawLine(from: CGPoint(x: 58, y: 100), to: CGPoint(x: 1222, y: 100), color: theme.line, width: 1.5)
}

func finishPage(number: Int) {
    drawText("Brazil SMB Private Domain Playbook", rect: CGRect(x: 58, y: 680, width: 300, height: 18), size: 12, color: theme.muted)
    drawText("\(number)", rect: CGRect(x: 1180, y: 676, width: 40, height: 18), size: 12, color: theme.muted, align: .right)
    endCanvas()
}

func drawCard(title: String, body: String, rect: CGRect, fill: NSColor = theme.panel, accent: NSColor = theme.teal) {
    drawRect(rect, fill: fill, stroke: theme.line, radius: 24)
    drawRect(CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: 10), fill: accent, radius: 24)
    drawText(title, rect: CGRect(x: rect.minX + 20, y: rect.minY + 24, width: rect.width - 40, height: 32), size: 22, weight: .bold)
    let h = textHeight(body, width: rect.width - 40, size: 16)
    drawText(body, rect: CGRect(x: rect.minX + 20, y: rect.minY + 66, width: rect.width - 40, height: h + 8), size: 16, color: theme.muted)
}

var page = 1

// Page 1
beginCanvas()

drawRect(CGRect(x: 54, y: 48, width: 1172, height: 624), fill: NSColor(calibratedRed: 0.99, green: 0.98, blue: 0.96, alpha: 1), stroke: theme.line, radius: 36)
pill("Brazil SMB", x: 88, y: 84, color: theme.sand, width: 136)
pill("Private Domain", x: 236, y: 84, color: theme.tealSoft, width: 188)
pill("Playbook", x: 438, y: 84, color: theme.coralSoft, width: 132)

drawText("巴西 SMB\n私域运营图解手册", rect: CGRect(x: 90, y: 144, width: 470, height: 180), size: 42, weight: .bold, lineSpacing: 12)
drawText("将“关系沉淀 + 分层服务 + 数据闭环 + 复购增长”重写为适合巴西中小品牌的经营系统。\n默认场景：Instagram 发现、WhatsApp 对话、门店 / 站点 / CRM / Pix 承接。", rect: CGRect(x: 92, y: 350, width: 470, height: 140), size: 20, color: theme.muted)

drawCircle(center: CGPoint(x: 875, y: 226), radius: 86, fill: theme.tealSoft, stroke: theme.teal)
drawCircle(center: CGPoint(x: 1018, y: 348), radius: 86, fill: theme.coralSoft, stroke: theme.coral)
drawCircle(center: CGPoint(x: 864, y: 474), radius: 86, fill: theme.oliveSoft, stroke: theme.olive)
drawText("发现", rect: CGRect(x: 825, y: 196, width: 100, height: 30), size: 26, weight: .bold, align: .center)
drawText("Instagram\nReels / Stories", rect: CGRect(x: 812, y: 230, width: 126, height: 50), size: 17, color: theme.muted, align: .center)
drawText("对话", rect: CGRect(x: 968, y: 318, width: 100, height: 30), size: 26, weight: .bold, align: .center)
drawText("WhatsApp\n1:1 / Groups", rect: CGRect(x: 955, y: 352, width: 126, height: 50), size: 17, color: theme.muted, align: .center)
drawText("复购", rect: CGRect(x: 814, y: 444, width: 100, height: 30), size: 26, weight: .bold, align: .center)
drawText("Loyalty / CRM\nPix / Store", rect: CGRect(x: 801, y: 478, width: 126, height: 50), size: 17, color: theme.muted, align: .center)
drawArrow(from: CGPoint(x: 940, y: 262), to: CGPoint(x: 986, y: 312), color: theme.teal)
drawArrow(from: CGPoint(x: 987, y: 408), to: CGPoint(x: 914, y: 450), color: theme.coral)
drawArrow(from: CGPoint(x: 818, y: 414), to: CGPoint(x: 812, y: 298), color: theme.olive)

drawRect(CGRect(x: 690, y: 562, width: 450, height: 70), fill: theme.panel, stroke: theme.line, radius: 20)
drawText("一句话定义：把一次性流量，变成可持续触达、可服务、可复购、可推荐的客户资产。", rect: CGRect(x: 714, y: 584, width: 404, height: 34), size: 19, weight: .semibold)

drawText("为巴西中小品牌重写 | 去本土平台依赖 | 包含流程图、案例、模板", rect: CGRect(x: 88, y: 612, width: 520, height: 24), size: 15, color: theme.muted)
endCanvas()
page += 1

// Page 2
startPage(number: page, title: "底层逻辑", subtitle: "先抽象方法，再落到巴西 SMB 品牌能执行的操作系统")
drawRect(CGRect(x: 58, y: 126, width: 1164, height: 110), fill: theme.panel, stroke: theme.line, radius: 26)
drawText("私域不是“另一个营销渠道”，而是品牌直连客户后的经营方式。它解决的不是曝光，而是四件事：拿到许可、识别用户、持续服务、驱动复购。市场不同，底层逻辑一致；差别只在触点、支付、数据、法规与消费习惯。", rect: CGRect(x: 86, y: 154, width: 1108, height: 64), size: 22, weight: .medium)

let logicCards: [(String, String, NSColor)] = [
    ("1. 先拿到许可", "用户愿意留下 WhatsApp、邮箱或会员身份，后续触达才具备商业价值。", theme.teal),
    ("2. 统一成“一个人”", "把门店、站点、社媒、客服和订单连到同一个客户视图，而不是散落在线索表里。", theme.coral),
    ("3. 分层而非群发", "不同价值、不同需求、不同阶段的客户，必须用不同节奏和权益沟通。", theme.olive),
    ("4. 服务先于促销", "先解决选择成本、信息不对称、使用场景与信任问题，再谈折扣和转化。", theme.teal),
    ("5. 满意客户会带来新客户", "UGC、转介绍、KOC 与社区气氛，本质上都是增长杠杆。", theme.coral)
]
for (index, item) in logicCards.enumerated() {
    let col = index % 3
    let row = index / 3
    let x = 58 + CGFloat(col) * 390
    let y = 270 + CGFloat(row) * 168
    let width: CGFloat = row == 1 && col == 2 ? 0 : 360
    if width > 0 {
        drawCard(title: item.0, body: item.1, rect: CGRect(x: x, y: y, width: width, height: 140), accent: item.2)
    }
}
drawRect(CGRect(x: 58, y: 606, width: 1164, height: 54), fill: theme.sand, radius: 20)
drawText("巴西版翻译原则：不用单一超级 App 解释一切，而是用 Instagram 做发现、WhatsApp 做关系、CRM 与 Pix 做承接、门店与站点做履约。", rect: CGRect(x: 82, y: 621, width: 1110, height: 24), size: 18, weight: .semibold)
finishPage(number: page)
page += 1

// Page 3
startPage(number: page, title: "增长闭环", subtitle: "把“流量”改写为从发现到推荐的循环，而不是一次性 campaign")
let nodes = [
    ("发现", "内容 / 门店 / 广告"),
    ("留资", "点击聊天 / 扫码 / 会员"),
    ("识别", "手机号 / 会员 / 订单"),
    ("分层", "新客 / 老客 / VIP / KOC"),
    ("激活", "内容 / 服务 / 权益"),
    ("成交", "Pix / 站点 / 门店"),
    ("复购推荐", "会员日 / UGC / Referral")
]
for (i, node) in nodes.enumerated() {
    let x = 68 + CGFloat(i) * 166
    drawRect(CGRect(x: x, y: 278, width: 150, height: 124), fill: i % 2 == 0 ? theme.tealSoft : theme.coralSoft, stroke: theme.line, radius: 26)
    drawText(node.0, rect: CGRect(x: x + 12, y: 300, width: 126, height: 28), size: 24, weight: .bold, align: .center)
    drawText(node.1, rect: CGRect(x: x + 12, y: 336, width: 126, height: 46), size: 15, color: theme.muted, align: .center)
    if i < nodes.count - 1 {
        drawArrow(from: CGPoint(x: x + 150, y: 340), to: CGPoint(x: x + 166, y: 340), color: theme.teal)
    }
}
drawArrow(from: CGPoint(x: 1146, y: 410), to: CGPoint(x: 1146, y: 506), color: theme.olive)
drawArrow(from: CGPoint(x: 1146, y: 506), to: CGPoint(x: 142, y: 506), color: theme.olive)
drawArrow(from: CGPoint(x: 142, y: 506), to: CGPoint(x: 142, y: 410), color: theme.olive)
drawText("闭环不是“加群就完事”。真正的经营动作发生在中段：身份识别、分层服务、转化承接与复购设计。", rect: CGRect(x: 98, y: 166, width: 1080, height: 34), size: 22, weight: .medium)
bulletList([
    "获客看的是 opt-in 率，而不是纯粉丝数。",
    "激活看的是回复、点击、参与和问卷，不只是阅读量。",
    "成交必须看辅助收入，不要只看最后点击归因。",
    "复购与推荐决定了长期 ROI，也是 SMB 最容易被忽略的部分。"], x: 88, y: 564, width: 540, size: 18)
drawCard(title: "一句实操话", body: "如果一个动作无法让客户“更容易被再次联系、更容易被更懂地服务、更容易下第二单”，它就不是私域核心动作。", rect: CGRect(x: 702, y: 536, width: 490, height: 118), accent: theme.olive)
finishPage(number: page)
page += 1

// Page 4
startPage(number: page, title: "巴西触点映射", subtitle: "默认组合：Instagram 发现，WhatsApp 对话，门店 / 站点 / CRM / Pix 承接")
let columns: [(String, [String], NSColor)] = [
    ("发现", ["Instagram Reels / Stories", "本地广告与创作者合作", "门店橱窗、收银台、活动 QR", "Google / 本地搜索入口"], theme.teal),
    ("沉淀", ["Click-to-WhatsApp", "WhatsApp Business Catalog", "结账页留资 / 会员加入", "包裹卡、电子小票、邮件订阅"], theme.coral),
    ("运营", ["WhatsApp 1:1 与分组广播", "兴趣群 / 会员群 / VIP 服务", "CRM、邮件、SMS 再触达", "会员日、积分、售后关怀"], theme.olive),
    ("成交", ["Pix / 站点支付 / 门店自提", "顾问式聊天成交", "补货提醒与套组", "转介绍、UGC 与 KOC"], theme.teal)
]
for (index, col) in columns.enumerated() {
    let x = 58 + CGFloat(index) * 292
    drawRect(CGRect(x: x, y: 148, width: 270, height: 402), fill: theme.panel, stroke: theme.line, radius: 26)
    drawRect(CGRect(x: x, y: 148, width: 270, height: 12), fill: col.2, radius: 26)
    drawText(col.0, rect: CGRect(x: x + 20, y: 178, width: 230, height: 30), size: 26, weight: .bold)
    bulletList(col.1, x: x + 20, y: 226, width: 228, size: 16, color: theme.muted, gap: 10)
}
drawRect(CGRect(x: 58, y: 580, width: 560, height: 76), fill: theme.tealSoft, radius: 22)
drawText("为什么这样组合？\n在巴西，多数 SMB 需要“先被看见，再进入聊天，再完成支付与履约”。因此不要把发现、对话、成交硬塞进一个单点渠道。", rect: CGRect(x: 82, y: 596, width: 514, height: 46), size: 17, weight: .medium)
drawRect(CGRect(x: 650, y: 580, width: 572, height: 76), fill: theme.coralSoft, radius: 22)
drawText("执行提示：\n把每个门店、活动、DM、客服和包裹都当成留资入口；把每次购买、咨询、评价和售后都当成下一次触达的理由。", rect: CGRect(x: 674, y: 596, width: 526, height: 46), size: 17, weight: .medium)
finishPage(number: page)
page += 1

// Page 5
startPage(number: page, title: "分层服务", subtitle: "不是所有客户都要进同一种群，也不是所有客户都值得同样的沟通频率")
drawText("推荐三层结构", rect: CGRect(x: 86, y: 138, width: 260, height: 28), size: 24, weight: .bold)
let pyramid = [
    (CGRect(x: 230, y: 212, width: 380, height: 92), "1:1 VIP / Concierge", "高客单、高频或高潜客户。专属顾问、预约提醒、隐藏福利、优先发售。", theme.coralSoft),
    (CGRect(x: 170, y: 326, width: 500, height: 102), "会员群 / 兴趣群", "中价值客户。根据品类、门店、兴趣、消费梯度建立群；核心目标是活跃与复购。", theme.tealSoft),
    (CGRect(x: 110, y: 450, width: 620, height: 112), "广播层 / 订阅层", "所有已留资客户。主要做上新通知、内容种草、会员权益、补货提醒与轻促销。", theme.oliveSoft)
]
for item in pyramid {
    drawRect(item.0, fill: item.3, stroke: theme.line, radius: 24)
    drawText(item.1, rect: CGRect(x: item.0.minX + 18, y: item.0.minY + 18, width: item.0.width - 36, height: 28), size: 24, weight: .bold)
    drawText(item.2, rect: CGRect(x: item.0.minX + 18, y: item.0.minY + 52, width: item.0.width - 36, height: 46), size: 16, color: theme.muted)
}
drawArrow(from: CGPoint(x: 770, y: 260), to: CGPoint(x: 840, y: 260), color: theme.coral)
drawArrow(from: CGPoint(x: 770, y: 374), to: CGPoint(x: 840, y: 374), color: theme.teal)
drawArrow(from: CGPoint(x: 770, y: 508), to: CGPoint(x: 840, y: 508), color: theme.olive)
let layerCards = [
    ("进入规则", "首次购买、留资来源、门店、消费频次、最近互动、商品偏好。"),
    ("服务承诺", "告知型信息给广播层；解释型内容给会员层；顾问式建议给 VIP。"),
    ("关键指标", "广播层看打开 / 回复；会员层看活跃 / 复购；VIP 看 ARPU / 保留率 / 口碑贡献。")
]
for (idx, card) in layerCards.enumerated() {
    drawCard(title: card.0, body: card.1, rect: CGRect(x: 852, y: 196 + CGFloat(idx) * 132, width: 330, height: 112), accent: idx == 0 ? theme.coral : (idx == 1 ? theme.teal : theme.olive))
}
drawRect(CGRect(x: 58, y: 612, width: 1164, height: 44), fill: theme.panel, stroke: theme.line, radius: 18)
drawText("最小可行版本：即使只有 1 家店、1 个运营，也至少要区分“刚留资的新客”“购买过的老客”“愿意互动的高价值客户”三类。", rect: CGRect(x: 82, y: 625, width: 1120, height: 20), size: 17, weight: .medium)
finishPage(number: page)
page += 1

// Page 6
startPage(number: page, title: "招募场景", subtitle: "把线下和线上所有高意图时刻都变成 opt-in 入口")
let scenes = [
    ("门店收银台", "最强动作", "扫码加入俱乐部，今天用 Pix 立减或得积分。"),
    ("电子小票 / 包裹卡", "售后顺手留资", "拿到补货提醒、会员价和新品试用名单。"),
    ("Instagram DM", "内容转对话", "回复关键词进入 WhatsApp，发送你的肤质 / 尺寸 / 偏好。"),
    ("客服与售后", "服务转沉淀", "问题解决后邀请进入会员层，而不是结束于一次工单。"),
    ("活动 / 快闪", "短期集中获客", "活动群要有明确周期，活动后筛出高意向客户进入长线层。"),
    ("老带新", "满意客户裂变", "不是纯抽奖，推荐成功后双方拿到可消费的权益。")
]
for (index, scene) in scenes.enumerated() {
    let x = 58 + CGFloat(index % 3) * 388
    let y = 148 + CGFloat(index / 3) * 224
    drawRect(CGRect(x: x, y: y, width: 360, height: 188), fill: theme.panel, stroke: theme.line, radius: 24)
    pill(scene.1, x: x + 18, y: y + 18, color: index % 2 == 0 ? theme.tealSoft : theme.coralSoft, width: 124)
    drawText(scene.0, rect: CGRect(x: x + 18, y: y + 62, width: 320, height: 30), size: 24, weight: .bold)
    drawText(scene.2, rect: CGRect(x: x + 18, y: y + 102, width: 320, height: 58), size: 16, color: theme.muted)
}
drawRect(CGRect(x: 58, y: 606, width: 560, height: 50), fill: theme.sand, radius: 20)
drawText("先要质量，再追数量：先抓已经有消费意图、门店关系、品类兴趣的人。", rect: CGRect(x: 82, y: 620, width: 516, height: 20), size: 17, weight: .semibold)
drawRect(CGRect(x: 650, y: 606, width: 572, height: 50), fill: theme.panel, stroke: theme.line, radius: 20)
drawText("避免低质涌入：福利不直接白送，要与注册、问卷、首购、评价、推荐等动作绑定。", rect: CGRect(x: 674, y: 620, width: 528, height: 20), size: 17, weight: .semibold)
finishPage(number: page)
page += 1

// Page 7
startPage(number: page, title: "内容与节奏", subtitle: "让客户留下来的，不是每天打折，而是稳定、可信、可被期待的内容节律")
drawRect(CGRect(x: 58, y: 138, width: 736, height: 442), fill: theme.panel, stroke: theme.line, radius: 26)
drawText("推荐周节律", rect: CGRect(x: 84, y: 164, width: 180, height: 28), size: 24, weight: .bold)
let week = [
    ("Mon", "工具型内容", "How to / 选品建议 / 使用技巧"),
    ("Tue", "口碑证明", "前后对比、用户评价、门店真实反馈"),
    ("Wed", "问题征集", "问卷、投票、回复关键词、尺码/肤质/口味调查"),
    ("Thu", "场景种草", "午间推荐、周末搭配、家庭/办公室使用场景"),
    ("Fri", "会员权益", "本周 VIP 价、套组、优先发售、店内活动"),
    ("Sat", "社群互动", "UGC 征集、打卡、料理/搭配分享、到店照片"),
    ("Sun", "补货与回访", "复购提醒、售后关怀、下周预告")
]
for (idx, day) in week.enumerated() {
    let y = 208 + CGFloat(idx) * 50
    drawRect(CGRect(x: 84, y: y, width: 74, height: 34), fill: idx % 2 == 0 ? theme.tealSoft : theme.coralSoft, radius: 17)
    drawText(day.0, rect: CGRect(x: 84, y: y + 7, width: 74, height: 20), size: 15, weight: .bold, align: .center)
    drawText(day.1, rect: CGRect(x: 176, y: y + 4, width: 170, height: 26), size: 18, weight: .semibold)
    drawText(day.2, rect: CGRect(x: 346, y: y + 4, width: 420, height: 26), size: 16, color: theme.muted)
}
drawRect(CGRect(x: 826, y: 138, width: 396, height: 204), fill: theme.tealSoft, radius: 24)
drawText("四类内容比例", rect: CGRect(x: 852, y: 164, width: 160, height: 26), size: 24, weight: .bold)
bulletList([
    "40% 实用内容：帮客户更快决策、更好使用。",
    "25% 口碑内容：用户评价、案例、门店真实反馈。",
    "20% 权益内容：会员日、补货提醒、限定套组。",
    "15% 归属内容：UGC、幕后、员工、社区故事。"], x: 852, y: 204, width: 330, size: 17, gap: 10)
drawRect(CGRect(x: 826, y: 370, width: 396, height: 286), fill: theme.panel, stroke: theme.line, radius: 24)
drawText("葡语示例", rect: CGRect(x: 852, y: 394, width: 140, height: 26), size: 24, weight: .bold)
drawText("Stories CTA\n“Quer receber a lista VIP de hoje? Responde ‘VIP’ aqui.”\n\nWhatsApp 1:1\n“Oi, Ana. Separei 3 kits que fazem sentido para pele sensível. Quer que eu te envie só as opções até R$120?”\n\n复购提醒\n“Seu produto provavelmente está acabando. Quer repetir o último pedido via Pix?”", rect: CGRect(x: 852, y: 432, width: 336, height: 198), size: 16, color: theme.muted)
finishPage(number: page)
page += 1

// Page 8
startPage(number: page, title: "激励系统", subtitle: "积分、福利与荣誉感的作用不是送便宜，而是把互动变成可持续的动作")
drawCircle(center: CGPoint(x: 348, y: 362), radius: 96, fill: theme.sand, stroke: theme.coral, lineWidth: 3)
drawText("Clube\nPontos", rect: CGRect(x: 280, y: 328, width: 136, height: 54), size: 30, weight: .bold, align: .center)

let rewardNodes = [
    (CGPoint(x: 166, y: 252), "Earn", "留资、下单、评价、问卷、分享"),
    (CGPoint(x: 530, y: 252), "Unlock", "会员日、专属价、优先试用、免运"),
    (CGPoint(x: 530, y: 470), "Redeem", "样品、服务、店内权益、套组"),
    (CGPoint(x: 166, y: 470), "Share", "晒单、拉新、UGC、门店打卡")
]
for node in rewardNodes {
    drawRect(CGRect(x: node.0.x - 84, y: node.0.y - 54, width: 168, height: 108), fill: theme.panel, stroke: theme.line, radius: 22)
    drawText(node.1, rect: CGRect(x: node.0.x - 64, y: node.0.y - 30, width: 128, height: 28), size: 24, weight: .bold, align: .center)
    drawText(node.2, rect: CGRect(x: node.0.x - 64, y: node.0.y + 4, width: 128, height: 42), size: 14, color: theme.muted, align: .center)
}
drawArrow(from: CGPoint(x: 246, y: 252), to: CGPoint(x: 446, y: 252), color: theme.teal)
drawArrow(from: CGPoint(x: 530, y: 306), to: CGPoint(x: 530, y: 416), color: theme.coral)
drawArrow(from: CGPoint(x: 446, y: 470), to: CGPoint(x: 246, y: 470), color: theme.olive)
drawArrow(from: CGPoint(x: 166, y: 416), to: CGPoint(x: 166, y: 306), color: theme.teal)

let rules = [
    "规则 1：奖励购买、评价、推荐和反馈，不奖励纯无意图进群。",
    "规则 2：设置过期机制，鼓励周期性消费，而不是囤积分不消费。",
    "规则 3：将积分与“服务”绑定，例如免费咨询、优先预约、专属配送。",
    "规则 4：对高质量 UGC、带来新客、帮助答疑的成员给予公开表扬。"
]
drawRect(CGRect(x: 708, y: 158, width: 514, height: 214), fill: theme.panel, stroke: theme.line, radius: 24)
drawText("四条实操规则", rect: CGRect(x: 734, y: 184, width: 220, height: 26), size: 24, weight: .bold)
bulletList(rules, x: 734, y: 226, width: 452, size: 16, gap: 10)
drawCard(title: "反“羊毛党”机制", body: "让优惠与身份绑定：必须先完成注册、偏好选择、首购或实际到店动作。推荐动作给双方发可消费权益，而不是无门槛现金。", rect: CGRect(x: 708, y: 404, width: 514, height: 116), accent: theme.coral)
drawCard(title: "高价值玩法", body: "把最活跃、最会表达、最愿意分享的客户培养成社区气氛组和轻量 KOC，帮助用户影响用户。", rect: CGRect(x: 708, y: 540, width: 514, height: 116), accent: theme.olive)
finishPage(number: page)
page += 1

// Page 9
startPage(number: page, title: "三种经营剧本", subtitle: "不同品牌，不同转化逻辑；不要把所有业务都做成一种社群")
let playbooks = [
    ("高频低客单\n福利型", "适合：迷你超市、宠物用品、基础美妆、咖啡零售", ["周固定会员日", "补货提醒", "套组与加价购", "到店 / 自提联动"], theme.tealSoft, theme.teal),
    ("高频中客单\n内容型", "适合：美妆、服饰、小众食品、手作、生活方式品牌", ["教程 / 场景种草", "用户口碑与对比", "限定清单", "UGC 反哺成交"], theme.coralSoft, theme.coral),
    ("低频高客单\n服务型", "适合：诊所、家具、定制、美容服务、教育", ["问诊 / 诊断", "顾问式 1:1", "预约提醒", "长决策跟进"], theme.oliveSoft, theme.olive)
]
for (idx, pb) in playbooks.enumerated() {
    let x = 58 + CGFloat(idx) * 388
    drawRect(CGRect(x: x, y: 144, width: 360, height: 476), fill: pb.4, stroke: theme.line, radius: 26)
    drawText(pb.0, rect: CGRect(x: x + 22, y: 176, width: 316, height: 64), size: 28, weight: .bold)
    drawText(pb.1, rect: CGRect(x: x + 22, y: 252, width: 316, height: 60), size: 16, color: theme.muted)
    drawText("关键动作", rect: CGRect(x: x + 22, y: 330, width: 150, height: 24), size: 20, weight: .semibold)
    bulletList(pb.2, x: x + 22, y: 366, width: 310, size: 17, gap: 10)
    drawRect(CGRect(x: x + 22, y: 520, width: 316, height: 74), fill: theme.panel, stroke: pb.4, lineWidth: 2, radius: 18)
    let bottom = idx == 0 ? "目标：提高复购频次" : (idx == 1 ? "目标：缩短决策时间" : "目标：提高咨询到成交转化")
    drawText(bottom, rect: CGRect(x: x + 38, y: 544, width: 284, height: 24), size: 18, weight: .semibold, align: .center)
}
finishPage(number: page)
page += 1

// Page 10
startPage(number: page, title: "数据与 KPI", subtitle: "不要只看“最后一单从哪来”，要看私域对全链路的助推效果")
drawRect(CGRect(x: 58, y: 142, width: 1164, height: 104), fill: theme.panel, stroke: theme.line, radius: 24)
let flow = ["触点", "身份", "互动", "订单", "LTV"]
for (idx, label) in flow.enumerated() {
    let x = 92 + CGFloat(idx) * 226
    drawRect(CGRect(x: x, y: 172, width: 164, height: 46), fill: idx % 2 == 0 ? theme.tealSoft : theme.coralSoft, radius: 18)
    drawText(label, rect: CGRect(x: x, y: 185, width: 164, height: 18), size: 19, weight: .bold, align: .center)
    if idx < flow.count - 1 {
        drawArrow(from: CGPoint(x: x + 164, y: 195), to: CGPoint(x: x + 206, y: 195), color: theme.teal)
    }
}

let metricCards = [
    ("获客", "Opt-in 率\n每个触点的留资率\n每个留资用户成本"),
    ("激活", "7 日活跃率\n消息回复率\n问卷 / 投票参与率"),
    ("转化", "WhatsApp 到下单率\n辅助收入\n套组渗透率"),
    ("留存", "30 / 60 / 90 日复购率\n补货成功率\n流失召回率"),
    ("推荐", "转介绍率\nUGC 贡献人数\n高价值社群成员数")
]
for (idx, card) in metricCards.enumerated() {
    let x = 58 + CGFloat(idx) * 232
    drawCard(title: card.0, body: card.1, rect: CGRect(x: x, y: 286, width: 212, height: 178), accent: idx % 2 == 0 ? theme.teal : theme.coral)
}
drawRect(CGRect(x: 58, y: 500, width: 560, height: 146), fill: theme.tealSoft, radius: 24)
drawText("建议公式", rect: CGRect(x: 84, y: 524, width: 160, height: 24), size: 24, weight: .bold)
drawText("私域收入影响 = 触达人数 × 回复率 × 成交率 × AOV × 复购倍数\n\n对 SMB 更实用的看法是：把私域视为“提高全渠道转化效率和复购效率”的系统，不是孤立店铺。", rect: CGRect(x: 84, y: 560, width: 500, height: 72), size: 17, color: theme.ink)
drawRect(CGRect(x: 650, y: 500, width: 572, height: 146), fill: theme.panel, stroke: theme.line, radius: 24)
drawText("最小数据底座", rect: CGRect(x: 676, y: 524, width: 180, height: 24), size: 24, weight: .bold)
bulletList([
    "唯一标识：手机号或会员 ID。",
    "订单要带门店 / 渠道 / 顾问信息。",
    "对话和订单至少能在周报层面对上。",
    "新客、老客、VIP、沉默用户要能被单独查看。"], x: 676, y: 560, width: 500, size: 17, gap: 10)
finishPage(number: page)
page += 1

// Page 11
startPage(number: page, title: "组织与 SOP", subtitle: "SMB 不需要大团队，但一定要有清晰分工和固定节奏")
let roles = [
    ("Owner / GM", "定义目标、预算、品类优先级、门店协同"),
    ("运营", "拉新、分层、群与广播、周报"),
    ("内容", "Stories / Reels / 话术 / UGC 征集"),
    ("销售 / 门店", "1:1 跟进、到店承接、反馈洞察"),
    ("数据 / 外部工具", "报表、标签、自动化、CRM 对接")
]
for (idx, role) in roles.enumerated() {
    let x = 58 + CGFloat(idx) * 232
    drawCard(title: role.0, body: role.1, rect: CGRect(x: x, y: 148, width: 212, height: 144), accent: idx % 2 == 0 ? theme.teal : theme.coral)
}

drawRect(CGRect(x: 58, y: 332, width: 1164, height: 256), fill: theme.panel, stroke: theme.line, radius: 26)
drawText("每周节奏", rect: CGRect(x: 84, y: 358, width: 140, height: 24), size: 24, weight: .bold)
let ops = [
    ("Mon", "看上周数据\n筛选沉默、VIP、潜客"),
    ("Tue", "排内容与权益\n准备话术、素材、套组"),
    ("Wed", "启动核心触达\n广播 / DM / 店员跟进"),
    ("Thu", "集中 1:1 转化\n回收问题与异议"),
    ("Fri", "会员日 / 直播 / 新品\n制造波峰"),
    ("Sat", "门店反馈\n收集 UGC 与评价"),
    ("Sun", "复盘\n下周计划")
]
for (idx, op) in ops.enumerated() {
    let x = 90 + CGFloat(idx) * 160
    drawRect(CGRect(x: x, y: 410, width: 138, height: 134), fill: idx % 2 == 0 ? theme.tealSoft : theme.coralSoft, stroke: theme.line, radius: 20)
    drawText(op.0, rect: CGRect(x: x, y: 426, width: 138, height: 20), size: 16, weight: .bold, align: .center)
    drawText(op.1, rect: CGRect(x: x + 12, y: 456, width: 114, height: 68), size: 15, color: theme.ink, align: .center)
    if idx < ops.count - 1 {
        drawArrow(from: CGPoint(x: x + 138, y: 476), to: CGPoint(x: x + 160, y: 476), color: theme.olive)
    }
}
drawRect(CGRect(x: 58, y: 612, width: 1164, height: 44), fill: theme.sand, radius: 18)
drawText("最重要的不是做很多动作，而是让同一个动作可重复：同一招募话术、同一欢迎流程、同一周报口径、同一售后升级路径。", rect: CGRect(x: 82, y: 625, width: 1120, height: 20), size: 17, weight: .semibold)
finishPage(number: page)
page += 1

// Page 12
startPage(number: page, title: "风险与护栏", subtitle: "用户允许你进入聊天，不代表你可以无边界地打扰他")
let guardrails = [
    ("LGPD", "必须说明收集什么、为什么收集、如何退出；避免超出目的使用数据。"),
    ("消息频率", "先问偏好，再发广播；营销消息必须相关且有价值，不要高频轰炸。"),
    ("群规", "欢迎语、安静时段、广告禁令、客服转 1:1 规则要提前写清。"),
    ("客诉", "先在私聊处理情绪与解决方案，再回到群里做简短说明。"),
    ("疲劳", "群生命周期有限，活动群要有结束机制，高价值客户再转入长线层。"),
    ("优惠依赖", "不能只靠折扣驱动；要把权益、服务与会员身份做成长期价值。")
]
for (idx, item) in guardrails.enumerated() {
    let x = 58 + CGFloat(idx % 3) * 388
    let y = 148 + CGFloat(idx / 3) * 212
    drawCard(title: item.0, body: item.1, rect: CGRect(x: x, y: y, width: 360, height: 176), accent: idx % 2 == 0 ? theme.teal : theme.coral)
}
drawRect(CGRect(x: 58, y: 594, width: 1164, height: 62), fill: theme.panel, stroke: theme.line, radius: 20)
drawText("底线：客户体验优先于短期收入。巴西环境里，WhatsApp 是高亲密度触点，越高亲密的渠道越需要克制地使用。", rect: CGRect(x: 82, y: 614, width: 1120, height: 24), size: 18, weight: .semibold)
finishPage(number: page)
page += 1

// Page 13
startPage(number: page, title: "案例 1：社区美妆品牌", subtitle: "适合：1-3 家门店，Instagram 有内容基础，但复购弱、顾问跟进零散")
drawRect(CGRect(x: 58, y: 142, width: 300, height: 238), fill: theme.coralSoft, radius: 24)
drawText("场景", rect: CGRect(x: 82, y: 168, width: 100, height: 24), size: 24, weight: .bold)
drawText("Sao Paulo 社区美妆店\nInstagram 18k 粉丝\n到店咨询多，购买记录散\n客户会回 DM，但不会被长期经营", rect: CGRect(x: 82, y: 208, width: 250, height: 122), size: 18)

drawRect(CGRect(x: 388, y: 142, width: 834, height: 238), fill: theme.panel, stroke: theme.line, radius: 24)
drawText("改造方案", rect: CGRect(x: 414, y: 168, width: 140, height: 24), size: 24, weight: .bold)
bulletList([
    "Reels / Stories 用“肤质测试”“妆前妆后”“今日柜台清单”引导进入 WhatsApp。",
    "WhatsApp 先做问诊式分层：油皮 / 干皮 / 敏感；新客 / 老客 / VIP。",
    "广播层发每周清单；会员群做口碑与试色；VIP 做 1:1 推荐与预约提醒。",
    "积分奖励购买后评价、妆容分享、带朋友到店，而不是只奖励进群。"], x: 414, y: 208, width: 766, size: 17, gap: 10)

drawRect(CGRect(x: 58, y: 414, width: 560, height: 212), fill: theme.tealSoft, radius: 24)
drawText("90 天内应看到的变化", rect: CGRect(x: 84, y: 440, width: 240, height: 24), size: 24, weight: .bold)
bulletList([
    "已留资客户显著增加，顾问跟进不再只停在 Instagram DM。",
    "高意向客户被更快识别，咨询到成交时间缩短。",
    "补货、上新、会员价开始形成可预测波峰。"], x: 84, y: 482, width: 500, size: 17)

drawRect(CGRect(x: 650, y: 414, width: 572, height: 212), fill: theme.panel, stroke: theme.line, radius: 24)
drawText("可参考的目标区间", rect: CGRect(x: 676, y: 440, width: 220, height: 24), size: 24, weight: .bold)
drawText("Opt-in 率：15% - 30%\n7 日活跃率：35% - 45%\n复购率提升：15% - 25%\n辅助收入占比：12% - 20%", rect: CGRect(x: 676, y: 486, width: 360, height: 96), size: 19, weight: .medium)
drawText("说明：区间仅作 SMB 运营目标示意，不是业绩承诺。", rect: CGRect(x: 676, y: 588, width: 360, height: 18), size: 13, color: theme.muted)
finishPage(number: page)
page += 1

// Page 14
startPage(number: page, title: "案例 2：社区食品 / Mini Mercado", subtitle: "适合：SKU 多、补货频次高、到店客流稳定，但与顾客缺少持续连接")
drawRect(CGRect(x: 58, y: 142, width: 336, height: 450), fill: theme.oliveSoft, radius: 24)
drawText("场景", rect: CGRect(x: 84, y: 170, width: 90, height: 24), size: 24, weight: .bold)
drawText("Curitiba 社区 mini mercado\n日常客流不少，但促销与客流不匹配。\n顾客只在进店 10 分钟内发生购买。\n营业时间之外没有连接渠道。", rect: CGRect(x: 84, y: 212, width: 272, height: 126), size: 18)
drawText("适合的系统", rect: CGRect(x: 84, y: 364, width: 130, height: 24), size: 24, weight: .bold)
bulletList([
    "收银台、电子小票、包裹卡、社区活动统一导入 WhatsApp。",
    "按门店 / 社区分群，做本地化清单与到店福利。",
    "固定“会员波峰日”：周三补货、周五家庭晚餐、周日下周备货。",
    "UGC 重点不是精致拍摄，而是菜谱、搭配、当日到货与真实评价。"], x: 84, y: 406, width: 250, size: 16, gap: 10)

drawRect(CGRect(x: 426, y: 142, width: 796, height: 450), fill: theme.panel, stroke: theme.line, radius: 24)
drawText("执行框架", rect: CGRect(x: 452, y: 170, width: 140, height: 24), size: 24, weight: .bold)
let marketSteps = [
    ("入口", "门店 QR、收据、电话客服、周边社区活动"),
    ("互动", "每日到货、今日晚餐、周末家庭清单"),
    ("权益", "会员价、组合包、满额换购、优先预留"),
    ("转化", "Pix 下单、店内自提、定时配送"),
    ("复购", "补货提醒、节日清单、家庭套餐"),]
for (idx, step) in marketSteps.enumerated() {
    let y = 220 + CGFloat(idx) * 58
    drawRect(CGRect(x: 452, y: y, width: 122, height: 36), fill: idx % 2 == 0 ? theme.tealSoft : theme.coralSoft, radius: 18)
    drawText(step.0, rect: CGRect(x: 452, y: y + 9, width: 122, height: 18), size: 16, weight: .bold, align: .center)
    drawText(step.1, rect: CGRect(x: 592, y: y + 6, width: 584, height: 24), size: 17, color: theme.muted)
}
drawRect(CGRect(x: 452, y: 530, width: 724, height: 40), fill: theme.sand, radius: 16)
drawText("这类业务最适合把“高频消费”转写成“高频关系”：不是天天发折扣，而是天天发与今晚、这周、这个社区有关的内容。", rect: CGRect(x: 470, y: 542, width: 688, height: 18), size: 16, weight: .semibold)
finishPage(number: page)
page += 1

// Page 15
startPage(number: page, title: "90 天落地路线", subtitle: "用最小可行系统先跑通，再扩展到更多门店、更多自动化、更多分层")
let roadmap = [
    ("Day 1-30\n搭底座", ["确定唯一身份标识", "梳理 5-8 个留资触点", "搭建欢迎语 / 群规 / 标签", "定义 3 层人群与基础 KPI"], theme.tealSoft, theme.teal),
    ("Day 31-60\n跑节奏", ["启动固定周节律", "首个会员日 / 快闪群", "开始 1:1 顾问跟进", "建立最小周报"], theme.coralSoft, theme.coral),
    ("Day 61-90\n做放大", ["积分与转介绍", "VIP 与沉默用户专线", "门店反馈接入内容生产", "复盘 ROI 与扩容计划"], theme.oliveSoft, theme.olive)
]
for (idx, stage) in roadmap.enumerated() {
    let x = 86 + CGFloat(idx) * 372
    drawRect(CGRect(x: x, y: 190, width: 316, height: 340), fill: stage.2, stroke: theme.line, radius: 28)
    drawText(stage.0, rect: CGRect(x: x + 24, y: 224, width: 268, height: 64), size: 32, weight: .bold)
    bulletList(stage.1, x: x + 24, y: 314, width: 256, size: 18, gap: 14)
    if idx < roadmap.count - 1 {
        drawArrow(from: CGPoint(x: x + 316, y: 360), to: CGPoint(x: x + 356, y: 360), color: stage.3, width: 4)
    }
}
drawRect(CGRect(x: 58, y: 566, width: 1164, height: 90), fill: theme.panel, stroke: theme.line, radius: 22)
drawText("先做什么，不先做什么", rect: CGRect(x: 84, y: 590, width: 240, height: 24), size: 24, weight: .bold)
drawText("先做：留资入口、基础分层、固定节律、顾问跟进、复购提醒。\n暂不优先：复杂自动化、过多群类型、过多福利、脱离订单数据的花哨互动。", rect: CGRect(x: 84, y: 628, width: 1040, height: 34), size: 17, color: theme.muted)
finishPage(number: page)
page += 1

// Page 16
startPage(number: page, title: "即用模板与依据", subtitle: "把第一波话术和原则直接拿走，用在你的巴西 SMB 项目里")
let templates = [
    ("邀请", "Oi! Criamos um canal VIP para quem quer receber novidades, reposição e ofertas sem spam. Quer entrar?"),
    ("欢迎", "Bem-vinda(o)! Aqui você vai receber lançamentos, dicas e benefícios. Se quiser, me responde com sua preferência para eu te enviar só o que faz sentido."),
    ("复购", "Seu último pedido já deve estar perto do fim. Quer repetir o mesmo kit por Pix ou ver uma opção nova?"),
    ("VIP 跟进", "Separei 3 opções com base no que você comprou antes. Posso te mandar só as que cabem no seu orçamento?")
]
for (idx, item) in templates.enumerated() {
    let x = 58 + CGFloat(idx % 2) * 582
    let y = 154 + CGFloat(idx / 2) * 168
    drawRect(CGRect(x: x, y: y, width: 552, height: 140), fill: theme.panel, stroke: theme.line, radius: 22)
    drawText(item.0, rect: CGRect(x: x + 22, y: y + 22, width: 120, height: 24), size: 24, weight: .bold)
    drawText(item.1, rect: CGRect(x: x + 22, y: y + 58, width: 508, height: 60), size: 18, color: theme.muted)
}
drawRect(CGRect(x: 58, y: 514, width: 1164, height: 142), fill: theme.sand, radius: 24)
drawText("制作依据", rect: CGRect(x: 84, y: 540, width: 140, height: 24), size: 24, weight: .bold)
drawText("1. Meta 官方说明：WhatsApp 已成为企业与用户对话的重要场景，且消息应以 opt-in、相关性和用户控制为前提。\n2. 巴西央行 Pix 官方说明：Pix 是巴西即时支付基础设施，适合将聊天中的意向快速转为支付。\n3. 巴西 LGPD 法律文本：客户数据收集与营销触达必须建立在明确目的、透明告知和退出机制之上。\n4. Sebrae 面向小企业的课程与文章：WhatsApp Business 与 Instagram 是巴西小企业常见的数字销售组合。", rect: CGRect(x: 84, y: 580, width: 1048, height: 92), size: 16, color: theme.ink)
finishPage(number: page)
let pdf = PDFDocument()
for (index, image) in pageImages.enumerated() {
    guard let page = PDFPage(image: image) else {
        continue
    }
    pdf.insert(page, at: index)
}
guard pdf.write(to: outputURL) else {
    fatalError("Failed to write PDF to \(outputURL.path)")
}
print(outputURL.path)
