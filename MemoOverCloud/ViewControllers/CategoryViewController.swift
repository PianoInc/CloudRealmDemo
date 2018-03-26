//
//  CategoryViewController.swift
//  MemoOverCloud
//
//  Created by 김범수 on 2018. 2. 2..
//  Copyright © 2018년 piano. All rights reserved.
//

import UIKit
import RealmSwift

class CategoryViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    var categoryRecordName: String!
    var notes: Results<RealmNoteModel>?
    var notificationToken: NotificationToken?
    var count = 0
    
    
    deinit {
        notificationToken?.invalidate()
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title = ""
        
        tableView.delegate = self
        tableView.dataSource = self
        
        validateToken()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToMemo" {
            guard let categoryVC = segue.destination as? MemoViewController,
                let memo = sender as? RealmNoteModel else {return}
            
            categoryVC.memo = memo
        }
    }
    
    func validateToken() {
        guard let realm = try? Realm() else {return}
        notes = realm.objects(RealmNoteModel.self).filter("categoryRecordNames CONTAINS[cd] %@", categoryRecordName)
        
        notificationToken = notes?.observe { [weak self] (changes) in
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
        
        let newNote = RealmNoteModel.getNewModel(title: "newNote \(count)", categoryRecordName: categoryRecordName)

        ModelManager.saveNew(model: newNote) { error in
            if let error = error {
                print(error)
            } else {
                print("happy")
            }
        }

        count += 1

    }
    
}

extension CategoryViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notes?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "memoCell", for: indexPath)
        
        guard let memo = notes?[indexPath.row] else {return cell}
        
        cell.textLabel?.text = memo.title
        cell.detailTextLabel?.text = String(describing: memo.content.prefix(15))
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let note = notes?[indexPath.row] else {return}
        performSegue(withIdentifier: "goToMemo", sender: note)
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
            guard let note = notes?[indexPath.row] else {return}
            ModelManager.delete(id: note.id, type: RealmNoteModel.self)
        }
    }
}
