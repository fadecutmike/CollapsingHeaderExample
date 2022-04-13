//
//  EVDLiftingHeaderVC.swift
//  PTypeV2
//
//  Created by Michael Dimore on 10/6/20.
//  Copyright © 2020 Caesar's Entertainment. All rights reserved.
//

import UIKit
import WHSportsbook
import WHNetwork
import WebKit

class EVDLiftingHeaderVC: UIViewController {
    
    weak var delegate                    : EVDHeaderDelegate?
    lazy var viewModel                   : EVDLiftingHeaderVM = .init(self)
    @IBOutlet weak var filterView        : FilterView?
    @IBOutlet weak var webView           : WKWebView?
    @IBOutlet weak var gameDateTimeLabel : UILabel?

    @IBOutlet weak var lhsTeamLabel      : UILabel?
    @IBOutlet weak var rhsTeamLabel      : UILabel?
    @IBOutlet weak var lhsTeamScore      : UILabel?
    @IBOutlet weak var rhsTeamScore      : UILabel?
    @IBOutlet weak var lhsIconImage      : UIImageView?
    @IBOutlet weak var rhsIconImage      : UIImageView?

    @IBOutlet weak var preGameInfoParent  : UIView?
    @IBOutlet weak var liveGameIconImg   : UIImageView?
    @IBOutlet weak var scoreboardBtn     : UIButton?
    @IBOutlet weak var scoreboardIconImg : UIImageView?
    @IBOutlet weak var sbHeightConst     : NSLayoutConstraint?
    
    @IBOutlet weak var debugBarLabel     : UILabel?
    @IBOutlet weak var debugBarHeight    : NSLayoutConstraint?
    @IBOutlet weak var debugBarWidth     : NSLayoutConstraint?
    
    var scoreboardBtnTitle: String = "Hide Scoreboard" {
        didSet { scoreboardBtn?.setTitle(scoreboardBtnTitle, for: .normal) }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        preGameInfoParent?.isHidden = true
        webView?.scrollView.isScrollEnabled = false
        webView?.alpha = 0.0
        stackViewConfig(true)
        debugBarWidth?.constant = 0.0
        scoreboardBtn?.contentEdgeInsets = UIEdgeInsets(top: 5.0, left: 5.0, bottom: 5.0, right: 5.0)
    }
    
    func updateScoreboardBtnTitle(_ willExpand: Bool) {
        DispatchQueue.main.async {
            let sbPrefix = willExpand ? "Hide" : "Show"
            self.scoreboardBtnTitle = "\(sbPrefix) Scoreboard"
            UIView.animate(withDuration: 0.25) {
                self.scoreboardIconImg?.transform = CGAffineTransform.init(rotationAngle: willExpand ? 0.0 : .pi)
            }
        }
    }
    
    func setupEVDHeader(_ ev: WHSportsbook.Event) {
        DispatchQueue.main.async { [self] in
            configTeams(ev)
            configLivescores(ev)
        }
    }
    
