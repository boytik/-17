// NestDocumentWrapper.swift
// Little Days: Quiet Mind
// SwiftUI wrapper for NestDocumentHostingController

import SwiftUI
import Combine

// MARK: - 🌐 Nest Document Wrapper — UIViewControllerRepresentable

struct NestDocumentWrapper: UIViewControllerRepresentable {

    let destination: URL
    let onError: () -> Void
    let on404Detected: () -> Void

    func makeUIViewController(context: Context) -> NestDocumentHostingController {
        let vc = NestDocumentHostingController()
        vc.updateContent(destination: destination, onError: onError, on404Detected: on404Detected)
        return vc
    }

    func updateUIViewController(
        _ uiViewController: NestDocumentHostingController,
        context: Context
    ) {
        uiViewController.updateContent(
            destination: destination,
            onError: onError,
            on404Detected: on404Detected
        )
    }
}
