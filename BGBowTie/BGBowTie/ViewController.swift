//
//  ViewController.swift
//  BGBowTie
//
//  Created by bhavesh on 15/06/21.
//  Copyright © 2021 Bhavesh. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var timesWornLabel: UILabel!
    @IBOutlet weak var lastWornLabel: UILabel!
    @IBOutlet weak var favoriteLabel: UILabel!
    @IBOutlet weak var wearButton: UIButton!
    @IBOutlet weak var rateButton: UIButton!

    //MARK:- Properties
    var managedContext: NSManagedObjectContext!
    var currentBowTie: BowTie!


    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        managedContext = appDelegate.persistentContainer.viewContext
        insertSampleData()

        let request: NSFetchRequest<BowTie> = BowTie.fetchRequest()
        let firstTitle = segmentedControl.titleForSegment(at: 0)!
        request.predicate = NSPredicate(format: "%K = %@",argumentArray: [#keyPath(BowTie.searchKey), firstTitle])

        do {
            let results = try managedContext.fetch(request)
            self.currentBowTie = results.first
            populate(bowTie: results.first)

        } catch {
            print(error.localizedDescription)
        }
    }


    // MARK: - IBActions

    @IBAction func segmentedControl(_ sender: UISegmentedControl) {

    }

    @IBAction func wear(_ sender: UIButton) {
        let times = currentBowTie.timesWorn
        currentBowTie.timesWorn = times + 1
        currentBowTie.lastWorn = Date()

        do {
            try managedContext.save()
            populate(bowTie: currentBowTie)
        } catch {
            print(error.localizedDescription)
        }
    }

    @IBAction func rate(_ sender: UIButton) {
        let alert = UIAlertController(title: "New Rating", message: "Rate this BowTie", preferredStyle: .alert)

        alert.addTextField { (textField) in
            textField.keyboardType = .decimalPad
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let saveAction = UIAlertAction(title: "Save", style: .default) { (action) in

            if let textField = alert.textFields?.first {
                self.update(rating: textField.text)
            }
        }

        alert.addAction(cancelAction)
        alert.addAction(saveAction)
        self.present(alert, animated: true, completion: nil)
    }

    fileprivate func update(rating: String?) {
        guard let rating = rating,
            let ratingValue = Double(rating) else {
                return
        }

        do {
            currentBowTie.rating = ratingValue
            try managedContext.save()
            self.populate(bowTie: currentBowTie)
        } catch {
            print(error.localizedDescription)
        }
    }

    // Insert BowTie Dummy Data
    fileprivate func insertSampleData() {
        let fetchRequest: NSFetchRequest<BowTie> = BowTie.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "searchKey != nil")

        let count = try! managedContext.count(for: fetchRequest)

        if count > 0 {
            // Sample Plist also into the Core Data
            return
        }

        let path = Bundle.main.url(forResource: "SampleData", withExtension: "plist")
        let dataArray = NSArray(contentsOf: path!)!

        for dict in dataArray {
            let entity = NSEntityDescription.entity(forEntityName: "BowTie", in: managedContext)!
            let bowTie = BowTie(entity: entity, insertInto: managedContext)

            let bowTieDict = dict as! [String: Any]

            bowTie.id = UUID(uuidString: bowTieDict["id"] as! String)
            bowTie.name = bowTieDict["name"] as? String
            bowTie.isFavorite = bowTieDict["isFavorite"] as! Bool
            bowTie.searchKey = bowTieDict["searchKey"] as? String
            bowTie.rating = bowTieDict["rating"] as! Double
            let colorDict = bowTieDict["tintColor"] as! [String: Any]
            bowTie.tintColor = UIColor.color(dict: colorDict)
            let imageName = bowTieDict["imageName"] as? String
            let image = UIImage(named: imageName!)
            let imageData = image!.pngData()!
            bowTie.photoData = imageData
            bowTie.lastWorn = bowTieDict["lastWorn"] as! Date

            let timesNumber = bowTieDict["timesWorn"] as! NSNumber
            bowTie.timesWorn = timesNumber.int32Value
            bowTie.url = URL(string: bowTieDict["url"] as! String)
        }

        do {
            try managedContext.save()
        } catch {
            print(error.localizedDescription)
        }
    }

    fileprivate func populate(bowTie: BowTie?) {

        guard let bowTie = bowTie else { return }
        nameLabel.text = bowTie.name
        if let imageData = bowTie.photoData as? Data,
            let lastWorn = bowTie.lastWorn as? Date,
            let tintColor = bowTie.tintColor as? UIColor {

            imageView.image = UIImage(data: imageData)
            nameLabel.text = bowTie.name
            ratingLabel.text = "Rating: \(bowTie.rating)/5"
            timesWornLabel.text = "# times worn: \(bowTie.timesWorn)"

            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .none

            lastWornLabel.text = "Last worn: \(dateFormatter.string(from: lastWorn))"
            favoriteLabel.isHidden = !bowTie.isFavorite
            view.tintColor = tintColor
            segmentedControl.backgroundColor = tintColor
        }
    }


}

private extension UIColor {

    static func color(dict: [String : Any]) -> UIColor? {
        guard let red = dict["red"] as? NSNumber,
            let green = dict["green"] as? NSNumber,
            let blue = dict["blue"] as? NSNumber else {
                return nil
        }
        return UIColor(red: CGFloat(truncating: red) / 255.0, green: CGFloat(truncating: green) / 255.0, blue: CGFloat(truncating: blue) / 255.0, alpha: 1)
    }
}
