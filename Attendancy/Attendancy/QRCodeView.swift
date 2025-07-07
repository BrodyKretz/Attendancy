//
//  QRCodeView.swift
//  Attendancy
//
//  Created by Don on 4/21/25.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

struct QRCodeView: View {
    let code: String
    let context = CIContext()
    let filter = CIFilter.qrCodeGenerator()
    
    var body: some View {
        Image(uiImage: generateQRCode(from: code))
            .interpolation(.none)
            .resizable()
            .scaledToFit()
            .padding(10)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray, lineWidth: 0.5)
            )
    }
    
    func generateQRCode(from string: String) -> UIImage {
        filter.message = Data(string.utf8)
        filter.correctionLevel = "H" // High error correction
        
        if let outputImage = filter.outputImage {
            // Scale the QR code for better visibility
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledQRImage = outputImage.transformed(by: transform)
            if let cgImage = context.createCGImage(scaledQRImage, from: scaledQRImage.extent) {
                return UIImage(cgImage: cgImage)
            }
        }
        
        // Fallback in case of failure
        return UIImage(systemName: "qrcode") ?? UIImage()
    }
}
