//
//  PerrFuncs.swift
//  SomeApp
//
//  Created by Perry on 2/12/16.
//  Copyright © 2016 PerrchicK. All rights reserved.
//

import UIKit
import ObjectiveC

// MARK: - "macros" (... like)

public typealias CompletionClosure<T> = ((T) -> Void)
public typealias PredicateClosure<T> = ((T) -> Bool)

func WIDTH(_ frame: CGRect?) -> CGFloat { return frame == nil ? 0 : (frame?.size.width)! }
func HEIGHT(_ frame: CGRect?) -> CGFloat { return frame == nil ? 0 : (frame?.size.height)! }

// MARK: - Global Methods

public func 📗(_ logMessage: Any, file:String = #file, function:String = #function, line:Int = #line) {
    let formattter = DateFormatter()
    formattter.dateFormat = "yyyy-MM-dd HH:mm:ss:SSS"
    let timesamp = formattter.string(from: Date())
    
    print("〈\(timesamp)〉\(file.components(separatedBy: "/").last!) ➤ \(function.components(separatedBy: "(").first!) (\(line)): \(logMessage)")
}

public func 📕(_ logMessage: Any, file:String = #file, function:String = #function, line:Int = #line) {
    let formattter = DateFormatter()
    formattter.dateFormat = "yyyy-MM-dd HH:mm:ss:SSS"
    let timesamp = formattter.string(from: Date())

    print("Error:〈\(timesamp)〉\(file.components(separatedBy: "/").last!) ➤ \(function.components(separatedBy: "(").first!) (\(line)): \(logMessage)")
}

// MARK: - A service class that has some usefull methods
open class PerrFuncs {

    // dispatch block on main queue
    static public func runOnUiThread(afterDelay seconds: Double = 0.0, block: @escaping ()->()) {
        runBlockAfterDelay(afterDelay: seconds, block: block)
    }
    
    // runClosureAfterDelay
    static public func runBlockAfterDelay(afterDelay seconds: Double, onQueue: DispatchQueue = DispatchQueue.main, block: @escaping ()->()) {
        let delayTime = DispatchTime.now() + Double(Int64(seconds * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC) // 2 seconds delay before retry
        onQueue.asyncAfter(deadline: delayTime, execute: block)
    }

// Delete?

    #if !os(macOS) && !os(watchOS)
    /// This is an async operation (it needs an improvement - in case this method is being called again before the previous is completed?)
    public static func runBackgroundTask(block: @escaping (_ completionHandler: @escaping () -> ()) -> ()) {
        func endBackgroundTask(_ task: inout UIBackgroundTaskIdentifier) {
            UIApplication.shared.endBackgroundTask(task)
            task = UIBackgroundTaskInvalid
        }
        
        var backgroundTask: UIBackgroundTaskIdentifier!
        backgroundTask = UIApplication.shared.beginBackgroundTask {
            endBackgroundTask(&backgroundTask!)
        }
        
        let onDone = {
            endBackgroundTask(&backgroundTask!)
        }
        
        block(onDone)
    }
    #endif

    lazy var imageContainer: UIView = {
        let container = UIView(frame: UIScreen.main.bounds)
        container.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        // To be a target, it must be an NSObject instance
        container.onClick() {_ in 
            self.removeImage()
        }

        return container
    }()

    func removeImage() {
        imageContainer.animateFade(fadeIn: false, duration: 0.5) { (doneSuccessfully) in
            self.imageContainer.removeAllSubviews()
            self.imageContainer.removeFromSuperview()
        }
    }

    static func random(from: Int = 0, to: Int) -> Int {
        guard to != from else { return to }

        var _from: Int = from, _to: Int = to
        
        if to < from {// Error handling
            swap(&_to, &_from)
        }

        let randdomNumber: UInt32 = arc4random() % UInt32(_to - _from)
        return Int(randdomNumber) + _from
    }

    public static func percentOfValue(ofValue value: CGFloat, fromValue: CGFloat) -> CGFloat {
        return value / fromValue * 100 // Example: 50 / 2000 * 100 == 2.5%
    }

    public static func percentOfValue(ofValue value: Float, fromValue: Float) -> Float {
        return value / fromValue * 100 // Example: 50 / 2000 * 100 == 2.5%
    }

    public static func valueOfPercent(percentage: CGFloat, fromValue: CGFloat) -> CGFloat {
        return fromValue * percentage / 100; // Example: 2000 * 2.5% / 100 == 50
    }

    public static func valueOfPercent(percentage: Float, fromValue: Float) -> Float {
        return fromValue * percentage / 100; // Example: 2000 * 2.5% / 100 == 50
    }

    static func copyToClipboard(stringToCopy string: String) {
        UIPasteboard.general.string = string
    }

    // Perry: delete?
    @discardableResult
    static func postRequest(urlString: String, jsonDictionary: [String: Any], httpHeaders: [String:String]? = nil, completion: @escaping ([String: Any]?) -> ()) -> URLSessionDataTask? {

        guard let url = URL(string: urlString) else { completion(nil); return nil }

        do {
            // here "jsonData" is the dictionary encoded in JSON data
            let jsonData = try JSONSerialization.data(withJSONObject: jsonDictionary, options: .prettyPrinted)
            // create post request
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            
            if let httpHeaders = httpHeaders {
                for httpHeader in httpHeaders {
                    request.setValue(httpHeader.value, forHTTPHeaderField: httpHeader.key)
                }
            }
            
            //request.setValue("application/json", forHTTPHeaderField: "Content-Type") // OR: setValue
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            // insert json data to the request
            request.httpBody = jsonData
            request.timeoutInterval = 30

            let task = URLSession.shared.dataTask(with: request as URLRequest) { data, response, error in
                if let error = error {
                    📕(error)
                    completion(nil)
                    return
                }
                guard let data = data else { completion(nil); return }
                
                do {
                    guard let result = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else { completion(nil); return }
                    completion(result)
                } catch let deserializationError {
                    📕("Failed to parse JSON: \(deserializationError), data string: \(String(describing: String(data: data, encoding: String.Encoding.utf8)))")
                    completion(nil)
                }
            }
            
            task.resume()
            return task
        } catch let serializationError {
            📕("Failed to serialize JSON: \(serializationError)")
            completion(nil)
        }
        
        return nil
    }
}

extension String {
    func localized(comment: String = "") -> String {
        return NSLocalizedString(self, comment: comment)
    }

    // https://stackoverflow.com/questions/24092884/get-nth-character-of-a-string-in-swift-programming-language
    subscript (index: Int) -> Character {
        guard count > index else {return Character("") }
        return self[self.index(startIndex, offsetBy: index)]
    }

    func toUrl() -> URL? {
        return URL(string: self)
    }
}

public protocol Localizable {
    func localize()
}

public extension Localizable {
    
    public func localize(_ string: String?) -> String? {
        guard let term = string, term.hasPrefix("@") else {
            return string
        }
        let substring = term.substring(from: term.index(after: term.startIndex));
        guard !term.hasPrefix("@@") else {
            return substring
        }
        return substring.localized()
    }
    
    public func localize(_ string: String?, _ setter: (String?) -> Void) {
        setter(localize(string))
    }
    
    public func localize(_ getter: (UIControlState) -> String?, _ setter: (String?, UIControlState) -> Void) {
        setter(localize(getter(.normal)), .normal)
        setter(localize(getter(.selected)), .selected)
        setter(localize(getter(.highlighted)), .highlighted)
        setter(localize(getter(.disabled)), .disabled)
    }
}

extension UIColor {
    convenience init(hexString: String) {
        let hexString:NSString = hexString.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) as NSString
        let scanner = Scanner(string: hexString as String)
        
        if (hexString.hasPrefix("#")) {
            scanner.scanLocation = 1
        }
        
        var color:UInt32 = 0
        scanner.scanHexInt32(&color)
        
        let mask = 0x000000FF
        let r = Int(color >> 16) & mask
        let g = Int(color >> 8) & mask
        let b = Int(color) & mask
        
        let red   = CGFloat(r) / 255.0
        let green = CGFloat(g) / 255.0
        let blue  = CGFloat(b) / 255.0
        
        self.init(red:red, green:green, blue:blue, alpha:1)
    }
    
    func toHexString() -> String {
        var r:CGFloat = 0
        var g:CGFloat = 0
        var b:CGFloat = 0
        var a:CGFloat = 0
        
        getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let rgb:Int = (Int)(r*255)<<16 | (Int)(g*255)<<8 | (Int)(b*255)<<0
        
        return NSString(format:"#%06x", rgb) as String
    }
}

//MARK: - Global Extensions

// Declare a global var to produce a unique address as the assoc object handle
var SompApplicationHuggedProperty: UInt8 = 0

// Allows this: { let temp = -3 ~ -80 ~ 5 ~ 10 }
precedencegroup Additive {
    associativity: left // Explanation: https://en.wikipedia.org/wiki/Operator_associativity
}
infix operator ~ : Additive // https://developer.apple.com/documentation/swift/operator_declarations

/// Inclusively raffles a number from `left` hand operand value to the `right` hand operand value.
///
/// For example: the expression `{ let random: Int =  -3 ~ 5 }` will declare a random number between -3 and 5.
/// - parameter left:   The value represents `from`.
/// - parameter right:  The value represents `to`.
///
/// - returns: A random number between `left` and `right`.
func ~ (left: Int, right: Int) -> Int { // Reference: http://nshipster.com/swift-operators/
    return PerrFuncs.random(from: left, to: right)
}

extension UIViewController {
    func mostTopViewController() -> UIViewController {
        guard let topController = self.presentedViewController else { return self }

        return topController.mostTopViewController()
    }
}

extension UIApplication {
    static func mostTopViewController() -> UIViewController? {
        guard let topController = UIApplication.shared.keyWindow?.rootViewController else { return nil }
        return topController.mostTopViewController()
    }
}

extension UIAlertController {

    /**
     Dismisses the current alert (if presented) and pops up the new one
     */
    @discardableResult
    func show(completion: (() -> Swift.Void)? = nil) -> UIAlertController? {
        guard let mostTopViewController = UIApplication.mostTopViewController() else { 📕("Failed to present alert [title: \(String(describing: self.title)), message: \(String(describing: self.message))]"); return nil }

        mostTopViewController.present(self, animated: true, completion: completion)

        return self
    }

    func withAction(_ action: UIAlertAction) -> UIAlertController {
        self.addAction(action)
        return self
    }

    func withInputText(configurationBlock: @escaping ((_ textField: UITextField) -> Void)) -> UIAlertController {
        self.addTextField(configurationHandler: { (textField: UITextField!) -> () in
            configurationBlock(textField)
        })
        return self
    }
    
    static func make(style: UIAlertControllerStyle, title: String, message: String, dismissButtonTitle: String = "OK") -> UIAlertController {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: style)
        return alertController
    }

    static func makeActionSheet(title: String, message: String, dismissButtonTitle: String = "OK") -> UIAlertController {
        return make(style: .actionSheet, title: title, message: message, dismissButtonTitle: dismissButtonTitle)
    }

    static func makeAlert(title: String, message: String, dismissButtonTitle: String = "OK") -> UIAlertController {
        return make(style: .alert, title: title, message: message, dismissButtonTitle: dismissButtonTitle)
    }

    /**
     A service method that alerts with title and message in the top view controller
     
     - parameter title: The title of the UIAlertView
     - parameter message: The message inside the UIAlertView
     */
    static func alert(title: String, message: String, dismissButtonTitle:String = "OK", onGone: (() -> Void)? = nil) {
        UIAlertController.makeAlert(title: title, message: message).withAction(UIAlertAction(title: dismissButtonTitle, style: UIAlertActionStyle.cancel, handler: { (alertAction) -> Void in
            onGone?()
        })).show()
    }
}

extension UIViewController {
    
    class func instantiate(storyboardName: String? = nil) -> Self {
        return instantiateFromStoryboardHelper(storyboardName)
    }
    
    fileprivate class func instantiateFromStoryboardHelper<T: UIViewController>(_ storyboardName: String?) -> T {
        let storyboard = storyboardName != nil ? UIStoryboard(name: storyboardName!, bundle: nil) : UIStoryboard(name: "Main", bundle: nil)
        let identifier = NSStringFromClass(T.self).components(separatedBy: ".").last!
        let controller = storyboard.instantiateViewController(withIdentifier: identifier) as! T
        return controller
    }
}

// Inspired from: https://medium.com/flawless-app-stories/dry-string-localization-with-interface-builder-665496eb0270
extension UILabel: Localizable {
    public func localize() {
        localize(text) { text = $0 }
    }
}

// And thanks again (same inspiration like above, different ref) to Lisa Dziuba: https://www.linkedin.com/groups/121874/121874-6305477606137483268
extension UIButton: Localizable {
    public func localize() {
        localize(title(for:), setTitle(_:for:))
    }
}

extension UIView {
    func getRoundedCornered(_ radius: CGFloat = 5) {
        self.layer.cornerRadius = radius
        self.layer.masksToBounds = true
    }

    func beOval() {
        getRoundedCornered(frame.width / 2)
        clipsToBounds = true
        contentMode = .scaleAspectFill
    }

    func iterateAllSubviewsInTree(withClosure closure: (UIView) -> ()) {
        for view in subviews {
            view.iterateAllSubviewsInTree(withClosure: closure)
            closure(view)
        }
    }

    func findSubviewsInTree(predicateClosure: PredicateClosure<UIView>) -> [UIView] {
        if predicateClosure(self) { return [self] }
        var foundSubviews = [UIView]()
        for view in subviews {
            foundSubviews.append(contentsOf: (view.findSubviewsInTree(predicateClosure: predicateClosure)))
        }
        
        return foundSubviews
    }
    
    /// From: https://stackoverflow.com/questions/12770181/how-to-get-the-pixel-color-on-touch
    func pixelColor(atPoint point: CGPoint) -> UIColor {
        let pixel = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: 4)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        let context = CGContext(data: pixel, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)
        
        context!.translateBy(x: -point.x, y: -point.y)
        layer.render(in: context!)
        let color:UIColor = UIColor(red: CGFloat(pixel[0])/255.0,
                                    green: CGFloat(pixel[1])/255.0,
                                    blue: CGFloat(pixel[2])/255.0,
                                    alpha: CGFloat(pixel[3])/255.0)
        
        pixel.deallocate(capacity: 4)
        return color
    }

    // MARK: - Property setters-like methods
    var isPresented: Bool {
        get {
            return !isHidden
        }
        set {
            isHidden = !newValue
        }
    }

    // MARK: - Animations
    func animateScaleAndFadeOut(scaleSize: CGFloat = 1.2, _ completion: ((Bool) -> Void)? = nil) {
        UIView.animate(withDuration: 0.5, delay: 0, options: UIViewAnimationOptions(), animations: {
            // Core Graphics Affine Transformation: https://en.wikipedia.org/wiki/Affine_transformation
            self.transform = CGAffineTransform(scaleX: scaleSize, y: scaleSize)
            self.alpha = 0.0
        }, completion: { (completed) -> Void in
            completion?(completed)
        })
    }

    public func animateBounce(_ completion: ((Bool) -> Void)? = nil) {
        UIView.animate(withDuration: 0.1, delay: 0, options: UIViewAnimationOptions.curveEaseIn, animations: { [weak self] () -> () in
            self?.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        }) { (succeeded) -> Void in
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.2, initialSpringVelocity: 6.0, options: UIViewAnimationOptions.curveEaseOut   , animations: { [weak self] () -> Void in
                self?.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            }) { (succeeded) -> Void in
                completion?(succeeded)
            }
        }
    }

    public func animateNo(duration: TimeInterval = 0.4) {
        let noAnimation = CAKeyframeAnimation()
        noAnimation.keyPath = "position.x"
        
        noAnimation.values = [0, 10, -10, 10, 0]
        let keyTimes: [NSNumber] = [0, NSNumber(value: Float(1.0 / 6.0)), NSNumber(value: Float(3.0 / 6.0)), NSNumber(value: Float(5.0 / 6.0)), 1]
        noAnimation.keyTimes = keyTimes
        noAnimation.duration = duration
        
        noAnimation.isAdditive = true
        noAnimation.isRemovedOnCompletion = false

        self.layer.add(noAnimation, forKey: Configurations.Keys.NoNoAnimation) // shake animation
    }

    public func animateMoveToCenter(ofX x: CGFloat,andY y: CGFloat, duration: TimeInterval = 1, completion: ((Bool) -> Void)? = nil) {
        UIView.animate(withDuration: duration, animations: {
            self.center.x = x
            self.center.y = y
        }, completion: completion)
    }
    
    public func animateZoom(zoomIn: Bool, duration: TimeInterval = 1, completion: ((Bool) -> Void)? = nil) {
        if zoomIn {
            self.transform = CGAffineTransform(scaleX: 0.0, y: 0.0)
        }
        UIView.animate(withDuration: duration, animations: { [weak self] () -> Void in
            if zoomIn {
                self?.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            } else {
                self?.frame.size = CGSize(width: 0.0, height: 0.0)
            }
        }, completion: { [weak self] (finished) in
            self?.isPresented = zoomIn
            completion?(finished)
        })
    }

    public func animateFade(fadeIn: Bool, duration: TimeInterval = 1, completion: ((Bool) -> Void)? = nil) {
        // Skip redundant calls
        guard (fadeIn == false && (alpha > 0 || isHidden == false)) || (fadeIn == true && (alpha == 0 || isHidden == true)) else { return }

        self.alpha = fadeIn ? 0.0 : 1.0
        isPresented = true

        UIView.animate(withDuration: duration, animations: { [weak self] () -> Void in
            self?.alpha = fadeIn ? 1.0 : 0.0
        }, completion: { [weak self] (finished) in
            self?.isPresented = fadeIn
            completion?(finished)
        }) 
    }

    /**
    Recursively remove all receiver’s immediate subviews... and their subviews... and their subviews... and their subviews...
    */
    public func removeAllSubviews() {
        for subView in self.subviews {
            subView.removeAllSubviews()
        }

        📗("Removing: \(self), bounds: \(bounds), frame: \(frame):")
        self.removeFromSuperview()
    }
    
    // MARK: - Constraints methods
    
    func stretchToSuperViewEdges(_ insets: UIEdgeInsets = UIEdgeInsets.zero) {
        // Validate
        guard let superview = superview else { fatalError("superview not set") }
        
        let leftConstraint = constraintWithItem(superview, attribute: .left, multiplier: 1, constant: insets.left)
        let topConstraint = constraintWithItem(superview, attribute: .top, multiplier: 1, constant: insets.top)
        let rightConstraint = constraintWithItem(superview, attribute: .right, multiplier: 1, constant: insets.right)
        let bottomConstraint = constraintWithItem(superview, attribute: .bottom, multiplier: 1, constant: insets.bottom)
        
        let edgeConstraints = [leftConstraint, rightConstraint, topConstraint, bottomConstraint]
        
        translatesAutoresizingMaskIntoConstraints = false

        superview.addConstraints(edgeConstraints)
    }
    
    func pinToSuperViewCenter(_ offset: CGPoint = CGPoint.zero) {
        // Validate
        assert(self.superview != nil, "superview not set")
        let superview = self.superview!
        
        let centerX = constraintWithItem(superview, attribute: .centerX, multiplier: 1, constant: offset.x)
        let centerY = constraintWithItem(superview, attribute: .centerY, multiplier: 1, constant: offset.y)
        
        let centerConstraints = [centerX, centerY]
        
        translatesAutoresizingMaskIntoConstraints = false
        superview.addConstraints(centerConstraints)
    }

    /// Reference: https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/VisualFormatLanguage.html
    // https://blog.flashgen.com/2016/10/auto-layout-visual-format-language-helpers/
    @discardableResult
    func addConstraintsWithFormat(_ format: String, views: UIView...) -> [NSLayoutConstraint] {
        var viewsDictionary = [String: UIView]()
        for (index, view) in views.enumerated() {
            let key = "v\(index)"
            viewsDictionary[key] = view
            view.translatesAutoresizingMaskIntoConstraints = false
        }
        
        let constraints = NSLayoutConstraint.constraints(withVisualFormat: format, options: NSLayoutFormatOptions(), metrics: nil, views: viewsDictionary)
        self.addConstraints(constraints)
        return constraints
    }

    func constraintWithItem(_ view: UIView, attribute: NSLayoutAttribute, multiplier: CGFloat = 2, constant: CGFloat = 0) -> NSLayoutConstraint {
        return NSLayoutConstraint(item: self, attribute: attribute, relatedBy: .equal, toItem: view, attribute: attribute, multiplier: multiplier, constant: constant)
    }

    @discardableResult
    func addVerticalGradientBackgroundLayer(topColor: UIColor, bottomColor: UIColor) -> CALayer {
        let gradientLayer = CAGradientLayer()
        let topCGColor = topColor.cgColor
        let bottomCGColor = bottomColor.cgColor
        gradientLayer.colors = [topCGColor, bottomCGColor]
        gradientLayer.frame = frame
        layer.insertSublayer(gradientLayer, at: 0)

        return gradientLayer
    }

    // MARK: - Other cool additions

    /**
     Attaches the closure to the tap event (onClick event)

     - parameter onClickClosure: A closure to dispatch when a tap gesture is recognized.
     */
    @discardableResult
    func onClick(_ onClickClosure: @escaping OnTapRecognizedClosure) -> OnClickListener {
        self.isUserInteractionEnabled = true
        // Ron, Don't worry abut memory leaks here, I checked it already. This doesn't create retain-cycles, guaranteed :)
        let tapGestureRecognizer = OnClickListener(target: self, action: #selector(onTapRecognized(_:)), closure: onClickClosure)

        // Solves bug: https://stackoverflow.com/questions/18159147/iphone-didselectrowatindexpath-only-being-called-after-long-press-on-custom-c
        tapGestureRecognizer.cancelsTouchesInView = false

        // This way is much better than the old one here: https://github.com/PerrchicK/swift-app/commit/08c980f1e9710e4fb87357279a452078b89d56bf#diff-4d8c8435da5872f3af7c536aa941f0ccL570
        tapGestureRecognizer.delegate = tapGestureRecognizer // ... because it's weak referenced

        if self is UIButton {
            (self as? UIButton)?.addTarget(self, action: #selector(onTapRecognized(_:)), for: .touchUpInside)
            tapGestureRecognizer.isEnabled = false
        }

        addGestureRecognizer(tapGestureRecognizer)
        return tapGestureRecognizer
    }

    static func currentTimestamp() -> Int64 {
        return Date().timestampMillis
    }
    
    @objc func onTapRecognized(_ tapGestureRecognizer: UITapGestureRecognizer) {
        var onClickListener: OnClickListener?
        if self is UIButton {
            onClickListener = gestureRecognizers?.filter( { $0.isEnabled == false && $0 is OnClickListener } ).first as? OnClickListener
        } else {
            onClickListener = tapGestureRecognizer as? OnClickListener
        }

        guard let _onClickListener = onClickListener else { return }
        
        _onClickListener.closure(_onClickListener)
    }

    @discardableResult
    func onDrag(predicateClosure: PredicateClosure<UIView>? = nil, onDragClosure: @escaping CompletionClosure<CGPoint>) -> OnPanListener {
        return onPan { panGestureRecognizer in
            guard let draggedView = panGestureRecognizer.view, let superview = draggedView.superview, (predicateClosure?(self)).or(true), let onPanListener = panGestureRecognizer as? OnPanListener else { return }
            let locationOfTouch = panGestureRecognizer.location(in: superview)

            switch panGestureRecognizer.state {
            case .cancelled: fallthrough
            case .ended:
                onPanListener.additionalInfo = nil
            case .began:
                onPanListener.additionalInfo = CGPoint(x: draggedView.center.x - locationOfTouch.x, y: draggedView.center.y - locationOfTouch.y) as AnyObject
                fallthrough
            default:
                if let offset = onPanListener.additionalInfo as? CGPoint {
                    draggedView.center = CGPoint(x: locationOfTouch.x + (offset.x), y: locationOfTouch.y + (offset.y))
                }
            }
            
            onDragClosure(draggedView.center)
        }
    }

    @discardableResult
    func onPan(_ onPanClosure: @escaping OnPanRecognizedClosure) -> OnPanListener {
        self.isUserInteractionEnabled = true
        let panGestureRecognizer = OnPanListener(target: self, action: #selector(onPanRecognized(_:)), closure: onPanClosure)
        
        panGestureRecognizer.cancelsTouchesInView = false // Solves bug: https://stackoverflow.com/questions/18159147/iphone-didselectrowatindexpath-only-being-called-after-long-press-on-custom-c
        panGestureRecognizer.delegate = panGestureRecognizer
        addGestureRecognizer(panGestureRecognizer)

        return panGestureRecognizer
    }
    
    @objc func onPanRecognized(_ panGestureRecognizer: UIPanGestureRecognizer) {
        guard let panGestureRecognizer = panGestureRecognizer as? OnPanListener else { return }
        panGestureRecognizer.closure(panGestureRecognizer)
        if panGestureRecognizer.state == .ended {
            panGestureRecognizer.previousLocation = nil
        } else {
            panGestureRecognizer.previousLocation = panGestureRecognizer.location(in: panGestureRecognizer.view?.superview)
        }
    }

    @discardableResult
    func onSwipe(direction: UISwipeGestureRecognizerDirection, _ onSwipeClosure: @escaping OnSwipeRecognizedClosure) -> OnSwipeListener {
        self.isUserInteractionEnabled = true
        let swipeGestureRecognizer = OnSwipeListener(target: self, action: #selector(onSwipeRecognized(_:)), closure: onSwipeClosure)
        
        swipeGestureRecognizer.cancelsTouchesInView = false // Solves bug: https://stackoverflow.com/questions/18159147/iphone-didselectrowatindexpath-only-being-called-after-long-press-on-custom-c
        
        swipeGestureRecognizer.delegate = swipeGestureRecognizer
        swipeGestureRecognizer.direction = direction

        addGestureRecognizer(swipeGestureRecognizer)
        return swipeGestureRecognizer
    }

    @objc func onSwipeRecognized(_ swipeGestureRecognizer: UISwipeGestureRecognizer) {
        guard let swipeGestureRecognizer = swipeGestureRecognizer as? OnSwipeListener else { return }

        swipeGestureRecognizer.closure(swipeGestureRecognizer)
    }

    /**
     Attaches the closure to the tap event (onClick event)
     
     - parameter onClickClosure: A closure to dispatch when a tap gesture is recognized.
     */
    @discardableResult
    func onLongPress(_ onLongPressClosure: @escaping OnLongPressRecognizedClosure) -> OnLongPressListener {
        self.isUserInteractionEnabled = true
        let longPressGestureRecognizer = OnLongPressListener(target: self, action: #selector(longPressRecognized(_:)), closure: onLongPressClosure)
        
        longPressGestureRecognizer.cancelsTouchesInView = false // Solves bug: https://stackoverflow.com/questions/18159147/iphone-didselectrowatindexpath-only-being-called-after-long-press-on-custom-c
        longPressGestureRecognizer.delegate = longPressGestureRecognizer

        addGestureRecognizer(longPressGestureRecognizer)
        return longPressGestureRecognizer
    }
    
    @objc func longPressRecognized(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
        guard let longPressGestureRecognizer = longPressGestureRecognizer as? OnLongPressListener else { return }

        longPressGestureRecognizer.closure(longPressGestureRecognizer)
    }

    func firstResponder() -> UIView? {
        var firstResponder: UIView? = self
        
        if isFirstResponder {
            return firstResponder
        }
        
        for subView in subviews {
            firstResponder = subView.firstResponder()
            if firstResponder != nil {
                return firstResponder
            }
        }
        
        return nil
    }
}

extension URL {
    func queryStringComponents() -> [String: AnyObject] {
        var dict = [String: AnyObject]()
        // Check for query string
        if let query = self.query {
            // Loop through pairings (separated by &)
            for pair in query.components(separatedBy: "&") {
                // Pull key, val from from pair parts (separated by =) and set dict[key] = value
                let components = pair.components(separatedBy: "=")
                dict[components[0]] = components[1] as AnyObject?
            }
        }
        
        return dict
    }
}

// I took some insperation from the Android development, to enable a fluent interface
extension UserDefaults {
    static func save(value: Any, forKey key: String) -> UserDefaults {
        UserDefaults.standard.set(value, forKey: key)
        return UserDefaults.standard
    }
    
    static func remove(key: String) -> UserDefaults {
        UserDefaults.standard.set(nil, forKey: key)
        return UserDefaults.standard
    }
    
    static func load<T>(key: String) -> T? {
        if let actualValue = UserDefaults.standard.object(forKey: key) {
            return actualValue as? T
        }
        
        return nil
    }

    static func load<T>(key: String, defaultValue: T) -> T {
        if let actualValue = UserDefaults.standard.object(forKey: key) {
            return (actualValue as? T).or(defaultValue)
        }
        
        return defaultValue
    }
}

extension Array {
    public subscript(safe index: Int) -> Element? {
        guard count > index else {return nil }
        return self[index]
    }
    
    @discardableResult
    mutating func remove(where predicate: (Array.Iterator.Element) throws -> Bool) -> Element? {
        if let indexToRemove = try? self.index(where: predicate), let _indexToRemove = indexToRemove {
            return self.remove(at: _indexToRemove)
        }
        
        return nil
    }
}

typealias OnPanRecognizedClosure = (_ panGestureRecognizer: UIPanGestureRecognizer) -> ()
class OnPanListener: UIPanGestureRecognizer, UIGestureRecognizerDelegate {
    private(set) var closure: OnPanRecognizedClosure
    var additionalInfo: AnyObject?
    var previousLocation: CGPoint?

    init(target: Any?, action: Selector?, closure: @escaping OnPanRecognizedClosure) {
        self.closure = closure
        super.init(target: target, action: action)
    }
    
    @objc func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
    
    //    deinit {
    //        📘("\(className(OnSwipeListener.self)) gone from RAM 💀")
    //    }
}

typealias OnSwipeRecognizedClosure = (_ swipeGestureRecognizer: UISwipeGestureRecognizer) -> ()
class OnSwipeListener: UISwipeGestureRecognizer, UIGestureRecognizerDelegate {
    private(set) var closure: OnSwipeRecognizedClosure
    
    init(target: Any?, action: Selector?, closure: @escaping OnSwipeRecognizedClosure) {
        self.closure = closure
        super.init(target: target, action: action)
    }
    
    @objc func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
    
//    deinit {
//        📘("\(className(OnSwipeListener.self)) gone from RAM 💀")
//    }
}

typealias OnTapRecognizedClosure = (_ tapGestureRecognizer: UITapGestureRecognizer) -> ()
class OnClickListener: UITapGestureRecognizer, UIGestureRecognizerDelegate {
    private(set) var closure: OnTapRecognizedClosure

    init(target: Any?, action: Selector?, closure: @escaping OnTapRecognizedClosure) {
        self.closure = closure
        super.init(target: target, action: action)
    }
    
    @objc func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }

//    deinit {
//        📘("\(className(OnClickListener.self)) gone from RAM 💀")
//    }
}

typealias OnLongPressRecognizedClosure = (_ longPressGestureRecognizer: UILongPressGestureRecognizer) -> ()
class OnLongPressListener: UILongPressGestureRecognizer, UIGestureRecognizerDelegate {
    private(set) var closure: OnLongPressRecognizedClosure

    init(target: Any?, action: Selector?, closure: @escaping OnLongPressRecognizedClosure) {
        self.closure = closure
        super.init(target: target, action: action)
    }

    @objc func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
}

extension Optional {
    /// Still returning an optional, and doesn't unwrap it ¯\\_(ツ)_/¯
    func `or`(_ value: Wrapped?) -> Optional {
        // Thanks to Lisa Dziuba. Reference: https://medium.com/flawless-app-stories/best-ios-hacks-from-twitter-october-edition-ce253347f88a
        return self ?? value
    }

    // Ha, that was the missing part from his twit: https://gist.github.com/PaulTaykalo/2ebfe0d7c1ca9fff1938506e910f738c#file-optionalchaining-swift-L13
    func `or`(_ value: Wrapped) -> Wrapped {
        return self ?? value
    }
}

extension Bool {
    /// Inspired by: https://twitter.com/TT_Kilew/status/922458025713119232/photo/1
    func `if`<T>(then valueIfTrue: T, else valueIfFalse: T) -> T {
        return self ? valueIfTrue : valueIfFalse
    }
}

extension Date {
    var timestampMillis: Int64 {
        return timeIntervalSince1970.milliseconds
    }
    
    func shortHourRepresentation() -> String {
        let shortDateFormatter = DateFormatter()
        shortDateFormatter.dateFormat = "HH:mm"
        return shortDateFormatter.string(from: self)
    }
}
