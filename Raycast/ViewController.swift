/// Copyright (c) 2017 Razeware LLC
///
/// THE SOFTWARE.

import UIKit
import AVFoundation

class ViewController: UIViewController {

  // MARK: Outlets
  @IBOutlet weak var playPauseButton: UIButton!
  @IBOutlet weak var progressBar: UIProgressView!
  @IBOutlet weak var meterView: UIView!
  @IBOutlet weak var volumeMeterHeight: NSLayoutConstraint!
  @IBOutlet weak var countUpLabel: UILabel!
  @IBOutlet weak var countDownLabel: UILabel!
	
	@IBOutlet weak var fatProgressBar: UIProgressView!

  // MARK: AVAudio properties
  var engine = AVAudioEngine()
	
  var player = AVAudioPlayerNode()

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
  var audioSampleRate: Float = 0 //количество сейплов в секунде
  var audioLengthSeconds: Float = 0 //количество секунд
  var audioLengthSamples: AVAudioFramePosition = 0 //количество аудио сейплов в файле
  var needsFileScheduled = true

  var updater: CADisplayLink?
	
	//текущее время воспроизведения
	
  var currentFrame: AVAudioFramePosition {
		 // 1
		guard let lastRenderTime = player.lastRenderTime,
					let playerTime = player.playerTime(forNodeTime: lastRenderTime) else {
						
				 return  0
		}
		
		// время как количество аудиосэмплов в аудиофайле.
		return playerTime.sampleTime
	}
	
	
  var skipFrame: AVAudioFramePosition = 0
  var currentPosition: AVAudioFramePosition = 0


  enum TimeConstant {
    static let secsPerMin = 60
    static let secsPerHour = TimeConstant.secsPerMin * 60
  }

  // MARK: - ViewController lifecycle
  //
  override func viewDidLoad() {
    super.viewDidLoad()
		
		
//		апдейт лейблов
    countUpLabel.text = formatted(time: 0)
    countDownLabel.text = formatted(time: audioLengthSeconds)
		
    setupAudio()
		
		//обновление UI
		updater = CADisplayLink(target: self, selector: #selector(updateUI))
		updater?.add(to: .current, forMode: .defaultRunLoopMode)
		updater?.isPaused = true
		
		
		addCollection()
  }
	
	
	private func addCollection(){
		fatProgressBar.transform = fatProgressBar.transform.scaledBy(x: 1, y: 10)
		
		//сделано  только для айфона 8+
		
		let width: CGFloat = 376
		
		let customFramme = CGRect(x: 20,
															y: 495,
															width: width,
															height: 20)
		
		let max: Int = Int(width / tickWidth) - 1
		let arrayData: [CGFloat] = (0...max).map({_ in CGFloat.random(in: 0...1)})
		
		let CV = CollectionTiks(frame: customFramme, dataArray: arrayData)
		
		self.view.addSubview(CV)
	}


}

// MARK: - Actions
//
extension ViewController {

  @IBAction func playTapped(_ sender: UIButton) {
		
		sender.isSelected = !sender.isSelected

		// 2
		if player.isPlaying {
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
	

  @objc func updateUI() {
		
		/*Свойство skipFrame представляет собой смещение,
		добавленное или вычтенное из currentFrameпервоначально установленного на ноль.
		Убедитесь, что currentPositionне выходит за пределы диапазона файла.*/

		currentPosition = currentFrame + skipFrame
		currentPosition = max(currentPosition, 0)
		currentPosition = min(currentPosition, audioLengthSamples)

		// прогресс бар
		progressBar.progress = Float(currentPosition) / Float(audioLengthSamples)
		fatProgressBar.progress = Float(currentPosition) / Float(audioLengthSamples)
		let time = Float(currentPosition) / audioSampleRate
		
//		формат лейблов
		countUpLabel.text = formatted(time: time)
		countDownLabel.text = formatted(time: audioLengthSeconds - time)

		// если аудио файл проигран до конца
		if currentPosition >= audioLengthSamples {
			player.stop()
			updater?.isPaused = true
			playPauseButton.isSelected = false
		}

		
  }
}



// MARK: - Audio
//
extension ViewController {
	//базовые настройки аудио
  func setupAudio() {
		
		// 1
		audioFileURL = Bundle.main.url(forResource: "Тони Раут & Иван Рейс - Шот", withExtension: "mp3")

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
	
	
	//MARK: - МОЩНОСТЬ АУДИО СЭМПЛА
	

  func connectVolumeTap() {
		// Получить формат данных для mainMixerNodeвывода.
		let format = engine.mainMixerNode.outputFormat(forBus: 0)
		
		// buffer.frameLength фактический размер буффера
		// when время захвата буфера
		engine.mainMixerNode.installTap(onBus: 0, bufferSize: 1024, format: format) {[weak self] buffer, _ in

      self?.valueBuffer(buffer: buffer, value100Procent: 26, completion: { (float) in
        self?.volumeMeterHeight.constant = float
      })
      
		}
		
  }
  
  
  private func valueBuffer(buffer: AVAudioPCMBuffer, value100Procent: Float, completion:@escaping((CGFloat) -> Void)){
    
    guard let channelData = buffer.floatChannelData else { //buffer.floatChannelData массив указателей на данные каждого образца
        completion(0)
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
    let meterLevel = avgPower.scaledPower
    let returnValue = min((meterLevel * value100Procent), value100Procent)
    
    DispatchQueue.main.async {
      completion(CGFloat(returnValue))
    }
    
  }


}


extension Float{
  
  /*
  преобразует отрицательное powerзначение в децибелах
  в положительное значение, которое корректирует
  volumeMeterHeight.constantзначение выше
  */
  var scaledPower: Float {
    // это конечное значение
    guard self.isFinite else { return 0.0 }
    
    let minDb: Float = -80.0

    // 2
    if self < minDb {
      return 0.0
    } else if self >= 1.0 {
      return 1.0
    } else {
      //  значение между 0,0 и 1,0.
      return (fabs(minDb) - fabs(self)) / fabs(minDb)
    }
  }
  
  
  
  
}
