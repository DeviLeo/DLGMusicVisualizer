//
//  MainViewController.swift
//  DLGMusicVisualizer
//
//  Created by Liu Junqi on 02/03/2017.
//  Copyright © 2017 DeviLeo. All rights reserved.
//

import UIKit


class MainViewController: UIViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tfUrl : UITextField?
    @IBOutlet weak var tvTableView : UITableView?
    @IBOutlet weak var tbToolbar : UIToolbar?
    
    var menu : Array<Dictionary<String, Any>>?
    var history : Array<Dictionary<String, Any>>?
    var urlForSegue : String?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.navigationItem.title = "DLGMusicVisualizer"
        self.tfUrl?.delegate = self
        self.tvTableView?.delegate = self
        self.tvTableView?.dataSource = self
        self.initVars()
        self.initToolbarItems(editing: false)
        self.registerNotifications()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func registerNotifications() {
        let nc : NotificationCenter! = NotificationCenter.default
        nc.addObserver(self, selector: #selector(self.notifyAddUrlToHistory), name: NSNotification.Name(rawValue: FMVNotificationAddUrlToHistory), object: nil)
    }
    
    func unregisterNotifications() {
        let nc : NotificationCenter! = NotificationCenter.default
        nc.removeObserver(self)
    }
    
    // MARK: - Init
    func initVars() {
        self.menu = [
            [
                "title" : "Local Files",
                "action" : NSStringFromSelector(#selector(self.onMenuLocalFilesTapped))
            ]
        ]
        self.loadHistory()
    }
    
    func initToolbarItems(editing : Bool) {
        let bbi = UIBarButtonItem.init(barButtonSystemItem: editing ? .edit : .done,
                                       target: self,
                                       action: editing ? #selector(self.onEditTapped) : #selector(self.onDoneTapped))
        let bbiFlex = UIBarButtonItem.init(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let bbiTrash = UIBarButtonItem.init(barButtonSystemItem: .trash, target: self, action: #selector(self.onTrashTapped))
        self.tbToolbar?.setItems([bbi, bbiFlex, bbiTrash], animated: true)
    }
    
    // MARK: - Actions
    @objc func onEditTapped(sender : Any?) {
        self.tvTableView?.setEditing(true, animated: true)
        self.initToolbarItems(editing: true)
    }
    
    @objc func onDoneTapped(sender : Any?) {
        self.tvTableView?.setEditing(false, animated: true)
        self.initToolbarItems(editing: false)
    }
    
    @objc func onTrashTapped(sender : Any?) {
        let ac = UIAlertController.init(title: "Delete All History",
                                        message: "Are you sure to delete all history?",
                                        preferredStyle: .alert)
        let delete = UIAlertAction.init(title: "Delete",
                                        style: .default) { (action : UIAlertAction) in
                                            self.deleteAllHistory()
        }
        let cancel = UIAlertAction.init(title: "Cancel",
                                        style: .cancel,
                                        handler: nil)
        ac.addAction(delete)
        ac.addAction(cancel)
        self.present(ac, animated: true, completion: nil)
    }
    
    @objc func onMenuLocalFilesTapped() {
        self.performSegue(withIdentifier: "m2fm", sender: self)
    }
    
    // MARK: - Notifications
    @objc func notifyAddUrlToHistory(notif : Notification) {
        let userinfo = notif.userInfo as! [String : String]
        let url : String? = userinfo["url"]
        self.addHistoryUrl(url: url)
    }

    // MARK: - History
    func addHistoryUrl(url : String?) {
        let count : Int = (self.history?.count)!
        for i in 0 ..< count {
            let obj = self.history?[i]
            if obj?["url"] as? String == url {
                self.history?.remove(at: i)
                break
            }
        }
        
        let dt = Date.timeIntervalSinceReferenceDate
        let dict : Dictionary<String, Any> = ["url" : url!, "dt" : dt]
        self.history?.insert(dict, at: 0)
        self.saveHistory()
        self.tvTableView?.reloadData()
    }
    
    func deleteHistoryAtIndex(index : Int) {
        self.history?.remove(at: index)
        self.saveHistory()
    }
    
    func loadHistory() {
        let ud = UserDefaults.standard
        let array : Array<Dictionary<String, Any>>? = ud.object(forKey: "history") as! Array<Dictionary<String, Any>>?
        if array == nil {
            self.history = Array.init()
        } else {
            self.history = array
        }
        self.tvTableView?.reloadData()
    }
    
    func saveHistory() {
        let ud = UserDefaults.standard
        ud.set(self.history, forKey: "history")
        ud.synchronize()
    }
    
    func deleteAllHistory() {
        self.history?.removeAll()
        let ud = UserDefaults.standard
        ud.removeObject(forKey: "history")
        ud.synchronize()
        self.tvTableView?.reloadData()
    }
    
    // MARK: - UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.returnKeyType == .go {
            textField.resignFirstResponder()
            let url : String! = textField.text
            if url.characters.count > 0 {
                self.addHistoryUrl(url: url)
                self.urlForSegue = url
                self.performSegue(withIdentifier: "m2v", sender: self)
            }
        }
        return true
    }
    
    func isLocalFile(url: String!) -> Bool {
        let range = url.range(of: ":")
        var isLocalFile: Bool = (range == nil)
        if isLocalFile == false {
            let p : String = url.substring(to: (range?.upperBound)!)
            let result: ComparisonResult = p.compare("file", options: .caseInsensitive, range: nil, locale: nil)
            if result == .orderedSame {
                isLocalFile = true
            }
        }
        return isLocalFile
    }
    
    func checkUrl(url: String?) -> String? {
        var finalUrl: String? = url
        let range: Range? = url?.range(of: ":")
        if range == nil { // file
            var tmp: String? = url
            if url?.characters.first != "/" { // relative
                let doc: String = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
                let nsdoc: NSString = doc as NSString
                tmp = nsdoc.appendingPathComponent(url!)
            } // else absolute
            
//            finalUrl = String.init(format: "file://%@", tmp!)
            finalUrl = tmp
        } // else network url or file://
        
        return finalUrl
    }
    
    func cellTextUrl(url: String?) -> String? {
        var finalUrl: String? = url
        if self.isLocalFile(url: url) == true {
            let nsurl: NSString = url! as NSString
            finalUrl = nsurl.lastPathComponent
        }
        return finalUrl
    }
    
    // MARK: - UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return (self.menu?.count)!
        } else {
            if self.history == nil {
                return 0
            } else {
                return (self.history?.count)!
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "FileCell", for: indexPath)
        if indexPath.section == 0 {
            let dict = self.menu?[indexPath.row]
            cell.textLabel?.text = dict?["title"] as? String
        } else {
            let dict = self.history?[indexPath.row]
            cell.textLabel?.text = dict?["url"] as? String
        }
        return cell
    }
    
    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Menu"
        } else {
            return "History"
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 44
        } else {
            return UITableViewAutomaticDimension
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            let dict: Dictionary? = self.menu?[indexPath.row]
            let selName: String = dict?["action"] as! String
            let sel: Selector = NSSelectorFromString(selName)
            let imp: IMP = self.method(for: sel)
            typealias f = @convention(c) (Any, Selector) -> Void
            let i = unsafeBitCast(imp, to: f.self)
            i(self, sel)
        } else {
            let row = indexPath.row
            if row < (self.history?.count)! {
                let dict = self.history?[row]
                let url = dict?["url"] as! String?
                self.addHistoryUrl(url: url)
                self.urlForSegue = self.checkUrl(url: url)
                self.performSegue(withIdentifier: "m2v", sender: self)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if indexPath.section == 0 {
            return false
        } else {
            return true
        }
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        if indexPath.section == 0 {
            return .none
        } else {
            return .delete
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            return
        }
        
        if editingStyle == .delete {
            let row = indexPath.row
            if row < (self.history?.count)! {
                self.deleteHistoryAtIndex(index: row)
                tableView.deleteRows(at: [indexPath], with: .automatic)
            }
        }
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == "m2v" {
            let vc: ViewController = segue.destination as! ViewController
            vc.url = self.urlForSegue
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        if (self.tfUrl?.canResignFirstResponder)! {
            self.tfUrl?.resignFirstResponder()
        }
    }
}
