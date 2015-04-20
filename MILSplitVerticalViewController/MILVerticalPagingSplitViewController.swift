/*
Licensed Materials - Property of IBM
© Copyright IBM Corporation 2015. All Rights Reserved.
*/

import UIKit

class VerticalPagingSplitViewController: UIViewController {
    
    // API
    // To populate the list of view controllers for each half of the SplitViewController, set the variables leftViewControllers and rightViewControllers to arrays of the Storyboard IDs wanted for each side:
    // To indicate which view controller should be initially shown, set the variables currentLeftVCIndex and currentRightVCIndex to the index of the view controller's storyboard ID:
    
    // Vars
    // These are the variables you should change to customize this view controller.
    var currentLeftVCIndex = 1
    var currentRightVCIndex = 1
    var leftViewControllers = ["LeftViewController1", "LeftViewController2", "LeftViewController3"]
    var rightViewControllers = ["RightViewController1", "RightViewController2", "RightViewController3"]
    // These the two view controllers being currently displayed. This is what you should access to
    // send data/info to and from the two displayed view controllers
    var currentLeftVC: UIViewController?
    var currentRightVC: UIViewController?
    // Probably shouldn't mess with any of this.
    var leftContainerView: UIView!
    var rightContainerView: UIView!
    var panGesture: UIPanGestureRecognizer!
    var belowVC: UIViewController?
    var aboveVC: UIViewController?
    // Frames
    var upDirectionEndFrame: CGRect!
    var normalEndFrame: CGRect!
    var downDirectionEndFrame: CGRect!
    // Gesture Recognition
    var side = Side.Left
    var containerForGesture: UIView?
    var indexForGesture: Int?
    var arrayForGesture: [String]?
    var currentVCForGesture: UIViewController?
    var canGoToAboveVC = true
    var canGoToBelowVC = true
    
    
    // Enums
    enum Direction {
        
        case Up
        case Down
        
    }
    
    enum Side {
        
