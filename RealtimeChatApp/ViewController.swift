//
//  ViewController.swift
//  RealtimeChatApp
//
//  Created by Ha Nguyen on 8/14/17.
//  Copyright © 2017 Ha Nguyen. All rights reserved.
//

import UIKit

class ViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(handleLogout))
    }
    
    func handleLogout() {
        
        let loginController = LoginController()
        present(loginController, animated: true, completion: nil)
    }
}

