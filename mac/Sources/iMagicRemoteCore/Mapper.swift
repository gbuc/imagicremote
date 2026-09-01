import CoreGraphics

public enum Mapper {
  public static func quartzPoint(x: Double, y: Double, target: CGRect, primary: CGRect) -> CGPoint {
    let cocoaX = target.origin.x + CGFloat(x) * target.size.width
    let cocoaY = target.origin.y + (1 - CGFloat(y)) * target.size.height
    let quartzX = cocoaX
    let quartzY = primary.maxY - cocoaY
    return CGPoint(x: quartzX, y: quartzY)
  }
}
