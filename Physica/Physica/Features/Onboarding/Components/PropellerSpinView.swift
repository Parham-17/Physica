import SwiftUI

/// Renders a Spark image at a given size. Propeller rotation is currently not
/// implemented — the static propeller drawn into the source asset is shown.
struct SparkAnimated: View {
    let imageName: String
    var size: CGFloat = 200

    var body: some View {
        Image(imageName)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
    }
}
