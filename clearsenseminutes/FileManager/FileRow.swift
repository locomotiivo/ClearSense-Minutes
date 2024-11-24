//
//  FileRow.swift
//  clearsenseminutes
//
//  Created by KooBH on 2/19/24.
//

import Foundation
import UIKit

class FileRow: UITableViewCell {
        
    @IBOutlet weak var label_name: UILabel!
    @IBOutlet weak var label_length: UILabel!
    @IBOutlet weak var label_date: UILabel!
    @IBOutlet weak var btn_play: UIButton!
    
    var data: File?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        contentView.backgroundColor = .clear
        label_name.text = ""
        label_length.text = ""
        label_date.text = ""
        data = nil
    }
}
