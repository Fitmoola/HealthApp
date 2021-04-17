//
//  UserProfile.swift
//  HealthApp
//
//  Created by SOTSYS036 on 01/03/19.
//  Copyright © 2019 SOTSYS036. All rights reserved.
//

import Foundation
import HealthKit

//////////////////
//error enum
//////////////////

private enum HealthkitSetupError: Error {
    case notAvailableOnDevice
    case dataTypeNotAvailable
}


class HealthKitAssistant {
    
    ///////////////////////////
    //Shared Variable
    ///////////////////////////
    
    static let shared = HealthKitAssistant()
    
    
    ///////////////////////////
    //Healthkit store object
    ///////////////////////////
    
    let healthKitStore = HKHealthStore()

    var heartRateQuery: HKObserverQuery!
    
    ////////////////////////////////////
    //MARK: Permission block
    ////////////////////////////////////
    func getHealthKitPermission(completion: @escaping (Bool) -> Void) {
        
        guard HKHealthStore.isHealthDataAvailable() else {
            print("No health data available")
            return
        }

        let stepsCount = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!
        let heartRate = HKObjectType.quantityType(forIdentifier: .heartRate)!
        let activitySummary = HKObjectType.activitySummaryType()
        let workoutType = HKObjectType.workoutType()

        self.healthKitStore.requestAuthorization(toShare:[stepsCount], read: [stepsCount, heartRate, activitySummary, workoutType]) {
            (success, error) in
            if success {
                print("Permission accept.")
                
                completion(true)
            } else {
                if error != nil {
                    print(error ?? "")
                }
                DispatchQueue.main.async {
                    completion(false)
                }
                print("Permission denied.")
            }
        }
    }

    func observerHeartRateSamples() {
        let heartRateSampleType = HKObjectType.quantityType(forIdentifier: .heartRate)


        if heartRateQuery != nil {
            healthKitStore.stop(heartRateQuery)
        }

        heartRateQuery = HKObserverQuery(sampleType: heartRateSampleType!, predicate: nil) { (_, completionHandler, error) in
            if let error = error {
                print("Error gettint heart rate data: \(error.localizedDescription)")
                return
            }

            self.fetchLatestHeartRateSample { (sample) in
                guard let sample = sample else {
                    completionHandler()
                    return
                }

                DispatchQueue.main.async {
                    let heartRateUnit = HKUnit(from: "count/min")

                    let heartRate = sample.quantity.doubleValue(for: heartRateUnit)

                    print("Heart Rate Sample: \(heartRate)")
                    completionHandler()
                }
            }
        }

        healthKitStore.execute(heartRateQuery)
    }


    //////////////////////////////////////////////////////
    //MARK: - Get Recent step Data
    //////////////////////////////////////////////////////
    
    func getMostRecentStep(for sampleType: HKQuantityType, completion: @escaping (_ stepRetrieved: Int, _ stepAll : [[String : String]]) -> Void) {
        
        // Use HKQuery to load the most recent samples.
        let mostRecentPredicate =  HKQuery.predicateForSamples(withStart: Date.distantPast, end: Date(), options: .strictStartDate)
        
        var interval = DateComponents()
        interval.day = 1
        
        let stepQuery = HKStatisticsCollectionQuery(quantityType: sampleType , quantitySamplePredicate: mostRecentPredicate, options: .cumulativeSum, anchorDate: Date.distantPast, intervalComponents: interval)
        
        stepQuery.initialResultsHandler = { query, results, error in
            
            if error != nil {
                //  Something went Wrong
                return
            }
            
            if let myResults = results {
                
                var stepsData : [[String:String]] = [[:]]
                var steps : Int = Int()
                stepsData.removeAll()
                
                myResults.enumerateStatistics(from: Date.distantPast, to: Date()) {
                    
                    statistics, stop in
                    
                    //Take Local Variable
                    
                    if let quantity = statistics.sumQuantity() {
                        
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "MMM d, yyyy"
                        dateFormatter.locale =  NSLocale(localeIdentifier: "en_US_POSIX") as Locale?
                        dateFormatter.timeZone = NSTimeZone.local
                        
                        var tempDic : [String : String]?
                        let endDate : Date = statistics.endDate
                        
                        steps = Int(quantity.doubleValue(for: HKUnit.count()))
                        
                        print("DataStore Steps = \(steps)")
                        
                        tempDic = [
                            "enddate" : "\(dateFormatter.string(from: endDate))",
                            "steps"   : "\(steps)"
                        ]
                        stepsData.append(tempDic!)
                    }
                }
                completion(steps, stepsData.reversed())
            }
        }

        healthKitStore.execute(stepQuery)
    }

