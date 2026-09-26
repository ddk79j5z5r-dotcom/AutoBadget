import PhotosUI
import SwiftUI
import UIKit

enum ImageService {
    /// Загружает фото из PhotosPicker, уменьшает и сжимает в JPEG
    static func loadJPEG(from item: PhotosPickerItem?, maxDimension: CGFloat = 1600) async -> Data? {
        guard let item, let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return nil }
        return downscaled(image, maxDimension: maxDimension).jpegData(compressionQuality: 0.8)
    }

    static func downscaled(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let scale = min(1, maxDimension / max(size.width, size.height))
        guard scale < 1 else { return image }
        let target = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: target, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
    }
}
