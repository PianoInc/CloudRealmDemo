//
//  ViewController.swift
//  MemoOverCloud
//
//  Created by 김범수 on 2018. 2. 2..
//  Copyright © 2018 piano. All rights reserved.
//

import UIKit
import RealmSwift


class ViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    var tags: RealmTagsModel?
    var notificationToken: NotificationToken?
    var count = 0


    deinit {
        notificationToken?.invalidate()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        
        validateToken()
        NotificationCenter.default.addObserver(self, selector: #selector(realmChanged), name: NSNotification.Name.RealmConfigHasChanged, object: nil)

        
        let searchViewController = self.storyboard!.instantiateViewController(withIdentifier: "search") as! SearchViewController
        
        let searchController = UISearchController(searchResultsController: searchViewController)
        searchController.searchResultsUpdater = searchViewController
        searchController.obscuresBackgroundDuringPresentation = true
        searchController.searchBar.placeholder = "Search Notes"
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToCategory" {
            guard let categoryVC = segue.destination as? CategoryViewController,
                let category = sender as? String else {return}
            categoryVC.categoryRecordName = category
        }
    }
    
    @objc func realmChanged() {
        DispatchQueue.main.async {
            self.navigationController?.popToRootViewController(animated: true)
            self.validateToken()
            self.tableView.reloadData()
        }
    }


    func validateToken() {

        do {
            let realm = try Realm()

            if let existingTags = realm.objects(RealmTagsModel.self).first {
                tags = existingTags
            } else {
                let newTags = RealmTagsModel.getNewModel()
                ModelManager.saveNew(model: newTags) { [weak self] _ in
                    DispatchQueue.main.async {
                        self?.validateToken()
                    }
                }
            }

            notificationToken = tags?.observe { [weak self] (changes) in
                guard let tableView = self?.tableView else {return}

                switch changes {
                    case .deleted: break
                    case .change(_): tableView.reloadData()
                    case .error(let error): print(error)
                }
            }


        } catch {print(error)}
    }

    @IBAction func newButtonTouched() {

        var tagsArray = tags!.tags.components(separatedBy: "!")
        tagsArray.append("\(count)")
        
        ModelManager.update(id: tags?.id ?? "", type: RealmTagsModel.self, kv: ["tags": tagsArray.joined(separator: "!")])

        count += 1
    }
    

}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = tags?.tags.components(separatedBy: "!").count ?? 0
        return count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "categoryCell", for: indexPath)
        let tag = tags?.tags.components(separatedBy: "!")[indexPath.row]

        cell.textLabel?.text = tag ?? ""

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let tag = tags?.tags.components(separatedBy: "!")[indexPath.row]

        performSegue(withIdentifier: "goToCategory", sender: tag)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .delete
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {

            var tagsArray = tags!.tags.components(separatedBy: "!")
            tagsArray.remove(at: indexPath.row)

            ModelManager.update(id: tags?.id ?? "", type: RealmTagsModel.self, kv: ["tags": tagsArray.joined(separator: "!")]) 
        }
    }
}
