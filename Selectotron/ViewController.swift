//
//  ViewController.swift
//  Selectotron
//
//  Created by David Wagner on 25/10/2022.
//

import UIKit
import UniformTypeIdentifiers

class ViewController: UIViewController {
    @IBOutlet var label: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        label.text = ""
    }
}

extension ViewController {
    @IBAction func handleSelectTapped(sender: UIButton) {
        let controller = UIDocumentPickerViewController(
            forOpeningContentTypes: [
                .png,
                .jpeg,
                .pdf,
            ]
        )
        controller.delegate = self
        controller.allowsMultipleSelection = false
        controller.shouldShowFileExtensions = true
        present(controller, animated: true) {
            print("Presented")
        }
    }
}

extension ViewController: UIDocumentPickerDelegate {
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first,
              url.startAccessingSecurityScopedResource()
        else {
            print("Could not access resource")
            return
        }
        
        defer {
            url.stopAccessingSecurityScopedResource()
            print("Released security scope")
        }
        
        do {
            let tmp = try FileManager
                .default
                .url(for: .itemReplacementDirectory, in: .userDomainMask, appropriateFor: url, create: true)
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension(url.pathExtension)
            
            try FileManager.default.copyItem(at: url, to: tmp)
            
            print("Picked: \(url)")
            print("Copied to: \(tmp)")
            print("Type: \(tmp.mimeType)")
            
            label.text = "Copied \(url.pathComponents.last ?? "''") locally ready to upload."
        } catch {
            print("Error: \(error)")
        }
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("Cancelled")
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
