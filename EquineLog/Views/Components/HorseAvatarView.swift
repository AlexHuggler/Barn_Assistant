import SwiftUI

/// Reusable horse avatar component that displays the horse's image or a placeholder.
struct HorseAvatarView: View {
    let horse: Horse
    var size: CGFloat = 50

    var body: some View {
        Group {
            if let imageData = horse.imageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "horse.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(Color.hunterGreen.opacity(0.6))
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .accessibilityLabel("\(horse.name) photo")
    }
}

/// Variant that accepts optional image data directly (useful for forms before horse is created).
struct HorseAvatarPlaceholder: View {
    let imageData: Data?
    var size: CGFloat = 50

    var body: some View {
        Group {
            if let imageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "horse.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(Color.hunterGreen.opacity(0.6))
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}

#Preview {
    VStack(spacing: 20) {
        HorseAvatarView(horse: PreviewContainer.sampleHorse(), size: 80)
        HorseAvatarView(horse: PreviewContainer.sampleHorse2(), size: 50)
        HorseAvatarPlaceholder(imageData: nil, size: 60)
    }
    .modelContainer(PreviewContainer.shared.container)
}
