/*
Licensed Materials - Property of IBM
© Copyright IBM Corporation 2015. All Rights Reserved.
*/

import Foundation

/**
*  Manages the available controllers and the current index for each side
*/
class VerticalPagingSplitModel {
    
    //////////////////////////////////////////////////////////////////////////////
    // These are the variables you should change to customize the view controller.
    //////////////////////////////////////////////////////////////////////////////
    var currentLeftVCIndex = 1
    var currentRightVCIndex = 1
    let leftViewControllers = ["LeftViewController1", "LeftViewController2", "LeftViewController3"]
    let rightViewControllers = ["RightViewController1", "RightViewController2", "RightViewController3"]

    enum Side {
        case Left
        case Right
    }
    
    /**
    :param: side The side panel to check (left or right)
    
    :returns: True if the current index is set to the first element of the view controllers on the side
    */
    func isFirstVC(side: Side) -> Bool {
        return side == .Left ? currentLeftVCIndex == 0 : currentRightVCIndex == 0
    }
    
    /**
    :param: side The side panel to check (left or right)
    
    :returns: True if the current index is set to the last element  of the view controllers on the side
    */
    func isLastVC(side: Side) -> Bool {
        return side == .Left ? currentLeftVCIndex == leftViewControllers.count - 1 : currentRightVCIndex == rightViewControllers.count - 1
    }
    
    /**
    :param: side The side to check (left or right)
    
    :returns: the identifier for the current view controller on the side
    */
    func getCurrentViewControllerIdentifier(side: Side) -> String {
        return side == .Left ? leftViewControllers[currentLeftVCIndex] : rightViewControllers[currentRightVCIndex]
    }

    /**
    :param: side The side to check (left or right)
    
    :returns: the identifier for the previous view controller on the side
    */
    func getPreviousViewControllerIdentifier(side: Side) -> String {
        assert(!isFirstVC(side), "Cannot retrieve previous view controller identified when the first array element is selected.")
        return side == .Left ? leftViewControllers[currentLeftVCIndex - 1] : rightViewControllers[currentRightVCIndex - 1]
    }

    /**
    :param: side The side to check (left or right)
    
    :returns: the identifier for the next view controller on the side
    */
    func getNextViewControllerIdentifier(side: Side) -> String {
        assert(!isLastVC(side), "Cannot retrieve the next view controller identified when the last array element is selected.")
        return side == .Left ? leftViewControllers[currentLeftVCIndex + 1] : rightViewControllers[currentRightVCIndex + 1]
    }
    
    /**
    :param: side    The side to check (left or right)
    :param: forward Set to true to increment the array index, false to decrement
    */
    func updateVC(side:Side, forward:Bool) {
        if (forward == true) {
            assert(!isLastVC(side),"Cannot increment view controller index when already set to last element.")
            if (side == .Left)
            {
                currentLeftVCIndex++
            }
            else {
                currentRightVCIndex++
            }
        }
        else {
            assert(!isFirstVC(side),"Cannot decrement view controller index when already set to first element.")
            if (side == .Left)
            {
                currentLeftVCIndex--
            }
            else {
                currentRightVCIndex--
            }
        }
    }
}