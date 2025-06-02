//
//  ViewController.swift
//  Live2DSDK
//
//  Created by NY on 03/06/2025.
//  Copyright (c) 2025 NY. All rights reserved.
//

import UIKit
import Live2DSDK
//import GLKit

import AVFoundation // TTS
import Speech     // STT // STT
import AVFAudio

import Combine

// 顶级响应结构体
struct ChatCompletionError: Codable {
    let message: String?
    let code: Int?
    enum CodingKeys: String, CodingKey {
        case message, code
    }
}

struct ChatCompletionResponse: Codable {
    let error: ChatCompletionError?
    let id: String?
    let provider: String?
    let model: String?
    let object: String?
    let created: Int?
    let choices: [Choice]?
    let usage: Usage?
    let user_id: String?
    enum CodingKeys: String, CodingKey {
        case id, provider, model, object, created, choices, usage, error, user_id
    }
}

// Choice 结构体
struct Choice: Codable {
    let logprobs: Logprobs?
    let finishReason: String?
    let nativeFinishReason: String?
    let index: Int?
    let message: Message?
    let refusal: String?
    let reasoning: String?
    
    enum CodingKeys: String, CodingKey {
        case logprobs
        case finishReason = "finish_reason"
        case nativeFinishReason = "native_finish_reason"
        case index, message, refusal, reasoning
    }
}

// Logprobs 结构体（处理 null）
struct Logprobs: Codable {
    let value: Bool? // JSON 中为 null，设为可选类型
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.value = try? container.decode(Bool.self)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encodeNil()
    }
}

// Message 结构体
struct Message: Codable {
    let role: String
    let content: String
}

// Usage 结构体
struct Usage: Codable {
    let promptTokens: Int
    let completionTokens: Int
    let totalTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
    }
}

class ViewController: UIViewController {
    var count = 0
        
    // TTS
    private let synthesizer = AVSpeechSynthesizer()
    private let audioEngine = AVAudioEngine()
    private var amplitudes: [Float] = []
    private var keyboardObserver: KeyboardObserver =  KeyboardObserver()
    private var cancellables = Set<AnyCancellable>()
    