    func fetchLatestHeartRateSample(completionHandler: @escaping (_ sample: HKQuantitySample?) -> Void) {
        print("Fetching heart rate sample data")

        guard let sampleType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate) else {
            completionHandler(nil)
            return
        }

        let predicate = HKQuery.predicateForSamples(withStart: Date.distantPast, end: Date(), options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: sampleType,
                                  predicate: predicate,
                                  limit: Int(HKObjectQueryNoLimit),
                                  sortDescriptors: [sortDescriptor]) { (_, results, error) in
                                    if let error = error {
                                        print("Error: \(error.localizedDescription)")
                                        return
                                    }

                                    print("Total heart rate sample data: \(results?.count ?? -1)")

                                    if let currentResults = results {
                                        if currentResults.count > 0 {
                                            currentResults[0].device
                                            completionHandler(currentResults[0] as? HKQuantitySample)
                                        } else {
                                            completionHandler(nil)
                                        }
                                    }
                                }

        healthKitStore.execute(query)
    }

    func fetchActivitySummary() {
        let calendar = Calendar.autoupdatingCurrent

        var dateComponents = calendar.dateComponents(
            [ .year, .month, .day ],
            from: Date()
        )

        // This line is required to make the whole thing work
        dateComponents.calendar = calendar

        let predicate = HKQuery.predicateForActivitySummary(with: dateComponents)

        let query = HKActivitySummaryQuery(predicate: predicate) { (query, summaries, error) in

            guard let summaries = summaries, summaries.count > 0
            else {
                print("No data for activity summary")
                return
            }

            let energyUnit = HKUnit.kilocalorie()
            let standUnit = HKUnit.count()
            let exerciseUnit = HKUnit.minute()

            summaries.forEach { (summary: HKActivitySummary) in
                let energy = summary.activeEnergyBurned.doubleValue(for: energyUnit)
                let stand = summary.appleStandHours.doubleValue(for: standUnit)
                let exercise = summary.appleExerciseTime.doubleValue(for: exerciseUnit)

                print("### HKActivitySummary")
                print("* energy: \(energy) Kcal")
                print("* stand: \(stand)")
                print("* exercise: \(exercise) minutes")
                print("### HKActivitySummary finished");
            }

        }

        healthKitStore.execute(query)
    }

    func fetchWorkoutsData() {
        // 1. Get all workouts with the "Other" activity type.
        let workoutPredicate = HKQuery.predicateForWorkouts(with: .running)
        // 2. Get all workouts that only came from this app.
        // let sourcePredicate = HKQuery.predicateForObjects(from: HKSource.)
        // 3. Combine the predicates into a single predicate.
        let compound = NSCompoundPredicate(andPredicateWithSubpredicates:
                                            [workoutPredicate])
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate,
                                                ascending: false)
        let query = HKSampleQuery(
          sampleType: .workoutType(),
          predicate: compound,
          limit: 0,
          sortDescriptors: [sortDescriptor]) { (query, samples, error) in
            guard let samples = samples, samples.count > 0, error == nil
              else {
                print("No workouts data for type running, error: \(error)");
                return
              }

            samples.forEach { (sample) in
                let workout = sample as? HKWorkout

                let totalEnergyBurned = workout?.totalEnergyBurned
                let totalDistance = workout?.totalDistance
                let duration = workout?.duration

                print("Reading workout")
                print("* totalEnergyBurned: \(String(describing: totalEnergyBurned))")
                print("* totalDistance: \(String(describing: totalDistance))")
                print("* duration: \(String(describing: duration))")

            }
        }

        healthKitStore.execute(query)
    }
}

extension Date {
    var dayBefore: Date {
        return Calendar.current.date(byAdding: .day, value: -1, to: self)!
    }
}
