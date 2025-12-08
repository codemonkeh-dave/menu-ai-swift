# Image Processing for Menu AI

## Overview

This document outlines the planned image processing feature that will be implemented to ensure high-quality menu images before uploading to the AI service. The feature consists of two main layers:

1. **Image Quality Detection** - Detecting whether an image is "good enough" (blur/quality assessment)
2. **Image Resizing** - Optimizing image size before upload

## Image Quality Detection

### Option A: iOS 18+ Vision Framework (Recommended)

For apps targeting iOS 18 and later, we can use Apple's new Vision image aesthetics API which provides a ready-made quality score.

#### Key Features:
- Uses `VNCalculateImageAestheticsScoresRequest` / `CalculateImageAestheticsScoresRequest`
- Returns `ImageAestheticsScoresObservation` with `overallScore`
- Accounts for blur, exposure, and composition
- Runs entirely on-device
- Part of the Vision framework

#### Implementation Example:

```swift
import Vision
import UIKit

func imageQualityScore(for image: UIImage) async throws -> Float {
    guard let cgImage = image.cgImage else { throw NSError() }

    var request = CalculateImageAestheticsScoresRequest(nil)
    let result = try await request.perform(on: cgImage, orientation: .up)

    guard let scores = result.observation else {
        throw NSError(domain: "Quality", code: -1)
    }

    return scores.overallScore
}
```

#### Usage:

```swift
let score = try await imageQualityScore(for: image)
let isTooBlurred = score < 0.0    // Threshold needs tuning based on testing
```

### Option B: Legacy iOS Support (Pre-iOS 18)

For supporting earlier iOS versions, implement a "variance of Laplacian" blur detector using Core Image/Accelerate/MPS.

#### Approach:
- Use Metal Performance Shaders (`MPSImageLaplacian`) or vImage
- Apply Laplacian filter and compute variance
- Lower variance indicates more blur
- Uses only Apple frameworks: Vision + Core Image + Accelerate

#### High-level Steps:
1. Convert `UIImage` to `vImage_Buffer` or `CIImage`
2. Apply a Laplacian kernel (e.g., 3×3)
3. Compute variance of pixel intensities
4. Compare variance against tuned threshold

#### Alternative:
Train a small Core ML model for "sharp vs blurry" classification and run through Vision's `VNCoreMLRequest` (usually overkill for this use case).

## Image Resizing

After determining image quality is acceptable, resize locally before upload to optimize performance and reduce bandwidth.

### UIKit Implementation:

```swift
import UIKit

func resized(image: UIImage, maxPixelSize: CGFloat) -> UIImage {
    let width = image.size.width
    let height = image.size.height

    let maxSide = max(width, height)
    if maxSide <= maxPixelSize { return image }

    let scale = maxPixelSize / maxSide
    let newSize = CGSize(width: width * scale, height: height * scale)

    let format = UIGraphicsImageRendererFormat()
    format.scale = 1        // Size in pixels
    let renderer = UIGraphicsImageRenderer(size: newSize, format: format)

    return renderer.image { _ in
        image.draw(in: CGRect(origin: .zero, size: newSize))
    }
}
```

## Recommended Pipeline for Menu AI

### Target Specifications:
- **Max side length**: 1200-1600px (keeps menus readable while avoiding huge uploads)
- **Quality threshold**: TBD (requires testing and tuning)

### Implementation Flow:

```swift
// 1. Check image quality
let qualityScore = try await imageQualityScore(for: capturedImage)
guard qualityScore >= threshold else {
    // Ask user to retake photo
    return
}

// 2. Resize image
let downsized = resized(image: capturedImage, maxPixelSize: 1600)

// 3. Upload to API
// Upload downsized image to Gemini/AI service
```

## Implementation Strategy

### Best Option (iOS 18+):
- Use Vision's image aesthetics request as blur/quality proxy
- Simple threshold on `overallScore`

### Backwards Compatible Option:
- Implement Laplacian variance blur detection with Core Image + Accelerate/MPS
- Follow Apple-friendly examples for implementation

### Universal Steps:
- Resize using `UIGraphicsImageRenderer` (or vImage for more control)
- Encode as JPEG before sending to AI service
- Integrate into existing networking layer

## Next Steps

1. Determine minimum iOS version support requirements
2. Choose appropriate implementation approach based on iOS version
3. Create helper class wrapping "check blur + resize + JPEG encode" functionality
4. Integrate with existing `NetworkManager`
5. Add user feedback for image quality issues
6. Test and tune quality thresholds with real menu images

## Related Files

- `NetworkManager.swift` - Will integrate image processing before upload
- `CameraView.swift` - Will call image processing after capture
- `Models.swift` - May need image processing result models

## References

- [Apple Vision Framework Documentation](https://developer.apple.com/documentation/vision)
- [Core Image Programming Guide](https://developer.apple.com/library/archive/documentation/GraphicsImaging/Conceptual/CoreImaging/ci_intro/ci_intro.html)
- [Metal Performance Shaders](https://developer.apple.com/documentation/metalperformanceshaders)