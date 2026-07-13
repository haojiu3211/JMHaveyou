//
//  CGFloat+Ext.swift
//  haveseeyou
//
//  Created by admin on 2026/5/14.
//

import UIKit

extension CGFloat {

    var fit: CGFloat {
        return self * UIScreen.main.bounds.width / 375.0
    }
}

extension Int {

    var fit: CGFloat {
        return CGFloat(self).fit
    }
}

extension Double {

    var fit: CGFloat {
        return CGFloat(self).fit
    }
}
