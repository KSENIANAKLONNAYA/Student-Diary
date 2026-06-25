//
//  Untitled.swift
//  StudentDiary
//
//  Created by Ксения Наклонная on 29.05.2026.
//

import SwiftUI
import QuickLook
import PDFKit

// MARK: - Просмотрщик вложений
struct AttachmentPreviewView: View {
    let attachment: Attachment
    @Environment(\.dismiss) var dismiss
    @State private var showShareSheet = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                if attachment.fileType == "image" {
                    if let image = attachment.image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                    } else {
                        Text("Не удалось загрузить изображение")
                            .foregroundColor(.white)
                    }
                } else if attachment.fileType == "pdf" {
                    PDFPreviewView(data: attachment.fileData)
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "doc.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                        Text(attachment.fileName)
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("Предпросмотр недоступен")
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle(attachment.fileName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Закрыть") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showShareSheet = true
                    }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: [attachment.fileData])
        }
    }
}

// MARK: - PDF Preview
struct PDFPreviewView: View {
    let data: Data
    @State private var currentPage = 1
    @State private var totalPages = 0
    
    var body: some View {
        VStack(spacing: 12) {
            if let document = PDFDocument(data: data) {
                PDFKitView(document: document, currentPage: $currentPage, totalPages: $totalPages)
                    .edgesIgnoringSafeArea(.all)
                
                if totalPages > 1 {
                    HStack(spacing: 20) {
                        Button(action: {
                            if currentPage > 1 {
                                currentPage -= 1
                            }
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                                .foregroundColor(currentPage > 1 ? .white : .gray)
                        }
                        
                        Text("\(currentPage) / \(totalPages)")
                            .foregroundColor(.white)
                        
                        Button(action: {
                            if currentPage < totalPages {
                                currentPage += 1
                            }
                        }) {
                            Image(systemName: "chevron.right")
                                .font(.title2)
                                .foregroundColor(currentPage < totalPages ? .white : .gray)
                        }
                    }
                    .padding(.bottom, 10)
                }
            } else {
                Text("Не удалось загрузить PDF")
                    .foregroundColor(.white)
            }
        }
    }
}

// MARK: - PDFKit View
struct PDFKitView: UIViewRepresentable {
    let document: PDFDocument
    @Binding var currentPage: Int
    @Binding var totalPages: Int
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = document
        pdfView.autoScales = true
        pdfView.displayMode = .singlePage
        pdfView.displayDirection = .vertical
        pdfView.usePageViewController(true)
        
        totalPages = document.pageCount
        
        return pdfView
    }
    
    func updateUIView(_ pdfView: PDFView, context: Context) {
        if let page = document.page(at: currentPage - 1) {
            pdfView.go(to: page)
        }
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