        case Left
        case Right
        
    }
    
    
    // Type Methods
    
    
    // Instance Methods
    // Init & Helpers
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        hideNavigationBar()
        configureContainerViews()
        removeOldConstraints()
        setupLayoutConstraints()
        setupPanGesture()
        configureLeftAndRightViewControllers()
        
    }
    
    private func hideNavigationBar() {
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    // init, setAutoResizingMask, addSubView
    private func configureContainerViews() {
        
        leftContainerView = UIView()
        rightContainerView = UIView()
        
        leftContainerView.setTranslatesAutoresizingMaskIntoConstraints(false)
        rightContainerView.setTranslatesAutoresizingMaskIntoConstraints(false)
        
        self.view.addSubview(leftContainerView)
        self.view.addSubview(rightContainerView)
        
    }
    
    private func removeOldConstraints() {
        self.view.removeConstraints(self.view.constraints())
    }
    
    // Sets constraints on the two container views so that they are of equal widths on the screen
    private func setupLayoutConstraints() {
        
        var viewsDictionary = ["leftContainerView" : leftContainerView, "rightContainerView": rightContainerView]
        
        self.view.addConstraint(NSLayoutConstraint(
            item: self.leftContainerView,
            attribute: .Width,
            relatedBy: NSLayoutRelation.Equal,
            toItem: self.rightContainerView,
            attribute: .Width,
            multiplier: 1,
            constant: 0))
        
        self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[leftContainerView]|", options: nil, metrics: nil, views: viewsDictionary))
        self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[rightContainerView]|", options: nil, metrics: nil, views: viewsDictionary))
        
        self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[leftContainerView][rightContainerView]|", options: nil, metrics: nil, views: viewsDictionary))
        
    }
    
    private func setupPanGesture() {
        
        panGesture = UIPanGestureRecognizer(target: self, action: Selector("PanGestureRecognized:"))
        view.addGestureRecognizer(panGesture)
        
    }
    
    // Create initial left and right view controllers
    private func configureLeftAndRightViewControllers() {
        
        currentLeftVC = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle()).instantiateViewControllerWithIdentifier(leftViewControllers[currentLeftVCIndex]) as? UIViewController
        currentRightVC = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle()).instantiateViewControllerWithIdentifier(rightViewControllers[currentRightVCIndex]) as? UIViewController
        
        displayContentController(currentLeftVC!, inContainerView: leftContainerView)
        displayContentController(currentRightVC!, inContainerView: rightContainerView)
        
    }
    
    // Used to setup the two initial view controllers
    private func displayContentController(content: UIViewController, inContainerView: UIView) {
        
        addChildViewController(content)
        
        content.view.frame = CGRect(x:0, y: 0, width: inContainerView.frame.size.width, height: inContainerView.frame.size.height)
        inContainerView.addSubview(content.view)
        
        content.didMoveToParentViewController(self)
        
    }
    
    // All other methods
    // Action Methods
    // This function does a lot of stuff, and gets pretty crazy. But the gist of it is this:
    // - Determine which side of the screen the pan is on
    // - Determine the direction and whether or not we want to count it as a swipe
    // - Determine if a view controller exists in the direction we are moving to
    // - Start the transistion to that view controller
    // - When the gesture ends, determine which view controller to completely transistion to
    @IBAction func PanGestureRecognized(sender: UIPanGestureRecognizer) {
        
        let direction = (sender.velocityInView(self.view).y > 0) ? Direction.Up : Direction.Down        // Get the direction of this pan gesture
        var shouldCompleteSwipeOptional : Bool? = determineShouldSwipe(sender)                          // are we actually swiping (no if user slows down)
        
        // On start, create the view controllers above and below the current view controller
        if sender.state == UIGestureRecognizerState.Began {
            handleUIGestureBegan(sender)
        }
            
        else if sender.state == UIGestureRecognizerState.Ended {
            handleUIGestureEnded(sender, shouldCompleteSwipeOptional: &shouldCompleteSwipeOptional, direction: direction, halfwayMark: halfwayMark)
        }
            
        else {
            
            // While the gesture is occuring, determine if we should move the view controllers along with it
            var yOffset = sender.translationInView(self.view).y
            var applyOffset = false
            
            if yOffset > 0 {
                
                if canGoToAboveVC || (currentVCForGesture!.view.frame.origin.y < 0) {
                    
                    applyOffset = true
                    
                    if (currentVCForGesture!.view.frame.origin.y < 0) && (currentVCForGesture!.view.frame.origin.y + yOffset > 0) {
                        yOffset = -(currentVCForGesture!.view.frame.origin.y)
                    }
                    
                }
                
            }
                
            else if yOffset < 0 {
                
                if canGoToBelowVC || (currentVCForGesture!.view.frame.origin.y > 0) {
                    
                    applyOffset = true
                    
                    if (currentVCForGesture!.view.frame.origin.y > 0) && (currentVCForGesture!.view.frame.origin.y + yOffset < 0) {
                        yOffset = -currentVCForGesture!.view.frame.origin.y
                    }
                    
                }
                
            }
            
            if applyOffset {
                
                currentVCForGesture!.view.frame.offset(dx: 0, dy: yOffset)
                aboveVC?.view.frame.offset(dx: 0, dy: yOffset)
                belowVC?.view.frame.offset(dx: 0, dy: yOffset)
                
            }
            
        }
        
        resetTranslation(sender)
        
    }
    
    private func determineShouldSwipe(sender: UIPanGestureRecognizer) -> Bool {
        
        var returnBool : Bool = false
        
        // Detect if this gesture is moving very quickly (might be a swipe)
        if abs(sender.velocityInView(self.view).y) > 1000 {
            returnBool = true
        }
            
        // Cancel a swipe if the gesture slows down a lot
        else if abs(sender.velocityInView(self.view).y) < 200 {
            returnBool = false
        }
        
        return returnBool
        
    }
    
    private func handleUIGestureBegan(sender: UIPanGestureRecognizer) {
        
        var startPoint = sender.locationOfTouch(0, inView: self.view)
        
        // Determine the side of the swipe
        if startPoint.x < (self.view.frame.size.width / 2) {
            
            side = .Left
            containerForGesture = leftContainerView
            indexForGesture = currentLeftVCIndex
            arrayForGesture = leftViewControllers
            currentVCForGesture = currentLeftVC
            
        }
            
        else {
            
            side = .Right
            containerForGesture = rightContainerView
            indexForGesture = currentRightVCIndex
            arrayForGesture = rightViewControllers
            currentVCForGesture = currentRightVC
            
        }
        
        // Frames for view controllers
        upDirectionEndFrame = CGRect(
            x: 0,
            y: -containerForGesture!.frame.size.height,
            width: containerForGesture!.frame.size.width,
            height: containerForGesture!.frame.size.height)
        
        normalEndFrame = CGRect(
            x: 0,
            y: 0,
            width: containerForGesture!.frame.size.width,
            height: containerForGesture!.frame.size.height)
        
        downDirectionEndFrame = CGRect(
            x: 0,
            y: containerForGesture!.frame.size.height,
            width: containerForGesture!.frame.size.width,
            height: containerForGesture!.frame.size.height)
        
        // Determine if we can create view controller above/below the moving view controller
        canGoToAboveVC = true
        canGoToBelowVC = true
        
        if indexForGesture == 0 {
            canGoToAboveVC = false
        }
        
        if indexForGesture == arrayForGesture!.count - 1 {
            canGoToBelowVC = false
        }
        
        // Create view controllers if possible and set above and below the current view controller
        if canGoToBelowVC {
            
            belowVC = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle()).instantiateViewControllerWithIdentifier(arrayForGesture![indexForGesture! + 1]) as? UIViewController
            self.addChildViewController(belowVC!)
            containerForGesture!.addSubview(belowVC!.view)
            belowVC!.view.frame = downDirectionEndFrame
            
        }
            
        else {
            belowVC = nil
        }
        
        if canGoToAboveVC {
            
            aboveVC = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle()).instantiateViewControllerWithIdentifier(arrayForGesture![indexForGesture! - 1]) as? UIViewController
            self.addChildViewController(aboveVC!)
            containerForGesture!.addSubview(aboveVC!.view)
            aboveVC!.view.frame = upDirectionEndFrame
            
        }
            
        else {
            aboveVC = nil
        }
        
    }
    
    private func handleUIGestureEnded(sender: UIPanGestureRecognizer, inout shouldCompleteSwipeOptional: Bool?, direction: Direction) {
        
        let halfwayMark = self.view.frame.size.height / 2
        
        // When the gesture ends, determine which view controller that needs to become the current view controller and finish the transistion
        var resetToCurrentVC = false
        
        if shouldCompleteSwipeOptional ?? false {
            
            if direction == .Down && canGoToBelowVC {
                moveFromViewController(currentVCForGesture!, toViewController: belowVC!, direction: direction, side: side)
                aboveVC?.willMoveToParentViewController(nil)
                aboveVC?.removeFromParentViewController()
            }
                
            else if direction == .Up && canGoToAboveVC {
                moveFromViewController(currentVCForGesture!, toViewController: aboveVC!, direction: direction, side: side)
                belowVC?.willMoveToParentViewController(nil)
                belowVC?.removeFromParentViewController()
            }
                
            else {
                resetToCurrentVC = true
            }
            
            shouldCompleteSwipeOptional = false
            
        }
            
        else {
            
            if currentVCForGesture!.view.frame.origin.y <= -halfwayMark {
                moveFromViewController(currentVCForGesture!, toViewController: belowVC!, direction: .Down, side: side)
                aboveVC?.willMoveToParentViewController(nil)
                aboveVC?.removeFromParentViewController()
            }
                
            else if currentVCForGesture!.view.frame.origin.y > halfwayMark {
                moveFromViewController(currentVCForGesture!, toViewController: aboveVC!, direction: .Up, side: side)
                belowVC?.willMoveToParentViewController(nil)
                belowVC?.removeFromParentViewController()
            }
                
            else {
                resetToCurrentVC = true
            }
            
        }
        
        if resetToCurrentVC {
            
            if currentVCForGesture!.view.frame.origin.y > 0 {
                
                moveFromViewController(aboveVC!, toViewController: currentVCForGesture!, direction: .Down, side: side)
                belowVC?.willMoveToParentViewController(nil)
                belowVC?.removeFromParentViewController()
                
            }
                
            else if currentVCForGesture!.view.frame.origin.y < 0 {
                
                moveFromViewController(belowVC!, toViewController: currentVCForGesture!, direction: .Up, side: side)
                aboveVC?.willMoveToParentViewController(nil)
                aboveVC?.removeFromParentViewController()
                
            }
            
        }
        
    }
    
    // Called when a gesture ends to transistion from one view controller to another.
    private func moveFromViewController(vc: UIViewController, toViewController: UIViewController, direction: Direction, side: Side) {
        
        vc.willMoveToParentViewController(nil)
        
        if direction == .Up {
            
            self.transitionFromViewController(
                vc,
                toViewController: toViewController,
                duration: 0.4,
                options: UIViewAnimationOptions.CurveEaseOut,
                animations: { () -> Void in
                    toViewController.view.frame = self.normalEndFrame
                    vc.view.frame = self.downDirectionEndFrame
                },
                completion:{ (finished: Bool) -> Void in
                    if self.currentVCForGesture != toViewController {
                        if side == .Left {
                            self.currentLeftVCIndex -= 1
                            self.currentLeftVC = toViewController
                        } else {
                            self.currentRightVCIndex -= 1
                            self.currentRightVC = toViewController
                        }
                    }
                    vc.removeFromParentViewController()
                    toViewController.didMoveToParentViewController(self)
            })
        } else if direction == .Down {
            self.transitionFromViewController(vc, toViewController: toViewController, duration: 0.4, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
                toViewController.view.frame = self.normalEndFrame
                vc.view.frame = self.upDirectionEndFrame
                }, completion:{ (finished: Bool) -> Void in
                    if self.currentVCForGesture != toViewController {
                        if side == .Left {
                            self.currentLeftVCIndex += 1
                            self.currentLeftVC = toViewController
                        } else {
                            self.currentRightVCIndex += 1
                            self.currentRightVC = toViewController
                        }
                        
                    }
                    vc.removeFromParentViewController()
                    toViewController.didMoveToParentViewController(self)
            })
            
        }
        
    }
    
    private func resetTranslation(sender: UIPanGestureRecognizer) {
        sender.setTranslation(CGPointZero, inView: self.view)
    }
    
}
