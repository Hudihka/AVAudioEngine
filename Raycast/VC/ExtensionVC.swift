//
//  ExtensionVC.swift
//  Raycast
//
//  Created by Hudihka on 29/03/2020.
//  Copyright © 2020 Razeware. All rights reserved.
//

import Foundation

//
extension ViewController {

  func formatted(time: Float) -> String {
    var secs = Int(ceil(time))
    var hours = 0
    var mins = 0

    if secs > TimeConstant.secsPerHour {
      hours = secs / TimeConstant.secsPerHour
      secs -= hours * TimeConstant.secsPerHour
    }

    if secs > TimeConstant.secsPerMin {
      mins = secs / TimeConstant.secsPerMin
      secs -= mins * TimeConstant.secsPerMin
    }

    var formattedString = ""
    if hours > 0 {
      formattedString = "\(String(format: "%02d", hours)):"
    }
    formattedString += "\(String(format: "%02d", mins)):\(String(format: "%02d", secs))"
    return formattedString
  }
}
