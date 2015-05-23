/*
Licensed Materials - Property of IBM
© Copyright IBM Corporation 2015. All Rights Reserved.
*/

import UIKit

class VerticalPagingSplitViewController: UIViewController {
    private let model = VerticalPagingSplitModel();
    
    //////////////////////////////////////////////////////////////////////////////////
    // These the two view controllers being currently displayed. This is what you should access to 
    // send data/info to and from the two displayed view controllers
    //////////////////////////////////////////////////////////////////////////////////
    private var currentLeftVC: UIViewController?
    private var currentRightVC: UIViewController?
    
    //////////////////////////////////////////////////////////////////////////////////
    // Probably shouldn't mess with any of this.
    //////////////////////////////////////////////////////////////////////////////////
    private var leftContainerView: UIView!
    private var rightContainerView: UIView!
    private var panGesture: UIPanGestureRecognizer!
    private var belowVC: UIViewController?
    private var aboveVC: UIViewController?
    
    private var upDirectionEndFrame: CGRect!
    private var normalEndFrame: CGRect!
    private var downDirectionEndFrame: CGRect!
    
    enum Direction {
        case Up
        case Down
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        // Setup container views
        leftContainerView = UIView()
        rightContainerView = UIView()
        leftContainerView.setTranslatesAutoresizingMaskIntoConstraints(false)
        rightContainerView.setTranslatesAutoresizingMaskIntoConstraints(false)
        view.addSubview(leftContainerView)
        view.addSubview(rightContainerView)
        setupLayoutConstraints()
        
        // Setup Pan Gesture
        panGesture = UIPanGestureRecognizer(target: self, action: Selector("PanGestureRecognized:"))
        view.addGestureRecognizer(panGesture)
        
        // Create initial left and right view controllersse
        currentLeftVC = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle()).instantiateViewControllerWithIdentifier(model.getCurrentViewControllerIdentifier(VerticalPagingSplitModel.Side.Left)) as? UIViewController
        displayContentController(currentLeftVC!, inContainerView: leftContainerView)
        
