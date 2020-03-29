//
//  SupportClass.swift
//  ginzaWindRegistration
//
//  Created by Hudihka on 15/01/2019.
//  Copyright © 2019 Username. All rights reserved.
//

import UIKit


let hDdevice = UIScreen.main.bounds.size.height
let wDdevice = UIScreen.main.bounds.size.width

let expansionAudio = "itMS.Sound-recording.m4a"


var getHKey: Int {

    //без автокоррекцией
    switch hDdevice {
    case 896: return 267//XMAX
    case 812: return 257//X
    case 736: return 226//7+/8+
    case 667: return 216//7/8
    case 568: return 216//5
    default: return 253
    }
}


var getHKeyAutokorec: Int {

    //с автокоррекции
    switch hDdevice {
    case 896: return 317//XMAX
    case 812: return 302//X
    case 736: return 271//7+/8+
    case 667: return 260//7/8
    case 568: return 253//5
    default: return 253
    }
}

var isIPhone5: Bool {
    return hDdevice == 568
}

var isIPhoneXorXmax: Bool {
    return hDdevice >= 812
}

var indentNavigationBarHeight: CGFloat {
    return statusBarHeight + navigBarHeight //88 : 64
}

var statusBarHeight: CGFloat{
    return isIPhoneXorXmax ? 44 : 20
}

let navigBarHeight: CGFloat = 44

var heightTabBar: CGFloat {
    return isIPhoneXorXmax ? 84 : 58
}

let tickWidth: CGFloat = 5



let colorTabBar           = UIColor(red: 17/255, green: 41/255, blue: 87/255, alpha: 1)

let colorBacground        = UIColor(red: 34/255, green: 34/255, blue: 34/255, alpha: 1)

let colorGrienButton      = UIColor(red: 108/255, green: 169/255, blue: 75/255, alpha: 1)
let colorGrienBlockButton = UIColor(red: 68/255, green: 133/255, blue: 31/255, alpha: 1)

let whiteBlock            = UIColor(red: 139/255, green: 141/255, blue: 144/255, alpha: 1)

let graySwitch            = UIColor(red: 128/255, green: 130/255, blue: 133/255, alpha: 1)
let grayTabBar            = UIColor(red: 47/255, green: 47/255, blue: 47/255, alpha: 1)
let grayBlock             = UIColor(red: 51/255, green: 51/255, blue: 51/255, alpha: 1)
let gray                  = UIColor(red: 63/255, green: 63/255, blue: 63/255, alpha: 1)


let red                   = UIColor(red: 235/255, green: 0/255, blue: 41/255, alpha: 1)
let gold                  = UIColor(red: 255/255, green: 173/255, blue: 38/255, alpha: 1)

let separator             = UIColor(red: 63/255, green: 63/255, blue: 63/255, alpha: 1)

