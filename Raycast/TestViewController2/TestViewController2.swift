//
//  TestViewController2.swift
//  Raycast
//
//  Created by Hudihka on 02/04/2020.
//  Copyright © 2020 Razeware. All rights reserved.
//

import UIKit

class TestViewController2: UIViewController {
	
	@IBOutlet weak var tableView: UITableView!
	var dataArray = [Float]()

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let path = Bundle.main.path(forResource: "test2", ofType:"mp3") else {
			fatalError("Couldn't find the file path")
		}
		
		desinTableview()
		
		let render = Render()
		
		let url = URL(fileURLWithPath: path)
		var outputArray : [Float] = []
		AudioContext.load(fromAudioURL: url, completionHandler: { audioContext in
			
			guard let audioContext = audioContext else {
				fatalError("Couldn't create the audioContext")
			}
			outputArray = render.render(audioContext: audioContext, targetSamples: 300)
			outputArray = outputArray.map({20 * log10(abs($0))})
			
			self.dataArray = outputArray.reloadProcent
			
			DispatchQueue.main.async {
				self.tableView.reloadData()
			}
			
			
		})
    }
    


}


extension TestViewController2: UITableViewDelegate, UITableViewDataSource{
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return dataArray.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "CellTest", for: indexPath) as! CellTest
		
		cell.procent = dataArray[indexPath.row]
		
		return cell
	}
	
	
	func desinTableview(){
		
		self.tableView.delegate = self
		self.tableView.dataSource = self
		
		self.tableView.register(UINib(nibName: "CellTest", bundle: nil), forCellReuseIdentifier: "CellTest")
	}
	
	
	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return 5
	}
	
	
	
}


extension Array where Element == Float {
	var reloadProcent: [Float]{
		
		if let max = self.max(by: {$0 < $1}) {
			return self.map({$0 / max})
		}
		
		return []
		
	}
}


