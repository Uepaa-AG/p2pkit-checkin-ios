//
//  HistoryViewController.swift
//  p2pkit-checkin-ios
//
//  Copyright © 2017 Uepaa AG. All rights reserved.
//

import UIKit

class HistoryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var historyTableView: UITableView!
    @IBOutlet weak var checkinTransactionContainerView: UIView!
    @IBOutlet weak var headerLabel: UILabel!
    
    fileprivate var guestsInHistory = Array<Guest>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        OperatorController.sharedController.historyController = self
        
        self.reloadData()
        self.headerLabel.backgroundColor = Helpers.defaultColor()
    }

    // MARK: - Table view data source
    
    func reloadData() {
        self.guestsInHistory = GuestManager.sharedManager.getGuestsInHistory()
        self.historyTableView.reloadData()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.guestsInHistory.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "historyCell", for: indexPath) as! HistoryTableViewCell

        let guest = self.guestsInHistory[indexPath.row]
        cell.guestName.text = guest.name
        cell.removeButton.tag = indexPath.row
        cell.removeButton.addTarget(self, action: #selector(removeGuest), for: UIControlEvents.touchUpInside)

        return cell
    }
    
    func removeGuest(_ sender: UIButton) {
        let guest = self.guestsInHistory[sender.tag]
        OperatorController.sharedController.removeGuestFromHistory(guest)
    }

}
