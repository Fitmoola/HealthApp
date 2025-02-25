//
//  StepsTableViewController.swift
//  SocialSignIn
//
//  Created by SOTSYS036 on 19/07/18.
//  Copyright © 2018 SOTSYS036. All rights reserved.
//

import UIKit
import HealthKit

class StepsTableViewController: UITableViewController {

    //MARK: Outlet
    
    @IBOutlet weak var labelToday: UILabel!
    
    
    //MARK: Var
    
    var todayStep = Int()
    
    var stepDataSource : [[String:String]]? = [] {
        didSet{
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //MARK: Get Healthkit permission 
        HealthKitAssistant.shared.getHealthKitPermission { (response) in
            self.loadData()
        }
        
    }
    
    ////////////////////////////////////
    //MARK: - Healthkit step load
    ////////////////////////////////////
    
    func loadData()  {
        
        // guard let stepsdata = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }

//        HealthKitAssistant.shared.getMostRecentStep(for: stepsdata) { (steps , stepsData) in
//            self.todayStep = steps
//            self.stepDataSource = stepsData
//            DispatchQueue.main.async {
//                self.labelToday.text = "\(self.todayStep)"
//            }
//        }

        // observe heart rate
        HealthKitAssistant.shared.observerHeartRateSamples()

        // load today activity summary
        //  HealthKitAssistant.shared.fetchActivitySummary()

        // load workout data
        // HealthKitAssistant.shared.fetchWorkoutsData()
    }
    
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    /////////////////////////////////////////////
    // MARK: - Table view data source
    /////////////////////////////////////////////
    

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return (stepDataSource?.count)!
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        // Configure the cell...
        
        cell.textLabel?.text =          (stepDataSource![indexPath.row] as AnyObject).object(forKey: "steps") as? String
        cell.detailTextLabel?.text =    (stepDataSource![indexPath.row] as AnyObject).object(forKey: "enddate") as? String
        
        return cell
    }
    
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "steps"
    }
    
    
    
    
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
