//
//  FileRow.swift
//  clearsenseminutes
//
//  Created by KooBH on 2/19/24.
//

import Foundation
import UIKit

class FileRow: UITableViewCell {
    @IBOutlet weak var label_id: UILabel!
    @IBOutlet weak var label_title: UILabel!
    @IBOutlet weak var label_company: UILabel!
    @IBOutlet weak var label_text: UILabel!
    @IBOutlet weak var label_date: UILabel!
    @IBOutlet weak var btn_minute: UIButton!
    
    var data: Minute?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        contentView.backgroundColor = .clear
        label_id.text = ""
        label_title.text = ""
        label_company.text = ""
        label_text.text = ""
        label_date.text = ""
        data = nil
    }
}
