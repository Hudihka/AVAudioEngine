//
//  ViewTicks.swift
//  Sound recording
//
//  Created by Username on 17.02.2020.
//  Copyright © 2020 itMegastar. All rights reserved.
//

import UIKit

class CollectionTiks: UICollectionView, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

	init(frame: CGRect) {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        super.init(frame: frame, collectionViewLayout: layout)

        self.baseSettingsCV(obj: self,
                                      scrollEnabled: false,
                                      clicableCell: false,
                                      arrayNameCell: ["TickCell"])


        translatesAutoresizingMaskIntoConstraints = false
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0

        layout.estimatedItemSize = CGSize(width: tickWidth, height: self.frame.height)


        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
       return Int(self.frame.width / tickWidth)
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TickCell", for: indexPath) as! TickCell

        cell.procent = CGFloat(arc4random_uniform(79)) + 20

        return cell
    }


}

