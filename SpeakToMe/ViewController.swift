//
//  ViewController.swift
//  SpeakToMe
//
//  Created by Alexei Gudimenko on 26/6/18.
//  Copyright © 2018 Alexei Gudimenko. All rights reserved.
//

import UIKit
import Speech

class ViewController: UIViewController, SFSpeechRecognizerDelegate {
  
  @IBOutlet weak var textLabel: UILabel!
  @IBOutlet weak var recordButton: UIButton!
  
  
  private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-AU"))!
  private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
  private var recognitionTask: SFSpeechRecognitionTask?
  private let audioEngine = AVAudioEngine()
  
  private let defaultRoutingBus = 0
  private let defaultBufferSize: AVAudioFrameCount = 1024
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    recordButton.isEnabled = false
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    speechRecognizer.delegate = self
    
    SFSpeechRecognizer.requestAuthorization { authStatus in
      
      OperationQueue.main.addOperation {
        switch authStatus {
        case .authorized:
          self.recordButton.isEnabled = true
          
        case .denied:
          self.recordButton.isEnabled = false
          self.recordButton.setTitle("User denied access to speech recognition", for: .disabled)
          
        case .restricted:
          self.recordButton.isEnabled = false
          self.recordButton.setTitle("Speech recognition restricted on this device", for: .disabled)
          
        case .notDetermined:
          self.recordButton.isEnabled = false
          self.recordButton.setTitle("Speech recognition not yet authorized", for: .disabled)
        }
      }
    } // end auth request
  }
  
  private func startRecording() throws {
    
    // Cancel the previous task if it's running
    // cancelRunningRecTasks()
    if let recognitionTask = recognitionTask {
      recognitionTask.cancel()
      self.recognitionTask = nil
    }
    
    // prepareAudioSession()
    let audioSession = AVAudioSession.sharedInstance()
    try audioSession.setCategory(AVAudioSessionCategoryRecord)
    try audioSession.setMode(AVAudioSessionModeMeasurement)
    try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
    
    // setupRecognitionRequest()
    recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
    
    // setupInputNode()
    let inputNode = audioEngine.inputNode
    
    // verifyRecognitionRequest()
    guard let recognitionRequest = recognitionRequest else {
      fatalError("Unable to created a SFSpeechAudioBufferRecognitionRequest object")
    }
    
    recognitionRequest.shouldReportPartialResults = true
    
    // A recognition task represents a speech recognition session.
    // We keep a reference to the task so that it can be cancelled.
    recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
      var isFinal = false
      
      if let result = result {
        self.textLabel.text = result.bestTranscription.formattedString
        isFinal = result.isFinal
      }
      
      if error != nil || isFinal {
        self.audioEngine.stop()
        inputNode.removeTap(onBus: self.defaultRoutingBus)
        
        self.recognitionRequest = nil
        self.recognitionTask = nil
        
        self.recordButton.isEnabled = true
        self.recordButton.setTitle("Start Recording", for: [])
      }
    }
    
    let recordingFormat = inputNode.outputFormat(forBus: defaultRoutingBus)
    
    inputNode.installTap(onBus: defaultRoutingBus, bufferSize: defaultBufferSize, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
      self.recognitionRequest?.append(buffer)
    }
    
    audioEngine.prepare()
    
    try audioEngine.start()
    
    textLabel.text = "Go ahead, I'm listening!"
  } // end 'start recording'
  
  
  public func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
    if available {
      recordButton.isEnabled = true
      recordButton.setTitle("Start Recording", for: [])
    } else {
      recordButton.isEnabled = false
      recordButton.setTitle("Recognition not available", for: .disabled)
    }
  }
  
  
  @IBAction func recordButtonTapped() {
    if audioEngine.isRunning {
      stopRecording()
      recordButton.isEnabled = false
      recordButton.setTitle("Stopping", for: .disabled)
    } else {
      try! startRecording()
      recordButton.setTitle("Stop recording", for: [])
    }
  }
  
  private func stopRecording() {
    audioEngine.stop()
    recognitionRequest?.endAudio()
  }
}