    // 定义 UISlider
    private let slider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0.0 // 最小值
        slider.maximumValue = 1.0 // 最大值
        slider.value = 0.5        // 默认值
        slider.translatesAutoresizingMaskIntoConstraints = false
        return slider
    }()
    
    lazy var speakBtn: UIButton = {
        let speakButton = UIButton(frame: .zero)// Speak Button
        speakButton.setTitle("Speak", for: .normal)
        speakButton.addTarget(self, action: #selector(speakText), for: .touchUpInside)
        return speakButton
    }()
    
    lazy var textView : UITextView = {
        // TextView 用于显示和输入文字
        let textView = UITextView(frame: .zero)
        textView.layer.borderColor = UIColor.gray.cgColor
        textView.layer.borderWidth = 1
        textView.layer.cornerRadius = 8
        textView.font = .systemFont(ofSize: 16)
        textView.text = "Hi,welcome! Let’s start the AI ​​journey together~"
        return textView
    }()
    
    lazy var inputWrapper: UIView = {
        let v = UIView(frame: .zero)
        return v
    }()
    
    lazy var aiAnswerTV: UITextView = {
        let textView = UITextView(frame: .zero)
        // 设置背景色和默认文本
        textView.backgroundColor = .black.withAlphaComponent(0.5)
        textView.text = ""
        textView.layer.cornerRadius = 8
        textView.showsVerticalScrollIndicator = true
        textView.isEditable = false
        textView.isHidden = true
        textView.textColor = .white
        textView.font = UIFont.systemFont(ofSize: 20)
        return textView
    }()
    
    var inputWrapperEndRect = CGRect()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        requestPermissions()
        setupAudioSession()
        keyboardObserver.keyboardHeightPublisher
            .sink { [weak self] keyRect in
                guard let `self` = self else { return }

                
                var rect = self.inputWrapperEndRect
                let keyboardH =  keyRect.size.height
                if keyRect.origin.y >= UIScreen.main.bounds.height {
                    rect = self.inputWrapperEndRect
                } else {
                    rect.origin.y =  UIScreen.main.bounds.height - keyboardH - self.inputWrapperEndRect.height
                }
                UIView.animate(withDuration: 0.35) {
                    self.inputWrapper.frame = rect
                } completion: { success in
    
                }
            }.store(in: &cancellables)

    }
    
 
    
    func setupUI() {
//        EAGLContext.setCurrent(EAGLContext(api: .openGLES2))
        self.view.addSubview(NYLDSDKManager.shared().stageVC.view)
        let w = (UIScreen.main.bounds.size.width - 45 )/2.0
        let btn = UIButton(frame: CGRect(x: 15, y: UIScreen.main.bounds.size.height - 50 - 60, width: w, height: 50))
        btn.setTitle("Change Background", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = .blue.withAlphaComponent(0.5)
        btn.addTarget(self, action: #selector(changeBackground), for: .touchUpInside)
        self.view.addSubview(btn)
        
        let mbtn = UIButton(frame: CGRect(x: w + 30, y:  UIScreen.main.bounds.size.height - 50 - 60, width: w, height: 50))
        mbtn.setTitle("Change Model", for: .normal)
        mbtn.setTitleColor(.white, for: .normal)
        mbtn.backgroundColor = .blue.withAlphaComponent(0.5)
        mbtn.addTarget(self, action: #selector(changeModel), for: .touchUpInside)
        self.view.addSubview(mbtn)
        
        // 添加 UI 元素到视图
        slider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        view.addSubview(slider)
        let sh = 30.0
        slider.frame = CGRect(x: 15, y: mbtn.frame.origin.y - sh - 10, width: UIScreen.main.bounds.size.width - 30, height: sh)
        
        // tts
        let th = 50.0
        let sbtnw = 80.0
        view.addSubview(inputWrapper)
        inputWrapper.frame = CGRect(x: 0, y: slider.frame.origin.y - 10.0 - th, width: UIScreen.main.bounds.size.width, height: th)
        inputWrapperEndRect = inputWrapper.frame
        inputWrapper.addSubview(self.textView)
        inputWrapper.addSubview(speakBtn)
        textView.frame = CGRect(x: slider.frame.origin.x, y: 0, width: UIScreen.main.bounds.size.width - 30 - sbtnw - 10, height: th)
        speakBtn.frame = CGRect(x: textView.frame.maxX + 10.0, y: textView.frame.origin.y, width: sbtnw, height: th)
        
//        view.addSubview(aiAnswerTV)
        let aiTVh = 230.0
        let aiTVy = inputWrapperEndRect.origin.y - 50 - aiTVh
        aiAnswerTV.frame = CGRect(x: slider.frame.origin.x, y: aiTVy, width: slider.frame.width, height: aiTVh)
    }
    
    @objc func endEditing() {
        self.view.endEditing(true)
    }
    
    // 滑动条值变化时的回调
    @objc private func sliderValueChanged(_ sender: UISlider) {
        let value = sender.value
        
        // 在这里处理 value（范围 0 到 1）
        print("Slider value: \(value)")
        NYLDModelManager.shared().mouthOpenRate = value
    }
    
    @objc func changeModel() {
        NYLDModelManager.shared().nextScene()
    }
    @objc func changeBackground() {
        count += 1
        let nameIndex = count % 6
        let name = "0\(nameIndex).png"
        NYLDSDKManager.shared().stageVC.changeBackground(withImagePath: name)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}


// MARK: - TTS
extension ViewController {
    // 请求权限
    private func requestPermissions() {
       // 麦克风权限
       AVAudioSession.sharedInstance().requestRecordPermission { granted in
           DispatchQueue.main.async {
               if !granted {
                   self.showAlert(message: "请在设置中启用麦克风权限")
               }
           }
       }
       
       // 语音识别权限
       SFSpeechRecognizer.requestAuthorization { status in
           DispatchQueue.main.async {
               if status != .authorized {
                   self.showAlert(message: "请在设置中启用语音识别权限")
               }
           }
       }
    }

    private func setupAudioSession() {
        synthesizer.delegate = self
        let audioSession:AVAudioSession = AVAudioSession.sharedInstance()
        do {
           try audioSession.setCategory(.playAndRecord, mode: .default, options: [.mixWithOthers, .defaultToSpeaker])
           try audioSession.setActive(true)
        } catch {
           print("音频会话配置失败: \(error)")
        }
    }

    private func setupAmplitudeAudioEngine() {
        stopAmplitudeAudioEngine()
        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            guard let `self` = self else { return }
            guard let floatChannelData = buffer.floatChannelData else { return }
            let frameLength = Int(buffer.frameLength)
            let samples = floatChannelData[0]
            
            let batchSize = 64
            var batchAmplitudes: [Float] = []
            
            for i in stride(from: 0, to: frameLength, by: batchSize) {
                let end = min(i + batchSize, frameLength)
                var sum: Float = 0
                let count = end - i
                
                for j in i..<end {
                    sum += abs(samples[j])
                }
                
                let averageAmplitude = count > 0 ? sum / Float(count) : 0
                batchAmplitudes.append(averageAmplitude)
            }
            
            self.amplitudes.append(contentsOf: batchAmplitudes)
            print("实时振幅（最新）: \(batchAmplitudes.last ?? 0)")
            if let amplitude = batchAmplitudes.last {
                NYLDModelManager.shared().mouthOpenRate = amplitude * 20
            }
        }
        
        do {
            audioEngine.prepare()
            try audioEngine.start()
        } catch {
            print("音频引擎启动失败: \(error)")
        }
    }
    
    func stopAmplitudeAudioEngine() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        NYLDModelManager.shared().mouthOpenRate = 0.0
        
        freshAIAnswerTextView(text: "", shouldHide: true)
    }
    
    func freshAIAnswerTextView(text: String, shouldHide: Bool) {
        
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else { return }
            self.aiAnswerTV.text = text
            self.aiAnswerTV.isHidden = shouldHide
        }
        
    }
    
    func startAISpeak(answer: String) {
        setupAmplitudeAudioEngine()
        let text = answer
        if text.isEmpty || text.count <= 0 { return }
        freshAIAnswerTextView(text: text, shouldHide: false)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US") // 中文语音
        utterance.rate = 0.5 // 语速（0.1 - 1.0）
        utterance.pitchMultiplier = 1.0 // 音调（0.5 - 2.0）
        
        synthesizer.stopSpeaking(at: .immediate)
        synthesizer.speak(utterance)
    }
    
    func aiRequest(prompt: String, model:String = "deepseek/deepseek-r1-zero:free", completion: ((String?)->())?) {
        let key = "your-auth-key"
        let headers: [String: String] = ["Authorization" : "Bearer \(key)"]
        let body: [String: Any] = [
            "model" : model,
            "messages": [
                [
                    "role": "user",
                    "content": prompt
                ]
            ]
        ]
        guard let url = URL(string: "https://openrouter.ai/api/v1/chat/completions") else { return }
        NetworkClient.shared.post(url: url, headers: headers, body: body) { result in
            print(result)
            switch result {
            case .success(let data):
                do {
                    let decoder = JSONDecoder()
                    let response = try decoder.decode(ChatCompletionResponse.self, from: data)
                    if let error = response.error {
                        print("USPictureSearchIntent error: \(error.message)")
                    } else {
                        print("ID: \(response.id)")
                        print("Provider: \(response.provider)")
                        if let firstChoice = response.choices?.first {
                            print("USPictureSearchIntent Assistant response: \(firstChoice.message?.content)")
                            DispatchQueue.main.async {
                                completion?(firstChoice.message?.content)
                            }
                        }
                    }
//                    let responseDict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
//                    print("USPictureSearchIntent ID: \(responseDict)")
//                    print("USPictureSearchIntent Provider: \(responseDict)")
//
                } catch  {
                    debugPrint("USPictureSearchIntent log request 错误: \(error.localizedDescription)")
                }
            case .failure(let error):
                print("USPictureSearchIntent error: \(error)")
                
            }
        }
    }
    
    // TTS: 文字转语音
    @objc private func speakText() {
        self.endEditing()
        let text = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty || text.count <= 0 { return }
        self.startAISpeak(answer: text)
//        aiAnswerTV.text = "AI 正在思考中，请稍等..."
//        aiAnswerTV.isHidden = false
//        aiRequest(prompt: text) { [weak self] answer in
//            guard let `self` = self else { return }
//            guard let answer = answer else { return }
//            self.startAISpeak(answer: answer)
//        }
    }
    
    
    // 高亮指定范围的文本
    func highlightText(in characterRange: NSRange) {
        // 获取当前文本
        let text = aiAnswerTV.text ?? ""
        guard !text.isEmpty else { return }
        
        // 创建 NSMutableAttributedString
        let attributedString = NSMutableAttributedString(string: text)
        
        // 设置默认样式（白色、常规字体）
        let fullRange = NSRange(location: 0, length: text.utf16.count)
        attributedString.addAttributes([
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 16)
        ], range: fullRange)
        
        // 验证 characterRange 是否有效
        let validRange = NSIntersectionRange(characterRange, fullRange)
        if validRange.length > 0 {
            // 设置高亮样式（蓝色、加粗字体）
            attributedString.addAttributes([
                .foregroundColor: UIColor.white,
                .font: UIFont.boldSystemFont(ofSize: 20)
            ], range: validRange)
        } else {
            print("Invalid range: \(characterRange)")
        }
        
        // 更新 UITextView
        aiAnswerTV.attributedText = attributedString
        // 滚动到高亮范围的中央
        scrollToRange(validRange)
    }
    
    private func scrollToRange(_ range: NSRange) {
        guard range.length > 0 else { return }
        
        let layoutManager = aiAnswerTV.layoutManager
        let glyphRange = layoutManager.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
        let boundingRect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textView.textContainer)
        
        let textViewHeight = aiAnswerTV.bounds.height
        let offsetY = boundingRect.midY - textViewHeight / 2
        let contentHeight = aiAnswerTV.contentSize.height
        let maxOffsetY = max(0, contentHeight - textViewHeight)
        let finalOffsetY = max(0, min(offsetY, maxOffsetY))
        
        // 动画滚动
        UIView.animate(withDuration: 0.3) {
            self.textView.contentOffset = CGPoint(x: 0, y: finalOffsetY)
        }
    }
    
    // 提示用户前往设置
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "权限错误", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "前往设置", style: .default) { _ in
//            if let url = URL(string: UIApplication.UIApplicationOpenSettingsURLString) {
//                UIApplication.shared.open(url)
//            }
        })
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alert, animated: true)
    }
}

// MARK: - AVSpeechSynthesizerDelegate
extension ViewController: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        
    }
    
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        print("characterRange: \(characterRange)")
        highlightText(in: characterRange)
    }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        print("语音合成完成，振幅数据（前 10 个）: \(amplitudes)")
        stopAmplitudeAudioEngine()
    }
}
