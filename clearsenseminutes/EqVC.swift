//
//  PurchasePopupViewController.swift
//  clearsenseminutes
//
//  Created by KooBH on 1/25/24.
//

import UIKit
import OSLog
import CoreData

final class EqVC: UIViewController {
    /*
    lazy var btn_back = UIBarButtonItem(image: UIImage(named: "back"),
                                            style: .plain,
                                            target: self,
                                            action: #selector(onClickClose))
    
    // Equalizer eq
    private var eq: [VerticalSlider]!
    @IBOutlet weak var eq_1: VerticalSlider!
    @IBOutlet weak var eq_2: VerticalSlider!
    @IBOutlet weak var eq_3: VerticalSlider!
    @IBOutlet weak var eq_4: VerticalSlider!
    @IBOutlet weak var eq_5: VerticalSlider!
    @IBOutlet weak var eq_6: VerticalSlider!
    @IBOutlet weak var eq_7: VerticalSlider!
    @IBOutlet weak var eq_8: VerticalSlider!
    @IBOutlet weak var eq_amp: UISlider!

    // Equalizer value labes
    private var eqLabel: [UILabel]!
    @IBOutlet weak var eq_val_1: UILabel!
    @IBOutlet weak var eq_val_2: UILabel!
    @IBOutlet weak var eq_val_3: UILabel!
    @IBOutlet weak var eq_val_4: UILabel!
    @IBOutlet weak var eq_val_5: UILabel!
    @IBOutlet weak var eq_val_6: UILabel!
    @IBOutlet weak var eq_val_7: UILabel!
    @IBOutlet weak var eq_val_8: UILabel!
    @IBOutlet weak var eq_val_amp: UILabel!
    
    @IBOutlet weak var btn_close: LanguageButton!
    
    var container: NSPersistentContainer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        container = appDelegate.persistentContainer
        
        eq = [eq_1, eq_2, eq_3, eq_4, eq_5, eq_6, eq_7, eq_8]
        eqLabel = [eq_val_1, eq_val_2, eq_val_3, eq_val_4, eq_val_5, eq_val_6, eq_val_7, eq_val_8]

        eq_amp.setThumbImage(UIImage(named: "set_circle"), for: .normal)
        eq_amp.setMinimumTrackImage(UIImage(named: "slider_H"), for: .normal)
        eq_amp.setMaximumTrackImage(UIImage(named: "slider_H"), for: .normal)
        
        for i in 0..<8 {
            eq[i].slider.tag = i
            eq[i].slider.addTarget(self, action: #selector(onChange), for:.valueChanged)
            
            eq[i].value = (Float(audioEngine.gain_eq[i]) - 0.5) * 24.0
            eqLabel[i].text = eq[i].value.toEqVal
        }
        eq_amp.value = (Float(audioEngine.gain_eq[8]) - 0.5) * 24.0
        eq_val_amp.text = eq_amp.value.toEqVal
        
        navigationItem.setLeftBarButton(btn_back, animated: false)
        
        let nav = self.navigationController as? LanguageNavController
        nav?.localized = "EQUALIZER"
        navigationItem.title = "EQUALIZER".localized()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func onChange(_ sender: VerticalSlider) {
        let val = eq[sender.tag].value
        eqLabel[sender.tag].text = val.toEqVal
        
        audioEngine.gain_eq[sender.tag] = Double(val) / 24.0 + 0.5
        audioEngine.optEQ = true
        audioEngine.SetEQ()

        do {
            let eqs = try container.viewContext.fetch(Eq.fetchRequest())
            if eqs.count > 0 {
                let eq = eqs[0]
                switch sender.tag {
                case 0: eq.eq_0 = Double(val)
                case 1: eq.eq_1 = Double(val)
                case 2: eq.eq_2 = Double(val)
                case 3: eq.eq_3 = Double(val)
                case 4: eq.eq_4 = Double(val)
                case 5: eq.eq_5 = Double(val)
                case 6: eq.eq_6 = Double(val)
                case 7: eq.eq_7 = Double(val)
                default: ()
                }
            } else {
                let entity = NSEntityDescription.entity(forEntityName: "Eq", in: container.viewContext)
                let EqVal = NSManagedObject(entity: entity!, insertInto: container.viewContext)
                EqVal.setValue(val, forKey: "eq_\(sender.tag)")
            }

            try container.viewContext.save()
        } catch {
            let message = "Error saving Core Data for eq_\(sender.tag): \(error.localizedDescription)"
            os_log(.error, log: .system, "%@", message)
        }
    }
    
    @IBAction func eq_value(_ sender: UISlider) {
        let val = eq_amp.value
        eq_val_amp.text = val.toEqVal

        audioEngine.gain_eq[8] = Double(val) / 24.0 + 0.5
        audioEngine.optEQ = true
        audioEngine.SetEQ()

        do {
            let eqs = try container.viewContext.fetch(Eq.fetchRequest())
            if eqs.count > 0 {
                let eq = eqs[0]
                eq.eq_amp = Double(val)
            } else {
                let entity = NSEntityDescription.entity(forEntityName: "Eq", in: container.viewContext)
                let EqVal = NSManagedObject(entity: entity!, insertInto: container.viewContext)
                EqVal.setValue(val, forKey: "eq_amp")
            }

            try container.viewContext.save()
        } catch {
            let message = "Error saving Core Data for eq_amp: \(error.localizedDescription)"
            os_log(.error, log: .system, "%@", message)
        }
    }

    @IBAction func btn_flat(_ sender: Any) {
        for i in 0..<8 {
            audioEngine.gain_eq[i] = 0.5
            eq[i].value = 0
            eqLabel[i].text = "+00"
        }
        audioEngine.optEQ = true
        audioEngine.SetEQ()
        
        do {
            let eqs = try container.viewContext.fetch(Eq.fetchRequest())
            if eqs.count > 0 {
                let eq = eqs[0]
                eq.eq_0 = 0
                eq.eq_1 = 0
                eq.eq_2 = 0
                eq.eq_3 = 0
                eq.eq_4 = 0
                eq.eq_5 = 0
                eq.eq_6 = 0
                eq.eq_7 = 0
            } else {
                let entity = NSEntityDescription.entity(forEntityName: "Eq", in: container.viewContext)
                let EqVal = NSManagedObject(entity: entity!, insertInto: container.viewContext)
                for i in 0..<8 {
                    EqVal.setValue(0.0, forKey: "eq_\(i)")
                }
            }

            try container.viewContext.save()
        } catch {
            let message = "Error saving Core Data for FLAT: \(error.localizedDescription)"
            os_log(.error, log: .system, "%@", message)
        }
    }

    @IBAction func btn_voice(_ sender: Any) {
        let eqArr : [Float] = [-4.0, -2.0, -1.0, -2.0, 6.0, 8.0, 7.0, 5.0]

        for i in 0..<8 {
            audioEngine.gain_eq[i] = Double(eqArr[i]) / 24.0 + 0.5
            eq[i].value = eqArr[i]
            eqLabel[i].text = eqArr[i].toEqVal
        }
        audioEngine.optEQ = true
        audioEngine.SetEQ()
        
        do {
            let eqs = try container.viewContext.fetch(Eq.fetchRequest())
            if eqs.count > 0 {
                let eq = eqs[0]
                eq.eq_0 = Double(eqArr[0])
                eq.eq_1 = Double(eqArr[1])
                eq.eq_2 = Double(eqArr[2])
                eq.eq_3 = Double(eqArr[3])
                eq.eq_4 = Double(eqArr[4])
                eq.eq_5 = Double(eqArr[5])
                eq.eq_6 = Double(eqArr[6])
                eq.eq_7 = Double(eqArr[7])
            } else {
                let entity = NSEntityDescription.entity(forEntityName: "Eq", in: container.viewContext)
                let EqVal = NSManagedObject(entity: entity!, insertInto: container.viewContext)
                for i in 0..<8 {
                    EqVal.setValue(eqArr[i], forKey: "eq_\(i)")
                }
            }

            try container.viewContext.save()
        } catch {
            let message = "Error saving Core Data for VOICE: \(error.localizedDescription)"
            os_log(.error, log: .system, "%@", message)
        }
    }
    
    @IBAction func onClickClose(_ sender: Any) {
        navigationController?.popViewController(animated: true)
        NotificationCenter.default.post(name: AppNotification.changeEq , object: nil)
    }
     */
}
