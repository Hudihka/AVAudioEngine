/// Copyright (c) 2017 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit
import AVFoundation

class ViewController: UIViewController {

  // MARK: Outlets
  @IBOutlet weak var playPauseButton: UIButton!
  @IBOutlet weak var skipForwardButton: UIButton!
  @IBOutlet weak var skipBackwardButton: UIButton!
  @IBOutlet weak var progressBar: UIProgressView!
  @IBOutlet weak var meterView: UIView!
  @IBOutlet weak var volumeMeterHeight: NSLayoutConstraint!
  @IBOutlet weak var rateSlider: UISlider!
  @IBOutlet weak var rateLabel: UILabel!
  @IBOutlet weak var rateLabelLeading: NSLayoutConstraint!
  @IBOutlet weak var countUpLabel: UILabel!
  @IBOutlet weak var countDownLabel: UILabel!

  // MARK: AVAudio properties
  var engine = AVAudioEngine()
	
  var player = AVAudioPlayerNode()
  var rateEffect = AVAudioUnitTimePitch()

  var audioFile: AVAudioFile? {
    didSet {
      if let audioFile = audioFile {
        audioLengthSamples = audioFile.length
        audioFormat = audioFile.processingFormat
        audioSampleRate = Float(audioFormat?.sampleRate ?? 44100)
        audioLengthSeconds = Float(audioLengthSamples) / audioSampleRate
      }
    }
  }
  var audioFileURL: URL? {
    didSet {
      if let audioFileURL = audioFileURL {
        audioFile = try? AVAudioFile(forReading: audioFileURL)
      }
    }
  }
  var audioBuffer: AVAudioPCMBuffer?

  // MARK: other properties
  var audioFormat: AVAudioFormat?
  var audioSampleRate: Float = 0
  var audioLengthSeconds: Float = 0
  var audioLengthSamples: AVAudioFramePosition = 0
  var needsFileScheduled = true
  let rateSliderValues: [Float] = [0.5, 1.0, 1.25, 1.5, 1.75, 2.0, 2.5, 3.0]
  var rateValue: Float = 1.0 {
    didSet {
      rateEffect.rate = rateValue
      updateRateLabel()
    }
  }
  var updater: CADisplayLink?
  var currentFrame: AVAudioFramePosition {
		 // 1
		guard let lastRenderTime = player.lastRenderTime,
					let playerTime = player.playerTime (forNodeTime: lastRenderTime)
			
			 else {
				 return  0
		}
		
		// время как количество аудиосэмплов в аудиофайле.
		return playerTime.sampleTime
	}
	
	
  var skipFrame: AVAudioFramePosition = 0
  var currentPosition: AVAudioFramePosition = 0
  let pauseImageHeight: Float = 26.0
  let minDb: Float = -80.0

  enum TimeConstant {
    static let secsPerMin = 60
    static let secsPerHour = TimeConstant.secsPerMin * 60
  }

  // MARK: - ViewController lifecycle
  //
  override func viewDidLoad() {
    super.viewDidLoad()

    setupRateSlider()
    countUpLabel.text = formatted(time: 0)
    countDownLabel.text = formatted(time: audioLengthSeconds)
		
    setupAudio()
		
		//обновление UI
		updater = CADisplayLink(target: self, selector: #selector(updateUI))
		updater?.add(to: .current, forMode: .defaultRunLoopMode)
		updater?.isPaused = true
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    updateRateLabel()
  }
}

// MARK: - Actions
//
extension ViewController {
  @IBAction func didChangeRateValue(_ sender: UISlider) {
    let index = round(sender.value)
    rateSlider.setValue(Float(index), animated: false)
    rateValue = rateSliderValues[Int(index)]
  }

  @IBAction func playTapped(_ sender: UIButton) {
		
		sender.isSelected = !sender.isSelected

		// 2
		if player.isPlaying {
			disconnectVolumeTap()
			updater?.isPaused = true
			player.pause ()
		} else {
			 if needsFileScheduled {
				needsFileScheduled = false
				scheduleAudioFile ()
			}
			connectVolumeTap()
			updater?.isPaused = false
			
			player.play ()
		}
		
  }

  @IBAction func plus10Tapped(_ sender: UIButton) {
    guard let _ = player.engine else { return }
    seek(to: 10.0)
  }

  @IBAction func minus10Tapped(_ sender: UIButton) {
    guard let _ = player.engine else { return }
    needsFileScheduled = false
    seek(to: -10.0)
  }

