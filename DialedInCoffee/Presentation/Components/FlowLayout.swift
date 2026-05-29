import SwiftUI

/// Lightweight wrapping layout: arranges subviews left-to-right and wraps to next row when full.
public struct FlowLayout: Layout {
    public var spacing: CGFloat

    public init(spacing: CGFloat = 8) {
        self.spacing = spacing
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        let rows = arrange(subviews: subviews, maxWidth: maxWidth)
        let height = rows.map(\.height).reduce(0, +) + CGFloat(max(0, rows.count - 1)) * spacing
        let widthUsed: CGFloat = {
            if proposal.width != nil { return maxWidth }
            return rows.map(\.width).max() ?? 0
        }()
        return CGSize(width: widthUsed, height: height)
    }

    public func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let rows = arrange(subviews: subviews, maxWidth: bounds.width)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            for item in row.items {
                let size = subviews[item.index].sizeThatFits(.unspecified)
                subviews[item.index].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private struct Row {
        var items: [(index: Int, size: CGSize)] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func arrange(subviews: Subviews, maxWidth: CGFloat) -> [Row] {
        var rows: [Row] = [Row()]
        for (i, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(.unspecified)
            var current = rows.removeLast()
            let projectedWidth = current.width + size.width + (current.items.isEmpty ? 0 : spacing)
            if projectedWidth > maxWidth && !current.items.isEmpty {
                rows.append(current)
                current = Row()
            }
            current.items.append((i, size))
            current.width += size.width + (current.items.count > 1 ? spacing : 0)
            current.height = max(current.height, size.height)
            rows.append(current)
        }
        return rows
    }
}
