//
//  XMPPMessageCell.swift
//  chatXMPPdemo
//
//  Created by Smith Huamani on 28/02/18.
//  Copyright © 2018 Smith Huamani. All rights reserved.
//

import UIKit

protocol XMPPMessageCellDelegate {
    func btnPlayAudioPressed(indexRow: Int)
}

class XMPPMessageCell: UITableViewCell {

    @IBOutlet weak var lblUser: UILabel!
    @IBOutlet weak var lblMessage: UILabel!
    @IBOutlet weak var btnPlay: UIButton!
    
    var messageCellDelegate: XMPPMessageCellDelegate!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBAction func btnPlayAudioPressed() {
        messageCellDelegate.btnPlayAudioPressed(indexRow: btnPlay.tag)
    }
}
