//
//  EVDLiftingHeaderVM.swift
//  WH_CZR_SBK
//
//  Created by Michael Dimore on 11/10/21.
//  Copyright © 2021 Caesar's Entertainment. All rights reserved.
//

import Foundation
import WHSportsbook
import WHNetwork
import WebKit

protocol EVDLiftingHeaderVMDelegate: AnyObject {
    func finishedLoadingLaunchURL(_ url: URL)
    func changeWebViewHiddenState()
}

class EVDLiftingHeaderVM {
    
    let delegate         : EVDLiftingHeaderVMDelegate
    var scoreboardHeight : CGFloat = 0.0
    
    func toggleWebViewIsHidden() {
        delegate.changeWebViewHiddenState()
    }
    
    init(_ del: EVDLiftingHeaderVMDelegate) { self.delegate = del }
    
    func fetchLiveScoreboardInfo(_ ev: WHSportsbook.Event) {
        
        guard let url = URL(string: "https://scoreboardslauncher.williamhill.com/scoreboards/events/\(ev.id)?secured=true") else { return }
        print("\n\t\t  fetchLiveScoreboardInfo called, url: \(url.absoluteString)\n")
        
        WHDataManager().decodeJsonDataFrom(url: url, objectType: EventDetailsLiveScoreboard.self) { response, error in
            
            // TODO: - Scoreboard height result from the above response always returns the same value of '282', so a lookup is being used instead for now
            // if let result = response?.height.cgFltVal, result > 0.0 { self.scoreboardHeight = result }
            
            if let sport = response?.sport {
                var sbHeight: CGFloat = 0.0
                switch sport {
                case "football":    sbHeight = 317.0
                case "ice-hockey":  sbHeight = 222.0
                case "tabletennis": sbHeight = 139.0
                case "cricket":     sbHeight = 269.0
                case "tennis":      sbHeight = 298.0
                case "basketball":  sbHeight = 300.0
                default: sbHeight = 282.0
                }
                self.scoreboardHeight = sbHeight
            } else {
                self.scoreboardHeight = 0.0
            }
            
            if let link = response?.launch_link, let url = URL(string: link) { self.delegate.finishedLoadingLaunchURL(url) }
            
            if let err = error { print("\n\t\t scoreboard Link error: \(String(describing: err))\n") }
        }
    }
}
