import SwiftUI

struct VoltCitySkylineView: View {
    var allDark: Bool = false

    var body: some View {
        GeometryReader { proxy in
            let columnCount = 11
            let totalSpacing: CGFloat = CGFloat(columnCount - 1) * 6
            let columnWidth = (proxy.size.width - totalSpacing - Spacing.lg * 2) / CGFloat(columnCount)

            HStack(alignment: .bottom, spacing: 6) {
                ForEach(0..<columnCount, id: \.self) { i in
                    buildingColumn(index: i, width: columnWidth)
                }
            }
            .padding(.horizontal, Spacing.lg)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
    }

    @ViewBuilder
    private func buildingColumn(index i: Int, width: CGFloat) -> some View {
        let baseHeight: Int = 70 + (i % 3) * 32 + (i % 2) * 12
        let height: CGFloat = CGFloat(baseHeight)
        let isLit: Bool = !allDark && ((i % 3 == 1) || (i % 5 == 0))
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.shadowMid)
                .frame(width: width, height: height)
            VStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { row in
                    HStack(spacing: 4) {
                        ForEach(0..<2, id: \.self) { col in
                            Circle()
                                .fill(Color.voltYellow.opacity(isLit && (row + col) % 2 == 0 ? 0.85 : 0.12))
                                .frame(width: 4, height: 4)
                        }
                    }
                }
            }
            .padding(.top, 12)
        }
    }
}