        currentRightVC = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle()).instantiateViewControllerWithIdentifier(model.getCurrentViewControllerIdentifier(VerticalPagingSplitModel.Side.Right)) as? UIViewController
        displayContentController(currentRightVC!, inContainerView: rightContainerView)
    }
    
    // Sets constraints on the two container views so that they are of equal widths on the screen
    private func setupLayoutConstraints() {
        view.removeConstraints(view.constraints())
        var viewsDictionary = Dictionary <String, UIView>()
        viewsDictionary["leftContainerView"] = leftContainerView
        viewsDictionary["rightContainerView"] = rightContainerView
        
        view.addConstraint(NSLayoutConstraint(item: leftContainerView, attribute: .Width, relatedBy: NSLayoutRelation.Equal, toItem: rightContainerView, attribute: .Width, multiplier: 1, constant: 0))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[leftContainerView]|", options: nil, metrics: nil, views: viewsDictionary))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[rightContainerView]|", options: nil, metrics: nil, views: viewsDictionary))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[leftContainerView][rightContainerView]|", options: nil, metrics: nil, views: viewsDictionary))
    }
    
    // Used to setup the two initial view controllers
    private func displayContentController(content: UIViewController, inContainerView: UIView) {
        addChildViewController(content)
        content.view.frame = CGRect(x:0, y: 0, width: inContainerView.frame.size.width, height: inContainerView.frame.size.height)
        inContainerView.addSubview(content.view)
        content.didMoveToParentViewController(self)
    }
    
    var swipe = false
    var direction = Direction.Up
    var side = VerticalPagingSplitModel.Side.Left
    var containerForGesture: UIView?
    var currentVCForGesture: UIViewController?
    var canGoToAboveVC = true
    var canGoToBelowVC = true

    
    // This function does a lot of stuff, and gets pretty crazy. But the gist of it is this:
    // - Determine which side of the screen the pan is on
    // - Determine the direction and whether or not we want to count it as a swipe
    // - Determine if a view controller exists in the direction we are moving to
    // - Start the transistion to that view controller
    // - When the gesture ends, determine which view controller to completely transistion to
    @IBAction func PanGestureRecognized(sender: UIPanGestureRecognizer) {
        var resetTranslation = true
        var halfwayMark = view.frame.size.height / 2
        let swipeVelocityThreshold : CGFloat = 1000
        let swipeCancelVelocityThreshold : CGFloat = 200
        
        // Get the direction of this pan gesture
        if sender.velocityInView(view).y > 0 {
            direction = Direction.Up
        } else {
            direction = Direction.Down
        }
        
        // Detect if this gesture is moving very quickly (might be a swipe)
        if abs(sender.velocityInView(view).y) > swipeVelocityThreshold {
            swipe = true
        } else if abs(sender.velocityInView(view).y) < swipeCancelVelocityThreshold {
            // Cancel a swipe if the gesture slows down a lot
            swipe = false
        }
        
        if sender.state == UIGestureRecognizerState.Began {
            beginTransition(sender)
        } else if sender.state == UIGestureRecognizerState.Ended {
            finishTransition(halfwayMark)
        } else {
            continueTransition(sender)
        }
        
        if resetTranslation {
            sender.setTranslation(CGPointZero, inView: view)
        }
    }
    
    /**
    On start, create the view controllers above and below the current view controller

    :param: sender
    */
    private func beginTransition(sender:UIPanGestureRecognizer) {
        let startPoint = sender.locationOfTouch(0, inView: view)
        
        // Determine the side of the swipe
        if startPoint.x < (view.frame.size.width / 2) {
            side = VerticalPagingSplitModel.Side.Left
            containerForGesture = leftContainerView
            currentVCForGesture = currentLeftVC
        } else {
            side = VerticalPagingSplitModel.Side.Right
            containerForGesture = rightContainerView
            currentVCForGesture = currentRightVC
        }
        canGoToAboveVC = !model.isFirstVC(side)
        canGoToBelowVC = !model.isLastVC(side)
        
        // Frames for view controllers
        upDirectionEndFrame = CGRect(x: 0, y: -containerForGesture!.frame.size.height, width: containerForGesture!.frame.size.width, height: containerForGesture!.frame.size.height)
        normalEndFrame = CGRect(x: 0, y: 0, width: containerForGesture!.frame.size.width, height: containerForGesture!.frame.size.height)
        downDirectionEndFrame = CGRect(x: 0, y: containerForGesture!.frame.size.height, width: containerForGesture!.frame.size.width, height: containerForGesture!.frame.size.height)
        
        // Create view controllers if possible and set above and below the current view controller
        if canGoToBelowVC {
            belowVC = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle()).instantiateViewControllerWithIdentifier(model.getNextViewControllerIdentifier(side)) as? UIViewController
            addChildViewController(belowVC!)
            containerForGesture!.addSubview(belowVC!.view)
            belowVC!.view.frame = downDirectionEndFrame
        } else {
            belowVC = nil
        }
        if canGoToAboveVC {
            aboveVC = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle()).instantiateViewControllerWithIdentifier(model.getPreviousViewControllerIdentifier(side)) as? UIViewController
            addChildViewController(aboveVC!)
            containerForGesture!.addSubview(aboveVC!.view)
            aboveVC!.view.frame = upDirectionEndFrame
        } else {
            aboveVC = nil
        }
    }
    
    /**
    When the gesture ends, determine which view controller that needs to become the current view controller and finish the transition

    :param: halfwayMark Half of the frame height
    */
    private func finishTransition(halfwayMark : CGFloat) {
        
        var resetToCurrentVC = false
        if swipe {
            if direction == .Down && canGoToBelowVC {
                moveFromViewController(currentVCForGesture!, toViewController: belowVC!, direction: direction, side: side)
                aboveVC?.willMoveToParentViewController(nil)
                aboveVC?.removeFromParentViewController()
            } else if direction == .Up && canGoToAboveVC {
                moveFromViewController(currentVCForGesture!, toViewController: aboveVC!, direction: direction, side: side)
                belowVC?.willMoveToParentViewController(nil)
                belowVC?.removeFromParentViewController()
            } else {
                resetToCurrentVC = true
            }
            swipe = false
        }
        else {
            if currentVCForGesture!.view.frame.origin.y <= -halfwayMark {
                moveFromViewController(currentVCForGesture!, toViewController: belowVC!, direction: .Down, side: side)
                aboveVC?.willMoveToParentViewController(nil)
                aboveVC?.removeFromParentViewController()
            } else if currentVCForGesture!.view.frame.origin.y > halfwayMark {
                moveFromViewController(currentVCForGesture!, toViewController: aboveVC!, direction: .Up, side: side)
                belowVC?.willMoveToParentViewController(nil)
                belowVC?.removeFromParentViewController()
            } else {
                resetToCurrentVC = true
            }
        }
        if resetToCurrentVC {
            if currentVCForGesture!.view.frame.origin.y > 0 {
                moveFromViewController(aboveVC!, toViewController: currentVCForGesture!, direction: .Down, side: side)
                belowVC?.willMoveToParentViewController(nil)
                belowVC?.removeFromParentViewController()
            } else if currentVCForGesture!.view.frame.origin.y < 0 {
                moveFromViewController(belowVC!, toViewController: currentVCForGesture!, direction: .Up, side: side)
                aboveVC?.willMoveToParentViewController(nil)
                aboveVC?.removeFromParentViewController()
            }
        }
    }
    
    /**
    While the gesture is occuring, determine if we should move the view controllers along with it

    :param: sender
    */
    private func continueTransition(sender:UIPanGestureRecognizer) {
        var yOffset = sender.translationInView(view).y
        var applyOffset = false
        
        if yOffset > 0 {
            if canGoToAboveVC || (currentVCForGesture!.view.frame.origin.y < 0) {
                applyOffset = true
                if (currentVCForGesture!.view.frame.origin.y < 0) && (currentVCForGesture!.view.frame.origin.y + yOffset > 0) {
                    yOffset = -(currentVCForGesture!.view.frame.origin.y)
                }
            }
        } else if yOffset < 0 {
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
    
    /**
    Called when a gesture ends to transistion from one view controller to another.
    */
    private func moveFromViewController(vc: UIViewController, toViewController: UIViewController, direction: Direction, side: VerticalPagingSplitModel.Side) {
        let forward : Bool
        let directionEndFrame : CGRect
        let transitionDuration = 0.4
        
        vc.willMoveToParentViewController(nil)
        if direction == .Up {
            forward = false
            directionEndFrame = downDirectionEndFrame
        }
        else {
            forward = true
            directionEndFrame = upDirectionEndFrame
        }
        
        transitionFromViewController(vc, toViewController: toViewController, duration: transitionDuration, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
                toViewController.view.frame = self.normalEndFrame
                vc.view.frame = directionEndFrame
                }, completion:{ (finished: Bool) -> Void in
                    if self.currentVCForGesture != toViewController {
                        self.model.updateVC(side,forward: forward)
                        if side == .Left {
                            self.currentLeftVC = toViewController
                        } else {
                            self.currentRightVC = toViewController
                        }
                    }
                    vc.removeFromParentViewController()
                    toViewController.didMoveToParentViewController(self)
        })
    }
}












