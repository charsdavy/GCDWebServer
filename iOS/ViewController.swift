/*
 Copyright (c) 2012-2019, Pierre-Olivier Latour
 All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
 * The name of Pierre-Olivier Latour may not be used to endorse
 or promote products derived from this software without specific
 prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL PIERRE-OLIVIER LATOUR BE LIABLE FOR ANY
 DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import GCDWebServers
import UIKit

let kWebUploaderNeedRefreshNotificationName = "kWebUploaderNeedRefresh"

class ViewController: UIViewController {
  @IBOutlet var label: UILabel?
  var webServer: GCDWebUploader!
  
  deinit {
    webServer.stop()
    webServer = nil
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
    webServer = GCDWebUploader(uploadDirectory: documentsPath)
    webServer.delegate = self
    webServer.allowHiddenItems = true
    
    if webServer.start() {
      if let serverURL = webServer.serverURL {
        label?.text = "GCDWebServer running \(serverURL) on port \(webServer.port)"
      } else {
        label?.text = "GCDWebServer running locally on port \(webServer.port)"
      }
    } else {
      label?.text = "GCDWebServer not running!"
    }
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
  }
    
   @IBAction func exchangeButtonAction(sender: UIButton) {
     let viewController = FilesViewController()
     viewController.title = "Files"
     if #available(iOS 13.0, *) {
       viewController.isModalInPresentation = true
     }
     self.present(UINavigationController(rootViewController: viewController), animated: true)
     
     print("Exchange")
  }
}

extension ViewController: GCDWebUploaderDelegate {
  func webUploader(_: GCDWebUploader, didUploadFileAtPath path: String) {
    NotificationCenter.default.post(name: NSNotification.Name.init(rawValue: kWebUploaderNeedRefreshNotificationName), object: nil)
    print("[UPLOAD] \(path)")
  }

  func webUploader(_: GCDWebUploader, didDownloadFileAtPath path: String) {
    NotificationCenter.default.post(name: NSNotification.Name.init(rawValue: kWebUploaderNeedRefreshNotificationName), object: nil)
    print("[DOWNLOAD] \(path)")
  }

  func webUploader(_: GCDWebUploader, didMoveItemFromPath fromPath: String, toPath: String) {
    NotificationCenter.default.post(name: NSNotification.Name.init(rawValue: kWebUploaderNeedRefreshNotificationName), object: nil)
    print("[MOVE] \(fromPath) -> \(toPath)")
  }

  func webUploader(_: GCDWebUploader, didCreateDirectoryAtPath path: String) {
    NotificationCenter.default.post(name: NSNotification.Name.init(rawValue: kWebUploaderNeedRefreshNotificationName), object: nil)
    print("[CREATE] \(path)")
  }

  func webUploader(_: GCDWebUploader, didDeleteItemAtPath path: String) {
    NotificationCenter.default.post(name: NSNotification.Name.init(rawValue: kWebUploaderNeedRefreshNotificationName), object: nil)
    print("[DELETE] \(path)")
  }
}
