//
//  ViewController.swift
//  Selectotron
//
//  Created by David Wagner on 25/10/2022.
//

import UIKit
import UniformTypeIdentifiers

class ViewController: UIViewController {
    @IBOutlet var textView: UITextView!
    @IBOutlet var button: UIButton!

    @IBOutlet var allowPNG: UISwitch!
    @IBOutlet var allowJPG: UISwitch!
    @IBOutlet var allowPDF: UISwitch!
    @IBOutlet var preferModal: UISwitch!
    
    var log = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textView.layer.cornerRadius = 8
        textView.contentInset = .init(top: 8, left: 8, bottom: 8, right: 8)
        
        button.layer.cornerRadius = 8
        button.contentEdgeInsets = .init(top: 8, left: 8, bottom: 8, right: 8)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        render(log: log)
    }
}

extension ViewController {
    private func clearLog() {
        log.removeAll()
        render(log: log)
    }
    
    private func log(_ message: String) {
        log.append(message)
        render(log: log)
    }
    
    private func render(log: [String]) {
        DispatchQueue.main.async { [output = self.textView] in
            output?.text = log.joined(separator:"\n\n")
        }
    }
}

extension ViewController {
    @IBAction func handleSelectTapped(sender: UIButton) {
        clearLog()
        
        var mediaTypes: [UTType] = []
        if allowPNG.isOn {
            mediaTypes.append(.png)
        }
        if allowJPG.isOn {
            mediaTypes.append(.jpeg)
        }
        if allowPDF.isOn {
            mediaTypes.append(.pdf)
        }

        let controller = UIDocumentPickerViewController(forOpeningContentTypes: mediaTypes)

        controller.delegate = self
        controller.allowsMultipleSelection = false
        controller.shouldShowFileExtensions = true
        controller.modalPresentationStyle = preferModal.isOn ? .fullScreen : .automatic

        present(controller, animated: true) { [weak self] in
            self?.log("Presented")
        }
    }
}

extension ViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first,
              url.startAccessingSecurityScopedResource()
        else {
            log("Could not access resource")
            return
        }
        
        log("Acquired security scope")
        defer {
            url.stopAccessingSecurityScopedResource()
            log("Released security scope")
        }
        
        do {
            let tmp = try FileManager
                .default
                .url(for: .itemReplacementDirectory, in: .userDomainMask, appropriateFor: url, create: true)
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension(url.pathExtension)
            
            try FileManager.default.copyItem(at: url, to: tmp)
            
            log("Picked: \(url)")
            log("Copied to: \(tmp)")
            log("Type: \(tmp.mimeType)")
            log("Copied \(url.pathComponents.last ?? "''") locally ready to upload.")
        } catch {
            log("⛔️ Error: \(error)")
        }
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        log("Cancelled")
    }
}

extension URL {
    var mimeType: String {
        guard let type = UTType(filenameExtension: pathExtension),
              let mimeType = type.preferredMIMEType
        else {
            return "application/octet-stream"
        }

        return mimeType
    }
}