  @objc func updateUI() {
		
		/*Свойство skipFrameпредставляет собой смещение,
		добавленное или вычтенное из currentFrameпервоначально установленного на ноль.
		Убедитесь, что currentPositionне выходит за пределы диапазона файла.*/

		currentPosition = currentFrame + skipFrame
		currentPosition = max(currentPosition, 0)
		currentPosition = min(currentPosition, audioLengthSamples)

		// прогресс бар
		progressBar.progress = Float(currentPosition) / Float(audioLengthSamples)
		let time = Float(currentPosition) / audioSampleRate
		countUpLabel.text = formatted(time: time)
		countDownLabel.text = formatted(time: audioLengthSeconds - time)

		// если аудио файл проигран до конца
		if currentPosition >= audioLengthSamples {
			player.stop()
			updater?.isPaused = true
			playPauseButton.isSelected = false
			disconnectVolumeTap() //disconnectVolumeTap
		}

		
  }
}

// MARK: - Display related
//
extension ViewController {
  func setupRateSlider() {
    let numSteps = rateSliderValues.count-1
    rateSlider.minimumValue = 0
    rateSlider.maximumValue = Float(numSteps)
    rateSlider.isContinuous = true
    rateSlider.setValue(1.0, animated: false)
    rateValue = 1.0
    updateRateLabel()
  }

  func updateRateLabel() {
    rateLabel.text = "\(rateValue)x"
    let trackRect = rateSlider.trackRect(forBounds: rateSlider.bounds)
    let thumbRect = rateSlider.thumbRect(forBounds: rateSlider.bounds , trackRect: trackRect, value: rateSlider.value)
    let x = thumbRect.origin.x + thumbRect.width/2 - rateLabel.frame.width/2
    rateLabelLeading.constant = x
  }

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

// MARK: - Audio
//
extension ViewController {
	//базовые настройки аудио
  func setupAudio() {
		
		// 1
		audioFileURL = Bundle.main.url(forResource: "Intro", withExtension: "mp4")

		// 2
		engine.attach(player)
		engine.connect(player, to: engine.mainMixerNode, format: audioFormat)
		engine.prepare() //предварительно распределяет необходимые ресурсы

		do {
			try engine.start()
		} catch let error {
			print(error.localizedDescription)
		}
		
  }

  func scheduleAudioFile() {
		
		//старт воспроизведения
		guard let audioFile = audioFile else { return }

		skipFrame = 0											//nil значит воспроизведение немедленно
		player.scheduleFile(audioFile, at: nil) { [weak self] in
//			воспроизведение завершенно
			self?.needsFileScheduled = true
		}
		
  }

  func connectVolumeTap() {
		// Получить формат данных для mainMixerNodeвывода.
		let format = engine.mainMixerNode.outputFormat(forBus: 0)
		
		
		// buffer.frameLength фактический размер буффера
		// when время захвата буфера
		engine.mainMixerNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, when in
			// 3
			guard
				let channelData = buffer.floatChannelData, //buffer.floatChannelData массив указателей на данные каждого образца
				let updater = self.updater
				else {
					return
			}

			let channelDataValue = channelData.pointee
			// переделываем ма массив данных в массив флоат
			//получаем массив флоатов от 0 до длинны буфера(не включая его) с шагом buffer.stride
			let channelDataValueArray = stride(from: 0,
																				 to: Int(buffer.frameLength), //buffer.stride Количество буферных чередующихся каналов.
																				 by: buffer.stride).map{ channelDataValue[$0] }
			//возводим каждое значение в квадрат
			//складывапем их, делим на длинну буфера
			//и извлекаем квадратный корень
			let all = channelDataValueArray.map{ $0 * $0 }.reduce(0, +) / Float(buffer.frameLength)
			
			//Преобразовать среднеквадратичное значение в децибелы ( ссылка на акустический децибел ) Это должно быть значение от -160 до 0
			
			let avgPower = 20 * log10(sqrt(all))
			// преобразуем значение от 0 до 1
			let meterLevel = self.scaledPower(power: avgPower)

			DispatchQueue.main.async {
				
//				получаем миниимальное значение и выставляем его
//				где self.pauseImageHeight = 26 это 100% высота
				
				self.volumeMeterHeight.constant = !updater.isPaused ?
							 CGFloat(min((meterLevel * self.pauseImageHeight), self.pauseImageHeight)) : 0.0
			}
		}
		
  }
	
	
	//MARK: - МОЩНОСТЬ АУДИО СЭМПЛА
	/*
	преобразует отрицательное powerзначение в децибелах
	в положительное значение, которое корректирует
	volumeMeterHeight.constantзначение выше
	*/
	func scaledPower(power: Float) -> Float {
		// это конечное значение
		guard power.isFinite else { return 0.0 }

		// 2
		if power < minDb {
			return 0.0
		} else if power >= 1.0 {
			return 1.0
		} else {
			//  значение между 0,0 и 1,0.
			return (fabs(minDb) - fabs(power)) / fabs(minDb)
		}
	}

  func disconnectVolumeTap() {
  }

  func seek(to time: Float) {
  }

}
