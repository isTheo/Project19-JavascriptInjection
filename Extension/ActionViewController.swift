//
//  ActionViewController.swift
//  Extension
//
//  Created by Matteo Orru on 13/05/24.
//

//NSDictionary works like a regular dictionary, except you don't need to declare or even know what data types it holds.


import UIKit
import WebKit
import MobileCoreServices
import UniformTypeIdentifiers

class ActionViewController: UIViewController {

    @IBOutlet var script: UITextView!
    
    //using UTType.propertyList.identifier because kUTTypePropertyList was deprecated in iOS 15
    let propertyList = UTType.propertyList.identifier
    
    var pageTitle = ""
    var pageURL = ""
    var browserInfo = ""
    var operatingSystem = ""
    
    let userDefaults = UserDefaults.standard
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Scripts", style: .plain, target: self, action: #selector(scriptButton))
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        
        
        if let inputItem = extensionContext?.inputItems.first as? NSExtensionItem {
            if let itemProvider = inputItem.attachments?.first {
                itemProvider.loadItem(forTypeIdentifier: propertyList as String) { [weak self] (dict, error) in
                    
                    guard let itemDictionary = dict as? NSDictionary else {return}
                    guard let javaScriptValues = itemDictionary[NSExtensionJavaScriptPreprocessingResultsKey] as? NSDictionary else {return}
                    
                    self?.pageTitle = javaScriptValues["title"] as? String ?? ""
                    self?.pageURL = javaScriptValues["URL"] as? String ?? ""
                    
                    
                    DispatchQueue.main.async {
                        if let currentURL = URL(string: self?.pageURL ?? ""), let host = currentURL.host {
                            self?.script.text = self!.userDefaults.string(forKey: host) ?? ""
                        }
                        self?.title = self?.pageTitle
                    }
                }
            }
        }
        
        
        
    }

    
    
    @IBAction func done() {
        let item = NSExtensionItem()
        let argument: NSDictionary = ["customJavaScript": script.text ?? "No value found"]
        let webDictionary: NSDictionary = [NSExtensionJavaScriptFinalizeArgumentKey: argument]
        let customJavaScript = NSItemProvider(item: webDictionary, typeIdentifier: propertyList as String)
        item.attachments = [customJavaScript]
        
        extensionContext?.completeRequest(returningItems: [item])
        
    }
    
    
    @objc func adjustForKeyboard(notification: Notification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }

        let keyboardScreenEndFrame = keyboardValue.cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)

        if notification.name == UIResponder.keyboardWillHideNotification {
            script.contentInset = .zero
        } else {
            script.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height - view.safeAreaInsets.bottom, right: 0)
        }

        script.scrollIndicatorInsets = script.contentInset

        let selectedRange = script.selectedRange
        script.scrollRangeToVisible(selectedRange)
    }
    
    
    
    @objc func scriptButton() {
        let ac = UIAlertController(title: "Scripts", message: "", preferredStyle: .actionSheet)
        
        let pageName = UIAlertAction(title: "Page name", style: .default) { _ in
            self.script.text = "alert(document.title);"
            self.done()
            
        }
        let pageURL = UIAlertAction(title: "Page URL", style: .default) { _ in
            self.script.text = "alert(document.URL);"
            self.done()
            
        }
        let browserInfo = UIAlertAction(title: "Browser info", style: .default) { _ in
            self.script.text = "alert(navigator.userAgent);"
            self.done()
        }
        let operatingSystem = UIAlertAction(title: "Operating System", style: .default) { _ in
            self.script.text = "alert(navigator.platform);"
            self.done()
            
        }
        
        ac.addAction(pageName)
        ac.addAction(pageURL)
        ac.addAction(browserInfo)
        ac.addAction(operatingSystem)
        ac.addAction(UIAlertAction(title: "Close", style: .cancel))
        
        
        present(ac, animated: true)
    }
    
    
    
    
}
