//
//  ContentView.swift
//  LaunchpadManager
//
//  Created by 陈飞 on 2025/3/10.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {

    @State private var exportFile: JsonFile?
    @State private var importFile: Bool = false
    @State private var result: Bool?
    @State private var message = ""

    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            
            // 打开目录
            Button(action: {
                showInFinder()
            }) {
                Text("show_in_finder")
                    .frame(width: 100)
            }

            // 导出布局
            Button(action: {
                exportLayout()
            }) {
                Text("export_layout")
                    .frame(width: 100)
            }
            .padding(.top, 10)
            .fileExporter(
                isPresented: Binding(
                    get: { exportFile != nil },
                    set: { if !$0 { exportFile = nil } }
                ),
                document: exportFile,
                contentType: .json,
                defaultFilename: "launchpad_layout.json"
            ) { r in
                // 处理导出结果
                switch r {
                case .success(let url):
                    result = true
                    message = url.path
                case .failure(let error):
                    result = false
                    message = error.localizedDescription
                }
            }
            
            // 恢复布局
            Button(action: {
                importFile.toggle()
            }) {
                Text("import_layout")
                    .frame(width: 100)
            }
            .padding(.top, 10)
            .fileImporter(
                isPresented: $importFile,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { r in
                importLayout(r)
            }
        }
        .padding()
        .frame(width: 300, height: 150)
        .alert("result", isPresented: Binding( get: { result != nil }, set: { if !$0 { result = nil } })) {
            Button("close", role: .cancel) { }
        } message: {
            if let result {
                Text(result ? "success" : "failure")
                + Text("\n") + Text(message)
            }
        }
    }
    
    private func showInFinder() {
        do {
            try LaunchpadDB.showInFinder()
        } catch {
            result = false
            message = error.localizedDescription
        }
    }
    
    private func exportLayout() {
        do {
            let data = try LaunchpadExporter.exportLayout()
            exportFile = JsonFile(content: String(data: data, encoding: .utf8)!)
        } catch {
            result = false
            message = error.localizedDescription
        }
    }
    
    private func importLayout(_ r: Result<[URL], Error>) {
        DispatchQueue.main.async {
            do {
                let urls = try r.get()
                guard let url = urls.first else { return }
                
                _ = url.startAccessingSecurityScopedResource()
                defer { url.stopAccessingSecurityScopedResource() }
                
                let data = try Data(contentsOf: url)
                
                try LaunchpadImporter.importLayout(data: data)
                try LaunchpadCleaner.cleanLayout()
                // 重启 dock
                try LaunchpadDB.killDock()
                
                result = true
                message = ""
            } catch {
                result = false
                message = error.localizedDescription
            }
        }
    }
    
    struct JsonFile: FileDocument {
        var content: String
        
        init(content: String) {
            self.content = content
        }
        
        static var readableContentTypes: [UTType] { [.json] }
        
        init(configuration: ReadConfiguration) throws {
            guard let data = configuration.file.regularFileContents,
                  let string = String(data: data, encoding: .utf8) else {
                throw CocoaError(.fileReadCorruptFile)
            }
            content = string
        }
        
        func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
            FileWrapper(regularFileWithContents: Data(content.utf8))
        }
    }
}

//#Preview {
//    ContentView()
//}
