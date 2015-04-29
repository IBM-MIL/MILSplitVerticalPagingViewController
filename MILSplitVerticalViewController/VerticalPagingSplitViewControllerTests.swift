/*
Licensed Materials - Property of IBM
© Copyright IBM Corporation 2015. All Rights Reserved.
*/

import UIKit
import XCTest


class VerticalPagingSplitViewControllerTests: XCTestCase {
    
    func testViewDidLoad()
    {
        let vpsvc = VerticalPagingSplitViewController()
        XCTAssertNotNil(vpsvc.view, "View Did Not load")
    }
    
    func testIdentifiers()
    {
        let vpsm = VerticalPagingSplitModel()

        //Check the current left controller identifier
        XCTAssertEqual("LeftViewController2", vpsm.getCurrentViewControllerIdentifier(VerticalPagingSplitModel.Side.Left))

        //Check the next right controller identifier
        XCTAssertEqual("RightViewController3", vpsm.getNextViewControllerIdentifier(VerticalPagingSplitModel.Side.Right))

        //Check the previous right controller identifier
        XCTAssertEqual("RightViewController1", vpsm.getPreviousViewControllerIdentifier(VerticalPagingSplitModel.Side.Right))
    }

    func testUpdates()
    {
        let vpsm = VerticalPagingSplitModel()
        
        //Increment the left side controller
        vpsm.updateVC(VerticalPagingSplitModel.Side.Left,forward: true)
        
        //Check that the array is now on the last element
        XCTAssertEqual(vpsm.isLastVC(VerticalPagingSplitModel.Side.Left),true)
        
        //Decrement the right side controller
        vpsm.updateVC(VerticalPagingSplitModel.Side.Right,forward: false)
        
        //Check that the array is now on the first element
        XCTAssertEqual("RightViewController1", vpsm.getCurrentViewControllerIdentifier(VerticalPagingSplitModel.Side.Right))
    }
    
}
