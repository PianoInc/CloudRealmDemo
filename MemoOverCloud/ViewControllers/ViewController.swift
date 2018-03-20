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
    var categories: Results<RealmCategoryModel>!
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
        NotificationCenter.default.addObserver(self, selector: #selector(validateToken), name: NSNotification.Name.RealmConfigHasChanged, object: nil)
        
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
                let category = sender as? RealmCategoryModel else {return}
            categoryVC.categoryRecordName = category.recordName
        }
    }

    @objc func validateToken() {
        
        guard let realm = try? Realm() else { fatalError("Database open failed")}
        self.categories = realm.objects(RealmCategoryModel.self)
        
        notificationToken = categories.observe { [weak self] (changes) in
            guard let tableView = self?.tableView else {return}

            switch changes {
            case .initial:
                tableView.reloadData()
            case .update(_, let deletes, let inserts, let mods):
                tableView.beginUpdates()
                tableView.insertRows(at: inserts.map{IndexPath(row: $0, section: 0)}, with: .automatic)
                tableView.deleteRows(at: deletes.map{IndexPath(row: $0, section: 0)}, with: .automatic)
                tableView.reloadRows(at: mods.map{IndexPath(row: $0, section: 0)}, with: .automatic)
                tableView.endUpdates()
            case .error(let error):
                    fatalError("Error!! \(error)")
            }


        }
    }

    @IBAction func newButtonTouched() {

        let newCategory = RealmCategoryModel.getNewModel(name: "new Category\(count)")

        ModelManager.save(model: newCategory) { error in
            if let error = error {
                print(error)
            } else {
                print("happy")
            }
        }

        count += 1
    }
    

}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "categoryCell", for: indexPath)
        let category = categories[indexPath.row]

        cell.textLabel?.text = category.name

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let category = categories[indexPath.row]
        
        performSegue(withIdentifier: "goToCategory", sender: category)
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

            ModelManager.delete(model: categories[indexPath.row])
        }
    }
}
