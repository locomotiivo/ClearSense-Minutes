//
//  FilesArray.swift
//  clearsenseminutes
//
//  Created by KooBH on 7/17/24.
//

import Foundation
import AVFoundation
import OSLog

final class FilesArray {

    static func loadData() -> [File] {
        do {
            var data : [File] = []
            
            let list = try FileManager.default.contentsOfDirectory(at: mpWAVURL,includingPropertiesForKeys: nil)
//                .filter { $0.pathExtension == "m4a" }
            
            list.forEach { url in
                // Title
                let fileTitle = url.lastPathComponent
                
                // Duration
                let filelength = try? AVAudioPlayer(contentsOf:url).duration
                
                let hours = Int(filelength ?? 0.0) / 3600
                let minutes = (Int(filelength ?? 0.0) % 3600) / 60
                let seconds = Int(filelength ?? 0.0) % 60
                let fileDuration = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
                
                // Creation Date
                let attributes = try? FileManager.default.attributesOfItem(atPath: url.path())
                guard let fileDate = attributes?[FileAttributeKey.creationDate] as? Date else { return }
                
                data.append(File(title: fileTitle, duration: fileDuration, date: fileDate, idx: -1))
            }
    
            data.sort(by: { $0.fileDate < $1.fileDate })
            
            // for table view
            for i in 0..<data.count {
                data[i].idx = i
            }
            
            return data
        } catch {
            let message = "Error listing .m4a files: \(error.localizedDescription)"
            os_log(.error, log: .files, "%@", message)
        }
        
        return []
    }
}