    private func configTeams(_ ev: WHSportsbook.Event) {
        let labels = [lhsTeamLabel, rhsTeamLabel].compactMap({$0})
        for (idx, label) in labels.enumerated() {
            var img: UIImage?
            var txt: String = "\(idx == 0 ? "Home" : "Away") Team"
            if let sel = idx == 0 ? ev.homeTeam : ev.awayTeam {
                img = UIImage(named: sel.logoImage.replacePipes())
                txt = sel.teamAbbreviation?.replacePipes() ?? sel.name.abbrvTeam()
            }
            
            label.text = txt
            label.backgroundColor = .clear
            label.superview?.superview?.backgroundColor = .clear
            label.transform = CGAffineTransform(rotationAngle: .pi/2.0*(idx == 0 ? 1.0 : -1.0))
            
            img = UIImage(named: "boostIcon\(idx == 0 ? "HD":"")")
            
            let teamLogoImgView       = idx == 0 ? lhsIconImage : rhsIconImage
            teamLogoImgView?.image    = img
            teamLogoImgView?.isHidden = img == nil ? true : false
        }
        
        if !ev.started { preGameInfoParent?.isHidden = false }
    }
    
    
    private func configLivescores(_ ev: WHSportsbook.Event) {
        if ev.started {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = ev.startTime.timeIsOnTheHour ? "ha MM.dd.yy" : "h:mma MM.dd.yy"
            gameDateTimeLabel?.text = dateFormatter.string(from: ev.startTime)
            viewModel.fetchLiveScoreboardInfo(ev)
            
            if let liveEventData = ev.liveEventData {
                if let score1 = liveEventData.scores.last?.points  { lhsTeamScore?.text = "\(score1)" }
                if let score2 = liveEventData.scores.first?.points { rhsTeamScore?.text = "\(score2)" }
                
                var gTimeString = "\(liveEventData.gameTime.minutes):\(liveEventData.gameTime.seconds)"
                if ev.sportId != "baseball" {
                    gTimeString.append(" - \(ev.sportId.contains("hockey") ? "P":"Q")\(liveEventData.period)")
                }
                
                gameDateTimeLabel?.text = gTimeString
            } else {
                gameDateTimeLabel?.text = "99:87 - Q0"
            }
        }
    }
}

// MARK: - Scoreboard Logic

extension EVDLiftingHeaderVC {
    func applyLiveScoreUpdate(_ livescoreUpdate: DiffusionLivescoreUpdate) {
        DispatchQueue.main.async { [self] in
            if isViewLoaded {
                lhsTeamScore?.text      = "\(livescoreUpdate.scores.last?.scoreValue() ?? 0)"
                rhsTeamScore?.text      = "\(livescoreUpdate.scores.first?.scoreValue() ?? 0)"
                gameDateTimeLabel?.text = livescoreUpdate.timeRemainingString()
            } else {
                fatalError("view NOT loaded in EVD headerVC applyLiveScoreUpdate.....")
            }
        }
    }
    
    private func stackViewConfig(_ shouldHideLive: Bool) {

        DispatchQueue.main.async { [self] in
            webView?.isHidden                  = shouldHideLive
            scoreboardBtn?.superview?.isHidden = shouldHideLive
            liveGameIconImg?.isHidden          = shouldHideLive
            lhsTeamScore?.superview?.isHidden  = shouldHideLive
            debugBarWidth?.constant = shouldHideLive ? 0.0 : 10.0
            view.setNeedsLayout()
            view.layoutIfNeeded()
        }
    }
    
    @IBAction func didTapScoreboardButton(_ sender: Any) { viewModel.toggleWebViewIsHidden() }
}

extension EVDLiftingHeaderVC: EVDLiftingHeaderVMDelegate {
    
    func finishedLoadingLaunchURL(_ url: URL) {
        stackViewConfig(viewModel.scoreboardHeight == 0.0)
        DispatchQueue.main.async { [self] in
            sbHeightConst?.constant = viewModel.scoreboardHeight
            debugBarHeight?.constant = viewModel.scoreboardHeight
            debugBarLabel?.text = Int(viewModel.scoreboardHeight).strValue.components(separatedBy: "\n").joined(separator: "")
            delegate?.scoreboardFinishedLoading(viewModel.scoreboardHeight)
            view.layoutIfNeeded()
        
            if viewModel.scoreboardHeight > 0.0 {
                webView?.load(.init(url: url))
                
                if viewModel.scoreboardHeight > 0.0, webView?.alpha == 0.0 {
                    UIView.animate(withDuration: 0.2, delay: 0.0, options: []) { self.webView?.alpha = 1.0 }
                }
            } else if let vc = delegate as? EventDetailsViewController {
                vc.viewModel.updateLiftingHeader(.liveNoScoreboard)
            }
        }
    }
    
    func changeWebViewHiddenState() {
        if let vc = delegate as? EventDetailsViewController {
            let shouldExpand = vc.currentHeaderHeight == vc.viewModel.minOperatingHeight
            vc.expandLiftingHeader(shouldExpand)
        }
    }
}

public struct EventDetailsLiveScoreboard: Codable {
    let eventId     : String
    let launch_link : String
    let height      : Int
    let sport       : String
}
