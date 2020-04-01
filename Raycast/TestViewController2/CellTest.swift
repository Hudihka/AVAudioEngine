//
//  CellTest.swift
//  Raycast
//
//  Created by Hudihka on 02/04/2020.
//  Copyright © 2020 Razeware. All rights reserved.
//

import UIKit

class CellTest: UITableViewCell {

	@IBOutlet weak var constreint: NSLayoutConstraint!
	
	var procent: Float = 0 {
		didSet{
			constreint.constant = CGFloat(procent) * wDdevice
		}
	}
	
	
	
	override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }


    
}
