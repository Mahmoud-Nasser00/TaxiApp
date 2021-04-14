//
//  ContainersVC.swift
//  TaxiApp
//
//  Created by Mahmoud Nasser on 13/04/2021.
//

import UIKit

class ContainersVC: UIViewController {
    
    @IBOutlet weak var MainVCCenterConst: NSLayoutConstraint!
    
    @IBOutlet weak var mainVCTopConst: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(sideMenuBtnTapped), name: NSNotification.Name("sideMenuBtnTapped"), object: nil)
        
    }
    
    @objc func sideMenuBtnTapped(){
        
        UIView.animate(withDuration: 0.3) { [weak self] in
            if self?.MainVCCenterConst.constant == 0 {
                self?.MainVCCenterConst.constant = 170
//                self?.mainVCTopConst.constant = 200
            } else {
                self?.MainVCCenterConst.constant = 0
//                self?.mainVCTopConst.constant = 0
            }
            
            self?.view.layoutIfNeeded()
            
        }
        
      
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
