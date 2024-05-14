//
//  ActionViewController.swift
//  Extension
//
//  Created by Matteo Orru on 13/05/24.
//

//NSDictionary works like a regular dictionary, except you don't need to declare or even know what data types it holds.
//When working with extensions NSDictionary it's an advantage because we don't care what's in there, we just want to pull out our data.

import UIKit
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
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //let userDefaults = UserDefaults.standard
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Scripts", style: .plain, target: self, action: #selector(scriptButton))
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        
        
        //verifica se è presente un elemento di input da extensionContext
        if let inputItem = extensionContext?.inputItems.first as? NSExtensionItem {
            //verifica se l'elemento di input ha degli allegati
            if let itemProvider = inputItem.attachments?.first {
                //carica l'allegato come tipo di dati kUTTypePropertyList
                itemProvider.loadItem(forTypeIdentifier: propertyList as String) { [weak self] (dict, error) in
                    
                    //verifica che il dizionario caricato sia valido
                    guard let itemDictionary = dict as? NSDictionary else {return}
                    //verifica se il dizionario contiene dati passati da JS
                    guard let javaScriptValues = itemDictionary[NSExtensionJavaScriptPreprocessingResultsKey] as? NSDictionary else {return}
                    
                    //setting of our two properties from the javaScriptValues dictionary, typecasting them as String
                    self?.pageTitle = javaScriptValues["title"] as? String ?? ""
                    self?.pageURL = javaScriptValues["URL"] as? String ?? ""
                    self?.browserInfo = javaScriptValues["userAgent"] as? String ?? ""
                    self?.operatingSystem = javaScriptValues["platform"] as? String ?? ""
                    
                    
                    //this (set the view controller's title property on the main queue) is needed because the closure being executed as a result of loadItem(forTypeIdentifier:) could be called on any thread, and we don't want to change the UI unless we're on the main thread
                    DispatchQueue.main.async {
                        self?.title = self?.pageTitle
                    }
                }
            }
        }
        
        
        
    }

    
    //è praticamente solo l'inverso di ciò che abbiamo fatto all'interno di viewDidLoad
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
        
        
        present(ac, animated: true)
    }
    
    
    
    
}
