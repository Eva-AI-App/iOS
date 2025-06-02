//
//  SwiftCombineSupport.swift
//  Live2DSDK_Example
//
//  Created by NY on 2025/4/19.
//  Copyright © 2025 CocoaPods. All rights reserved.
//

import Foundation
import UIKit
import Combine

class KeyboardObserver {
    private var cancellables = Set<AnyCancellable>()

    // 用于发布键盘高度变化的Publisher
    var keyboardHeightPublisher = PassthroughSubject<CGRect, Never>()
    
    init() {
        // 监听键盘弹出和收起的通知
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .merge(with: NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification))
            .sink { [weak self] notification in
                self?.handleKeyboardNotification(notification)
            }
            .store(in: &cancellables)
    }

    private func handleKeyboardNotification(_ notification: Notification) {
        // 获取键盘的高度
        if let userInfo = notification.userInfo,
           let frameEnd = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            // 将键盘的高度发布出去
            keyboardHeightPublisher.send(frameEnd)
        }
    }
}
