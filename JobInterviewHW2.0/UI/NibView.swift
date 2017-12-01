//
//  NibView.swift
//  SomeApp
//
//  Referenced from: https://github.com/n-b/UIView-NibLoading/blob/c67ca6a96c9b0cb9aad81a5bd019c493951cc6f1/UIView+NibLoading.m

import Foundation
import UIKit

open class NibView: UIView {
    static public func className(_ aClass: AnyClass) -> String {
        let className = NSStringFromClass(aClass)
        let components = className.components(separatedBy: ".")
        
        if components.count > 0 {
            return components.last!
        } else {
            return className
        }
    }

    fileprivate struct AssociatedKeys {
        static var NibsKey = "nibViewNibsAssociatedKeys"
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.loadViewContentsFromNib()
        
        // Notify event
        viewDidLoadFromNib()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.loadViewContentsFromNib()

        // Notify event
        viewDidLoadFromNib()
    }
    
    func viewDidLoadFromNib() {
        // Override in children to get this event...
    }
    
    fileprivate static func _nibLoadingAssociatedNibWithName(_ nibName: String) -> UINib? {
        
        let associatedNibs = objc_getAssociatedObject(self, &AssociatedKeys.NibsKey) as? NSDictionary
        var nib: UINib? = associatedNibs?.object(forKey: nibName) as? UINib
        
        if (nib == nil) {
            nib = UINib(nibName: nibName, bundle: nil)
            
            let updatedAssociatedNibs = NSMutableDictionary()
            if (associatedNibs != nil) {
                updatedAssociatedNibs.addEntries(from: associatedNibs! as! [String:UINib])
            }
            
            updatedAssociatedNibs.setObject(nib!, forKey: nibName as NSCopying)
            objc_setAssociatedObject(self, &AssociatedKeys.NibsKey, updatedAssociatedNibs, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        
        return nib
    }
    
    open func loadViewContentsFromNib() {
        loadViewContentsFromNibNamed(NibView.className(type(of: self)))
    }
    
    open func loadViewContentsFromNibNamed(_ nibName:String) {
        
        let nib = type(of: self)._nibLoadingAssociatedNibWithName(nibName)
        
        if let nib = nib {
            
            let views = nib.instantiate(withOwner: self, options: nil) as NSArray
            assert(views.count == 1, "There must be exactly one root container view in \(nibName)")
            
            let containerView = views.firstObject as! UIView
            
            assert(containerView.isKind(of: UIView.self) || containerView.isKind(of: type(of: self)), "UIView+NibLoading: The container view in nib \(nibName) should be a UIView instead of \(NibView.className(type(of: containerView))). (It's only a container, and it's discarded after loading.")
            
            containerView.translatesAutoresizingMaskIntoConstraints = false
            if self.bounds.equalTo(CGRect.zero) {
                //`self` has no size : use the containerView's size, from the nib file
                self.bounds = containerView.bounds
            }
            else {
                //`self` has a specific size : resize the containerView to this size, so that the subviews are autoresized.
                containerView.bounds = self.bounds
            }
            
            //save constraints for later
            let constraints = containerView.constraints
            
            //reparent the subviews from the nib file
            for view in containerView.subviews {
                self.addSubview(view)
            }
            
            //re-add constraints, replace containerView with self
            for constraint in constraints {
                
                var firstItem = constraint.firstItem
                var secondItem = constraint.secondItem
                
                if (firstItem as? NSObject == containerView) {
                    firstItem = self
                }
                
                if (secondItem as? NSObject == containerView) {
                    secondItem = self
                }
                
                //re-add
                if let firstItem = firstItem {
                self.addConstraint(NSLayoutConstraint(item: firstItem, attribute: constraint.firstAttribute, relatedBy: constraint.relation, toItem: secondItem, attribute: constraint.secondAttribute, multiplier: constraint.multiplier, constant: constraint.constant))
                }
            }
        }
        else {
            assert(nib != nil, "UIView+NibLoading : Can't load nib named \(nibName)")
        }
    }
}
